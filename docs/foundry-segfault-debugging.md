# Foundry Segfault Debugging Report

## Problem Summary

After successfully fixing the bottle download and GSettings schema issues, foundry would segfault when executed with any command (e.g., `foundry --help`, `foundry init`). The application would crash with exit code 139 (segmentation fault).

## Initial Investigation

### Symptoms
```bash
$ foundry --help
Segmentation fault (core dumped)

$ echo $?
139
```

The segfault occurred consistently on every invocation, suggesting a fundamental issue with library loading or initialization.

## Debugging Process

### Step 1: Dynamic Linker Debugging

Used `LD_DEBUG=all` to trace library loading and symbol resolution:

```bash
$ LD_DEBUG=all foundry --help 2>&1 | grep -B10 "soup_uri"
```

**Key Finding:** The dynamic linker was attempting to look up the symbol `soup_uri_new` but couldn't find it in any loaded library.

```
symbol=soup_uri_new;  lookup in file=foundry [0]
symbol=soup_uri_new;  lookup in file=/home/linuxbrew/.linuxbrew/Cellar/foundry/1.0.0/lib/libfoundry-1.so.1 [0]
symbol=soup_uri_new;  lookup in file=/home/linuxbrew/.linuxbrew/opt/glib/lib/libgobject-2.0.so.0 [0]
...
[symbol not found in any library]
```

### Step 2: Understanding the Symbol

The symbol `soup_uri_new` is from **libsoup 2.x API**. However, the system only had **libsoup 3.x** installed, which uses a different API (`GUri` instead of `SoupURI`).

```bash
$ brew list | grep soup
libsoup  # This is libsoup 3.x

$ ldd /home/linuxbrew/.linuxbrew/bin/foundry | grep soup
libsoup-3.0.so.0 => /home/linuxbrew/.linuxbrew/opt/libsoup/lib/libsoup-3.0.so.0
```

### Step 3: Identifying the Source

Since `dlsym` was being called (visible in LD_DEBUG output), this indicated runtime dynamic loading, typically used by plugin systems. Foundry uses **libpeas** for its plugin architecture.

Examined the build configuration:

```bash
$ cat /tmp/foundry-check/meson.options | grep -A3 "feature-llm\|plugin-ollama"
```

**Discovery:**
- `feature-llm` defaults to `true` (line 44-47 of meson.options)
- `plugin-ollama` defaults to `true` (line 305-308 of meson.options)
- The ollama plugin is part of the LLM feature

### Step 4: Confirming the Ollama Plugin Issue

Checked the ollama plugin source code:

```bash
$ grep -r "libsoup\|soup\.h" /tmp/foundry-check/plugins/ollama/
```

**Results:**
```
/tmp/foundry-check/plugins/ollama/plugin-ollama-llm-provider.c:#include <libsoup/soup.h>
/tmp/foundry-check/plugins/ollama/plugin-ollama-client.h:#include <libsoup/soup.h>
/tmp/foundry-check/plugins/ollama/plugin-ollama-client.c:#include <foundry-soup.h>
/tmp/foundry-check/plugins/ollama/meson.build:  dependency('libsoup-3.0'),
```

The ollama plugin was including libsoup headers and depending on libsoup-3.0. However, when built without proper feature flags or with introspection disabled, the plugin system was failing to resolve symbols correctly.

### Step 5: Build Configuration Analysis

The formula was building with:
```ruby
-Dgtk=false
-Dintrospection=disabled
-Ddocs=false
-Dfeature-flatpak=false
```

**But NOT:**
```ruby
-Dfeature-llm=false
```

This meant the ollama plugin was being built and embedded into libfoundry, but without proper introspection support, the plugin couldn't load correctly at runtime, causing the symbol resolution failure.

## Root Cause

1. **Feature Mismatch:** The LLM feature (including ollama plugin) was enabled by default
2. **Introspection Disabled:** Building with `-Dintrospection=disabled` prevented proper plugin loading
3. **Symbol Resolution Failure:** At runtime, the plugin system tried to dynamically load plugin code that referenced libsoup symbols, but the dynamic linker couldn't resolve them properly without introspection metadata
4. **Segfault:** The unresolved symbol lookup caused a segmentation fault

## Solution

### Fix Applied

Updated `Formula/foundry.rb` to explicitly disable the LLM feature:

```ruby
args = %W[
  --wrap-mode=nofallback
  --prefix=#{prefix}
  --libdir=#{lib}
  --buildtype=plain
  -Dgtk=false
  -Dintrospection=disabled
  -Ddocs=false
  -Dfeature-flatpak=false
  -Dfeature-llm=false          # Added this line
]
```

### Verification

After rebuilding with `-Dfeature-llm=false`:

1. Library size decreased from 3.0M to 2.7M (confirming ollama plugin was excluded)
2. No more `soup_uri_new` symbol lookups in LD_DEBUG output
3. Foundry executed successfully without segfaults

## Lessons Learned

### 1. Feature Defaults Matter

When building packages with many optional features, always check the defaults in `meson.options` or equivalent configuration files. Features enabled by default may have dependencies or requirements that conflict with minimal build configurations.

### 2. Introspection and Plugins

GObject introspection is crucial for dynamic plugin loading in GNOME-based applications. When disabling introspection:
- Either ensure all plugins are also disabled
- Or only enable plugins that don't require introspection for runtime loading

### 3. Symbol Resolution Debugging

The debugging workflow that worked well:
1. Use `LD_DEBUG=symbols` to identify which symbols can't be resolved
2. Use `nm -D` and `readelf -s` to verify what symbols libraries export
3. Use `ldd` to check library dependencies
4. Check source code to understand why symbols are being referenced

### 4. Minimal Builds Require Minimal Features

For a CLI-only build of foundry (no GTK), the following features should be disabled:
- `-Dgtk=false`
- `-Dintrospection=disabled`
- `-Ddocs=false`
- `-Dfeature-flatpak=false`
- `-Dfeature-llm=false`
- Potentially others depending on requirements

## Additional Issues Encountered

### Bottle Relocation Issue

When manually extracting the bottle, discovered that the ELF interpreter path contained an unreplaced placeholder:

```bash
$ file /home/linuxbrew/.linuxbrew/Cellar/foundry/1.0.0/bin/foundry
ELF 64-bit LSB executable, interpreter @@HOMEBREW_PREFIX@@/lib/ld.so
```

This indicates the bottle wasn't properly relocated. The `brew bottle` command should automatically replace these placeholders with actual paths.

**Root Cause:** Unknown - requires investigation into Homebrew's bottle relocation mechanism.

**Workaround:** Rebuild bottle using Homebrew's standard bottling process, ensuring relocation occurs properly.

## References

- libsoup 2.x API: Uses `SoupURI` type and `soup_uri_new()` function
- libsoup 3.x API: Uses `GUri` type from GLib (no `soup_uri_new()`)
- Foundry meson options: `/tmp/foundry-check/meson.options`
- Ollama plugin source: `/tmp/foundry-check/plugins/ollama/`
- GObject Introspection docs: https://gi.readthedocs.io/

## Commit History

1. **fix: disable LLM feature to resolve segfault** (commit 41c92f4)
   - Added `-Dfeature-llm=false` to meson args
   - Rebuilt bottle with new configuration
   - Updated bottle SHA in formula

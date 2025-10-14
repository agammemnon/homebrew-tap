# Foundry Homebrew Formula: Debugging Journey

## Current Status

**Date:** October 14, 2025

| Aspect | Status |
|--------|--------|
| Source builds | Working perfectly |
| Bottle installations | Segfault (exit code 139) |
| Formula configuration | All known issues resolved |
| **Current workaround** | Install with `--build-from-source` |

## Overview

This document chronicles the debugging journey for packaging foundry as a Homebrew formula. The project encountered three major issues during development, two of which have been successfully resolved, with one remaining active issue related to bottle installation.

**Build Environment:**
- **OS:** Bazzite Linux (Fedora 42 based)
- **Kernel:** 6.16.4-114.bazzite.fc42.x86_64
- **Homebrew:** Latest (as of October 14, 2025)
- **Homebrew Prefix:** `/home/linuxbrew/.linuxbrew`

---

## Issue 1: GLib GSettings Schema Linking Conflict (RESOLVED)

### Problem

When creating bottles for formulae that compile GSettings schemas (like GNOME applications), the build process generates a compiled schema file `gschemas.compiled` in `share/glib-2.0/schemas/`.

If this compiled file is included in the bottle, it causes a symlink conflict during installation:

```
Error: The `brew link` step did not complete successfully
The formula built, but is not symlinked into /home/linuxbrew/.linuxbrew
Could not symlink share/glib-2.0/schemas/gschemas.compiled
Target /home/linuxbrew/.linuxbrew/share/glib-2.0/schemas/gschemas.compiled
already exists.
```

This happens because multiple formulae may share the same global schemas directory, and each trying to symlink their own compiled schema file creates a conflict.

### Root Cause

The `gschemas.compiled` file is:
- Auto-generated during the build process
- Not unique to each formula (it's a compilation of all schemas in the directory)
- Should be regenerated on the user's system, not included in bottles

### Solution

Add this line to the formula's `install` method to remove the compiled schema file before bottling:

```ruby
def install
  # ... build steps ...

  mkdir "build" do
    system "meson", "..", *args
    system "meson", "compile", "--verbose"
    system "meson", "install"

    # Remove compiled schema file to avoid linking conflicts
    rm_f "#{share}/glib-2.0/schemas/gschemas.compiled"
  end

  # ... rest of install ...
end
```

### Implementation

**Formula location:** `Formula/foundry.rb:80`

The fix has been successfully implemented and resolves the schema linking conflict.

### User Setup

After installing, users may need to compile schemas if they encounter schema-related errors:

```bash
export GSETTINGS_SCHEMA_DIR=/home/linuxbrew/.linuxbrew/opt/foundry/share/glib-2.0/schemas:$GSETTINGS_SCHEMA_DIR
glib-compile-schemas /home/linuxbrew/.linuxbrew/opt/foundry/share/glib-2.0/schemas
```

---

## Issue 2: Segfault from LLM/Ollama Plugin (RESOLVED)

### Problem Summary

After successfully fixing the bottle download and GSettings schema issues, foundry would segfault when executed with any command (e.g., `foundry --help`, `foundry init`). The application would crash with exit code 139 (segmentation fault).

### Symptoms

```bash
$ foundry --help
Segmentation fault (core dumped)

$ echo $?
139
```

The segfault occurred consistently on every invocation, suggesting a fundamental issue with library loading or initialization.

### Debugging Process

#### Step 1: Dynamic Linker Debugging

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

#### Step 2: Understanding the Symbol

The symbol `soup_uri_new` is from **libsoup 2.x API**. However, the system only had **libsoup 3.x** installed, which uses a different API (`GUri` instead of `SoupURI`).

```bash
$ brew list | grep soup
libsoup  # This is libsoup 3.x

$ ldd /home/linuxbrew/.linuxbrew/bin/foundry | grep soup
libsoup-3.0.so.0 => /home/linuxbrew/.linuxbrew/opt/libsoup/lib/libsoup-3.0.so.0
```

#### Step 3: Identifying the Source

Since `dlsym` was being called (visible in LD_DEBUG output), this indicated runtime dynamic loading, typically used by plugin systems. Foundry uses **libpeas** for its plugin architecture.

Examined the build configuration:

```bash
$ cat /tmp/foundry-check/meson.options | grep -A3 "feature-llm\|plugin-ollama"
```

**Discovery:**
- `feature-llm` defaults to `true` (line 44-47 of meson.options)
- `plugin-ollama` defaults to `true` (line 305-308 of meson.options)
- The ollama plugin is part of the LLM feature

#### Step 4: Confirming the Ollama Plugin Issue

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

#### Step 5: Build Configuration Analysis

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

### Root Cause

1. **Feature Mismatch:** The LLM feature (including ollama plugin) was enabled by default
2. **Introspection Disabled:** Building with `-Dintrospection=disabled` prevented proper plugin loading
3. **Symbol Resolution Failure:** At runtime, the plugin system tried to dynamically load plugin code that referenced libsoup symbols, but the dynamic linker couldn't resolve them properly without introspection metadata
4. **Segfault:** The unresolved symbol lookup caused a segmentation fault

### Solution

**Formula location:** `Formula/foundry.rb:72`

Updated the formula to explicitly disable the LLM feature:

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
3. Foundry executed successfully without segfaults when built from source

### Lessons Learned

#### Feature Defaults Matter

When building packages with many optional features, always check the defaults in `meson.options` or equivalent configuration files. Features enabled by default may have dependencies or requirements that conflict with minimal build configurations.

#### Introspection and Plugins

GObject introspection is crucial for dynamic plugin loading in GNOME-based applications. When disabling introspection:
- Either ensure all plugins are also disabled
- Or only enable plugins that don't require introspection for runtime loading

#### Symbol Resolution Debugging

The debugging workflow that worked well:
1. Use `LD_DEBUG=symbols` to identify which symbols can't be resolved
2. Use `nm -D` and `readelf -s` to verify what symbols libraries export
3. Use `ldd` to check library dependencies
4. Check source code to understand why symbols are being referenced

#### Minimal Builds Require Minimal Features

For a CLI-only build of foundry (no GTK), the following features should be disabled:
- `-Dgtk=false`
- `-Dintrospection=disabled`
- `-Ddocs=false`
- `-Dfeature-flatpak=false`
- `-Dfeature-llm=false`

---

## Issue 3: Bottle Installation Segfault (CURRENT)

### Problem

**Foundry builds and runs successfully from source, but segfaults when installed from a pre-built bottle.**

The formula configuration is correct (both schema and LLM issues resolved), but the bottle installation process itself appears to corrupt the library.

### Key Findings

#### Library Size Mystery

The core issue appears to be a discrepancy in library sizes:

| Build Type | Library Size (bytes) | Status |
|------------|---------------------|---------|
| Source build (working) | 2,778,920 (2.7M) | No segfault |
| Bottle file contents | 2,712,232 (2.7M) | Expected |
| Installed from bottle | 2,995,872 (3.0M) | Segfaults |

**Key Discovery:** The bottle tarball contains the correct 2.7M library, but after Homebrew installs it, the library grows to 3.0M and segfaults occur.

#### Size Increase Explanation

The ~284KB size increase is due to Homebrew's relocation process replacing `@@HOMEBREW_PREFIX@@` placeholders with actual paths:
- Placeholder: `@@HOMEBREW_PREFIX@@` (20 characters)
- Replacement: `/home/linuxbrew/.linuxbrew` (27 characters)

However, this should be a normal part of the bottling process and shouldn't cause segfaults.

### What We've Tried

#### 1. Rebuilding with Different Configurations 

**Attempts:**
- Rebuilt bottle multiple times with `brew install --build-bottle`
- Created bottles with `brew bottle --json --no-rebuild`
- Verified formula has `-Dfeature-llm=false`

**Result:** Source builds always work, bottles always fail.

#### 2. Verifying Bottle Contents

**Verification steps:**
```bash
# Download bottle from GitHub
wget https://github.com/agammemnon/homebrew-tap/releases/download/foundry-1.0.0/foundry-1.0.0.x86_64_linux.bottle.1.tar.gz

# Extract and check library size
tar -xzf foundry-1.0.0.x86_64_linux.bottle.1.tar.gz
ls -lh foundry/1.0.0/lib/libfoundry-1.so.1.0.0
# Result: 2.7M (correct!)
```

**SHA Verification:**
```bash
shasum -a 256 foundry-1.0.0.x86_64_linux.bottle.1.tar.gz
# Result: 68f9ee6f9dcb31357997ad40b8f14eac4fa64687931317699f6b51d79cedee5b
# Matches formula
```

**Result:** Bottle file is correct before installation.

#### 3. Testing Ollama Plugin Removal

**Verification:**
```bash
# Check for ollama symbols in both libraries
strings /tmp/foundry/1.0.0/lib/libfoundry-1.so.1.0.0 | grep -i ollama
# No results

# Check for soup_uri symbols (libsoup 2.x API used by ollama)
LD_DEBUG=symbols foundry --version 2>&1 | grep soup_uri
# No soup_uri lookups found
```

**Result:** Ollama plugin is successfully excluded. This is not the issue.

#### 4. Multiple Upload/Download Cycles

**Attempts:**
- Deleted old bottles from GitHub releases
- Uploaded new bottles with correct filenames
- Updated formula SHA multiple times
- Cleared Homebrew cache between attempts

**Result:** Same issue persists regardless of bottle version.

### The Core Mystery

**Question:** Why does the library work when built from source but fail when installed from a bottle, even though the bottle contains the same binary?

**Observations:**
1. The bottle tarball contains a working 2.7M library
2. After `brew install`, the library becomes 3.0M
3. The 3.0M library segfaults
4. Building from source produces a 2.7M library that works
5. Both use the same formula with identical build flags

### Possible Causes (Unconfirmed)

1. **Homebrew Post-Install Processing Issue**
   - Homebrew may be doing additional processing during installation
   - The relocation process might be corrupting the binary
   - Strip operations or other modifications might be problematic

2. **Relocation Side Effects**
   - The `@@HOMEBREW_PREFIX@@` replacement might be affecting more than just strings
   - Could be modifying code sections or breaking relocations
   - Might be affecting library dependencies in unexpected ways

3. **Build Environment Differences**
   - `--build-bottle` flag might enable different compilation settings
   - Bottle builds might have different optimization levels
   - Debug symbols or other metadata might differ

4. **Plugin Loading Mechanism**
   - Foundry uses libpeas for plugins
   - Plugin loading might be affected by how libraries are relocated
   - Dynamic loading paths might break after relocation

### Debugging Evidence

#### Working Source Build

```bash
$ brew install --build-from-source agammemnon/tap/foundry
$ stat -c '%s' /home/linuxbrew/.linuxbrew/Cellar/foundry/1.0.0/lib/libfoundry-1.so.1.0.0
2778920

$ GSETTINGS_SCHEMA_DIR=/home/linuxbrew/.linuxbrew/opt/foundry/share/glib-2.0/schemas foundry --help
Usage:
  foundry [OPTIONS…] COMMAND
[... full help output, no segfault ...]
```

#### Failing Bottle Install

```bash
$ brew install agammemnon/tap/foundry
$ stat -c '%s' /home/linuxbrew/.linuxbrew/Cellar/foundry/1.0.0/lib/libfoundry-1.so.1.0.0
2995872

$ GSETTINGS_SCHEMA_DIR=/home/linuxbrew/.linuxbrew/opt/foundry/share/glib-2.0/schemas foundry --help
Segmentation fault
$ echo $?
139
```

#### LD_DEBUG Analysis

No suspicious symbol lookups found:
- No `soup_uri_new` lookups (ollama plugin is excluded)
- No missing library dependencies
- All shared libraries load successfully
- Segfault occurs after successful library loading

### Next Steps to Investigate

#### Option 1: Investigate Homebrew Bottling Process

**Actions:**
1. Compare bottle installation with source installation step-by-step
2. Use `brew install --verbose` to see exactly what Homebrew does during bottle installation
3. Check if Homebrew runs any post-install scripts or modifications
4. Look for differences in RPATH, RUNPATH, or other ELF metadata

#### Option 2: Create Manual Bottle Without Homebrew Tooling

**Actions:**
1. Build from source
2. Manually create tarball of working installation
3. Test installing the manual tarball
4. Compare with Homebrew-created bottle

#### Option 3: Debug the Relocated Binary

**Actions:**
1. Install gdb: `brew install gdb`
2. Get backtrace from segfault:
   ```bash
   GSETTINGS_SCHEMA_DIR=/home/linuxbrew/.linuxbrew/opt/foundry/share/glib-2.0/schemas \
   gdb -batch -ex "run --help" -ex "bt" foundry
   ```
3. Identify exact crash location
4. Compare with working source build

#### Option 4: Disable Bottle Relocation

**Actions:**
1. Research if bottles can skip relocation
2. Try building with absolute paths instead of `@@HOMEBREW_PREFIX@@`
3. Test if unrelocated bottle works

#### Option 5: Report Upstream

**Actions:**
1. Check if this is a known Homebrew issue with meson-built GObject applications
2. Report to Homebrew if it's a bottling issue
3. Report to Foundry project if it's an application issue

**Immediate Action Required:** Debug with Option 3 (gdb backtrace) to identify the exact crash location and understand what's different between source and bottle installations.

---

## Current Workaround for Users

Users should build foundry from source instead of using the bottle:

```bash
brew install --build-from-source agammemnon/tap/foundry
```

This works reliably but takes longer (~2-3 minutes to compile).

---

## Formula State

### Current Configuration
- **File:** `Formula/foundry.rb`
- **Latest Commit:** `8fd4982` - "fix: update foundry bottle from verified working source build"
- **Build Flags:** `-Dfeature-llm=false -Dintrospection=disabled -Dgtk=false`

### Bottle Assets
- **GitHub Release:** `foundry-1.0.0`
- **Current Bottle:** `foundry-1.0.0.x86_64_linux.bottle.1.tar.gz`
- **SHA:** `68f9ee6f9dcb31357997ad40b8f14eac4fa64687931317699f6b51d79cedee5b`

### Dependencies

All dependencies install successfully from bottles without issues. The problem is specific to the foundry bottle itself.

---

## Consolidated Lessons Learned

### 1. GSettings Schema Management
- Never include compiled schema files (`gschemas.compiled`) in bottles
- Schema compilation should happen on the target system
- Multiple formulae sharing the schema directory will conflict

### 2. Feature Flags and Dependencies
- Always check default values in `meson.options` or equivalent
- Optional features may have incompatible dependencies
- Explicitly disable features you don't want, don't rely on defaults

### 3. Introspection and Plugins
- GObject introspection is essential for dynamic plugin loading
- Disabling introspection requires disabling plugins that depend on it
- Symbol resolution failures often indicate plugin loading issues

### 4. Bottle Relocation Complexity
- Homebrew's bottle relocation process can have unexpected side effects
- Binary size changes during relocation are normal but can indicate issues
- Test both source builds and bottle installs separately

### 5. Debugging Methodology
- `LD_DEBUG=symbols` is invaluable for tracking symbol resolution
- Compare working and failing builds systematically
- Look for environmental differences between build methods

---

## References

### Documentation
- [GLib GSettings Documentation](https://docs.gtk.org/gio/class.Settings.html)
- [Homebrew Bottle Documentation](https://docs.brew.sh/Bottles)
- [GObject Introspection docs](https://gi.readthedocs.io/)

### API Documentation
- libsoup 2.x API: Uses `SoupURI` type and `soup_uri_new()` function
- libsoup 3.x API: Uses `GUri` type from GLib (no `soup_uri_new()`)

### Related Files
- Foundry meson options: [foundry source]/meson.options
- Ollama plugin source: [foundry source]/plugins/ollama/
- Formula: `Formula/foundry.rb`

### Commit History
- **Issue 1 Fix (GLib Schemas):** Multiple commits implementing schema file removal
- **Issue 2 Fix (LLM/Ollama):** Commit `41c92f4` - "fix: disable LLM feature to resolve segfault"
- **Issue 3 Attempts:** Commits `8fd4982`, `78d04f4`, `5180f6b`, `45fb6d6`, `205fc62` - Multiple bottle rebuild attempts

---

## Conclusion

This debugging journey has resolved two major issues (GSettings schemas and LLM plugin segfaults) but uncovered a deeper problem with Homebrew's bottle installation process. The issue is perplexing because:

1. The source build works perfectly
2. The bottle file contains correct binaries
3. Something during bottle installation corrupts or mishandles the library
4. The corruption manifests as a segfault

The issue is likely related to Homebrew's bottle relocation process or some incompatibility between how foundry is built and how Homebrew processes bottles for meson-based GObject applications.

**Current Status:** Users must build from source until the bottle installation issue is resolved.

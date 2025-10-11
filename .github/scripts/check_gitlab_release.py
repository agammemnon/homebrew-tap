#!/usr/bin/env python3

import argparse
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, Optional

import requests


class GitLabReleaseChecker:
    """Check for new GitLab releases and compare with formula version"""

    def __init__(
        self,
        project_path: str = "asus-linux/asusctl",
        formula_name: str = "asusctl",
        gitlab_host: str = "gitlab.com",
    ):
        self.project_path = project_path
        self.formula_name = formula_name
        self.gitlab_host = gitlab_host
        self.gitlab_token = os.environ.get("GITLAB_TOKEN")

    def fetch_latest_release(self) -> Optional[str]:
        """Fetch the latest release tag from GitLab API"""

        url = f"https://{self.gitlab_host}/api/v4/projects/{self.project_path.replace('/', '%2F')}/releases/permalink/latest"
        headers = {}

        if self.gitlab_token:
            headers["PRIVATE-TOKEN"] = self.gitlab_token

        try:
            response = requests.get(url, headers=headers, timeout=30)
            response.raise_for_status()
            data = response.json()
            return self._normalize_version(data.get("tag_name", ""))
        except requests.RequestException as request_error:
            print(f"Error fetching GitLab release: {request_error}", file=sys.stderr)
            return None

    def _normalize_version(self, version: str) -> str:
        """Remove 'v' prefix if present"""
        return version.lstrip("v")

    def get_formula_version(self, formula_path: str | None = None) -> Optional[str]:
        """Extract version from Homebrew formula"""

        if formula_path is None:
            formula_path = f"Formula/{self.formula_name}.rb"

        path = Path(formula_path)
        if not path.exists():
            print(f"Formula not found: {formula_path}", file=sys.stderr)
            return None

        content = path.read_text(encoding="utf-8")

        # Patterns to extract version from different formula URL formats
        # 1. Tarball archives: url "https://host/project/-/archive/1.2.3/project-1.2.3.tar.gz"
        # 2. Explicit version: version "1.2.3"
        # 3. Git tags: tag: "1.2.3" or tag: "v1.2.3"
        patterns = [
            r'url\s+"[^"]*\/archive\/v?([^\/\"]+)\/',
            r'version\s+"([^"]+)"',
            r'tag:\s+"v?([^"]+)"',
        ]

        for pattern in patterns:
            match = re.search(pattern, content)
            if match:
                return self._normalize_version(match.group(1))

        return None

    def compare_versions(
        self, gitlab_version: str, formula_version: str
    ) -> Dict[str, Any]:
        """Compare versions and determine if update is needed"""

        needs_update = gitlab_version != formula_version

        return {
            "needs_update": needs_update,
            "latest_version": gitlab_version,
            "current_version": formula_version,
            "new_version": gitlab_version if needs_update else "",
        }

    def set_github_output(self, data: Dict[str, Any]):
        """Set GitHub Actions output variables"""

        if "GITHUB_OUTPUT" not in os.environ:
            return

        with open(file=os.environ["GITHUB_OUTPUT"], mode="a", encoding="utf-8") as file:
            for key, value in data.items():
                if isinstance(value, bool):
                    value = str(value).lower()
                file.write(f"{key}={value}\n")
                file.write(f"{self.formula_name}_{key}={value}\n")

    def write_github_summary(self, data: Dict[str, Any]):
        """Write summary to GitHub Actions step summary"""

        if "GITHUB_STEP_SUMMARY" not in os.environ:
            return

        status = "Update needed" if data["needs_update"] else "Up-to-date"
        action = "Formula will be updated automatically" if data["needs_update"] else "No action required"

        summary = f"""# GitLab Release Check Results

## Formula: {self.formula_name}

| Property | Value |
|----------|-------|
| Current Formula Version | {data["current_version"]} |
| Latest GitLab Release | {data["latest_version"]} |
| Status | {status} |
| Action | {action} |

### Details
- **Project**: {self.project_path}
- **Checked at**: GitLab API latest release endpoint
"""

        with open(file=os.environ["GITHUB_STEP_SUMMARY"], mode="a", encoding="utf-8") as file:
            file.write(summary)

    def run(self) -> int:
        """Main execution flow"""

        print("Checking GitLab for latest release...")
        gitlab_version = self.fetch_latest_release()

        if not gitlab_version:
            print("Failed to fetch GitLab release", file=sys.stderr)
            return 1

        print(f"Latest GitLab release: {gitlab_version}")

        formula_version = self.get_formula_version()
        if not formula_version:
            print("Could not determine formula version, assuming update needed")
            formula_version = "unknown"
        else:
            print(f"Current formula version: {formula_version}")

        result = self.compare_versions(gitlab_version, formula_version)
        self.set_github_output(result)
        self.write_github_summary(result)

        if result["needs_update"]:
            print(f"New version available: {gitlab_version} → Update needed!")
            print(f"New {self.formula_name} version {gitlab_version} is available")
        else:
            print(f"Formula is up-to-date at version {gitlab_version}")

        return 0


def main():
    """Entry point"""

    parser = argparse.ArgumentParser(description="Check for GitLab release updates")
    parser.add_argument("--formula", default="asusctl", help="Formula name")
    parser.add_argument(
        "--project", default="asus-linux/asusctl", help="GitLab project path"
    )
    parser.add_argument(
        "--gitlab-host", default="gitlab.com", help="GitLab host (e.g., gitlab.com, gitlab.gnome.org)"
    )

    args = parser.parse_args()

    checker = GitLabReleaseChecker(
        project_path=args.project,
        formula_name=args.formula,
        gitlab_host=args.gitlab_host,
    )
    sys.exit(checker.run())


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Unit tests for update_manifest.py. Run with: python3 -m unittest discover jellyfin-plugin/scripts"""

import json
import os
import subprocess
import sys
import tempfile
import unittest

SCRIPT = os.path.join(os.path.dirname(__file__), "update_manifest.py")
BUILD_YAML = os.path.join(os.path.dirname(__file__), "..", "build.yaml")


def run_update(tmpdir, build_yaml, existing=None, version_suffix=""):
    output = os.path.join(tmpdir, f"manifest{version_suffix}.json")
    args = [
        sys.executable,
        SCRIPT,
        "--build-yaml",
        build_yaml,
        "--source-url",
        f"https://example.com/driftfin-plugin{version_suffix}.zip",
        "--checksum",
        f"checksum{version_suffix}",
        "--timestamp",
        "2026-01-01T00:00:00Z",
        "--image-url",
        "https://example.com/icon.png",
        "--output",
        output,
    ]
    if existing is not None:
        args += ["--existing", existing]
    subprocess.run(args, check=True)
    with open(output, encoding="utf-8") as f:
        return json.load(f)


class UpdateManifestTests(unittest.TestCase):
    def test_creates_new_entry_from_build_yaml(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            manifest = run_update(tmpdir, BUILD_YAML)

        self.assertEqual(len(manifest), 1)
        entry = manifest[0]
        self.assertEqual(entry["guid"], "a3b1e7c4-1d2f-4b8a-9c6e-7f0d2e5a9b11")
        self.assertEqual(entry["name"], "Driftfin")
        self.assertEqual(entry["owner"], "hamadtheironside")
        self.assertEqual(len(entry["versions"]), 1)
        version = entry["versions"][0]
        self.assertEqual(version["version"], "1.0.0.0")
        self.assertEqual(version["targetAbi"], "10.10.0.0")
        self.assertEqual(version["checksum"], "checksum")
        self.assertEqual(version["sourceUrl"], "https://example.com/driftfin-plugin.zip")

    def test_appends_new_version_to_existing_manifest_preserving_history(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            first = run_update(tmpdir, BUILD_YAML)
            existing_path = os.path.join(tmpdir, "existing.json")
            with open(existing_path, "w", encoding="utf-8") as f:
                json.dump(first, f)

            bumped_yaml = os.path.join(tmpdir, "build-v2.yaml")
            with open(BUILD_YAML, encoding="utf-8") as f:
                content = f.read()
            content = content.replace('version: "1.0.0.0"', 'version: "1.0.1.0"')
            with open(bumped_yaml, "w", encoding="utf-8") as f:
                f.write(content)

            second = run_update(tmpdir, bumped_yaml, existing=existing_path, version_suffix="2")

        self.assertEqual(len(second), 1, "must not create a second plugin entry for the same guid")
        versions = [v["version"] for v in second[0]["versions"]]
        self.assertEqual(versions, ["1.0.1.0", "1.0.0.0"], "newest version must sort first")

    def test_rerunning_same_version_replaces_rather_than_duplicates(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            first = run_update(tmpdir, BUILD_YAML)
            existing_path = os.path.join(tmpdir, "existing.json")
            with open(existing_path, "w", encoding="utf-8") as f:
                json.dump(first, f)

            second = run_update(tmpdir, BUILD_YAML, existing=existing_path, version_suffix="2")

        self.assertEqual(len(second[0]["versions"]), 1)
        self.assertEqual(second[0]["versions"][0]["checksum"], "checksum2")

    def test_output_is_valid_json_array_at_top_level(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            manifest = run_update(tmpdir, BUILD_YAML)
        self.assertIsInstance(manifest, list)


if __name__ == "__main__":
    unittest.main()

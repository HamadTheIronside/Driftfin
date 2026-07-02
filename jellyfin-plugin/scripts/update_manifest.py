#!/usr/bin/env python3
"""Upserts a plugin version into a Jellyfin plugin-repository manifest.json.

Reads plugin metadata (guid/name/description/...) from build.yaml, merges a
new version entry into the existing manifest (fetched from the live
gh-pages URL by the caller), and writes the result. Used by
.github/workflows/plugin.yaml on every `plugin-v*` tag push — see
jellyfin-plugin/README.md for the manifest schema and install instructions.
"""

import argparse
import json
import os

import yaml


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-yaml", required=True)
    parser.add_argument("--existing", help="Path to the current manifest.json, if any")
    parser.add_argument("--source-url", required=True)
    parser.add_argument("--checksum", required=True, help="MD5 hex digest of the release zip")
    parser.add_argument("--timestamp", required=True, help="ISO 8601 UTC timestamp")
    parser.add_argument("--image-url", default="")
    parser.add_argument("--output", required=True)
    return parser.parse_args()


def load_existing_manifest(path):
    if not path or not os.path.exists(path):
        return []
    with open(path, encoding="utf-8") as f:
        content = f.read().strip()
    return json.loads(content) if content else []


def version_key(version):
    return [int(part) for part in version.split(".")]


def main():
    args = parse_args()

    with open(args.build_yaml, encoding="utf-8") as f:
        meta = yaml.safe_load(f)

    manifest = load_existing_manifest(args.existing)

    entry = next((e for e in manifest if e.get("guid", "").lower() == meta["guid"].lower()), None)
    if entry is None:
        entry = {"guid": meta["guid"], "versions": []}
        manifest.append(entry)

    entry["name"] = meta["name"]
    entry["description"] = meta.get("description", "").strip()
    entry["overview"] = meta.get("overview", "").strip()
    entry["owner"] = meta["owner"]
    entry["category"] = meta.get("category", "General")
    if args.image_url:
        entry["imageUrl"] = args.image_url

    entry["versions"] = [v for v in entry["versions"] if v["version"] != meta["version"]]
    entry["versions"].append(
        {
            "version": meta["version"],
            "changelog": meta.get("changelog", "").strip(),
            "targetAbi": meta["targetAbi"],
            "sourceUrl": args.source_url,
            "checksum": args.checksum,
            "timestamp": args.timestamp,
        }
    )
    entry["versions"].sort(key=lambda v: version_key(v["version"]), reverse=True)

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
        f.write("\n")


if __name__ == "__main__":
    main()

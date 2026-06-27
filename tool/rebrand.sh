#!/usr/bin/env bash
#
# Re-apply the Driftfin rebrand on top of upstream Fladder code.
# Idempotent — safe to run any number of times. Run it after every
# `git merge upstream/develop`, because upstream keeps writing
# `package:fladder/` imports in new/changed files.
#
# Usage:
#   tool/rebrand.sh
#   fvm flutter pub get && fvm flutter analyze   # verify afterwards
#
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Dart package imports: package:fladder/ -> package:driftfin/"
grep -rlZ --include='*.dart' 'package:fladder/' lib test 2>/dev/null \
  | xargs -0 -r sed -i 's#package:fladder/#package:driftfin/#g'

echo "==> Deep-link scheme: fladder:// -> driftfin://"
sed -i 's/const _client = "fladder";/const _client = "driftfin";/' \
  lib/providers/service_provider.dart 2>/dev/null || true
grep -rlZ --include='*.dart' 'fladder:///' lib 2>/dev/null \
  | xargs -0 -r sed -i 's#fladder:///#driftfin:///#g'

# Visible-branding files (pubspec name, web/, ios/, windows/) are committed and
# usually survive a merge untouched; only re-check them if upstream edited the
# same lines (git will flag those as conflicts). See FORK.md.

echo "==> Done. Now run: fvm flutter pub get && fvm flutter analyze"

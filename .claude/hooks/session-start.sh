#!/bin/bash
# Installs the fvm-pinned Flutter SDK (see .fvmrc) plus the native
# dependencies Driftfin needs on Linux, so `flutter analyze`/`test`/`build`
# work without manual setup in Claude Code on the web sessions.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

REPO_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
FVM_VERSIONS_DIR="${HOME}/fvm/versions"

FLUTTER_VERSION="$(jq -r '.flutter' "${REPO_DIR}/.fvmrc")"
if [ -z "${FLUTTER_VERSION}" ] || [ "${FLUTTER_VERSION}" = "null" ]; then
  echo "error: could not read .flutter version from ${REPO_DIR}/.fvmrc" >&2
  exit 1
fi

TARGET_DIR="${FVM_VERSIONS_DIR}/${FLUTTER_VERSION}"
MARKER="${TARGET_DIR}/.driftfin_install_complete"

# The Flutter SDK archive is a git checkout owned by its packaged uid; running
# as root (as these sessions do) makes git refuse it as "dubious ownership"
# and every `flutter` invocation fails with exit 128.
git config --global --add safe.directory '*'

# CI=true suppresses the "running as root"/animated-spinner prompts so the
# hook's output stays readable and non-interactive.
export CI=true

# ---- native build dependencies (Linux desktop + libmpv player backend) ----
APT_PACKAGES="libmpv-dev clang cmake ninja-build pkg-config libgtk-3-dev libcurl4-openssl-dev"
MISSING_PACKAGES=""
for pkg in $APT_PACKAGES; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    MISSING_PACKAGES="${MISSING_PACKAGES} ${pkg}"
  fi
done
if [ -n "${MISSING_PACKAGES}" ]; then
  echo "Installing native dependencies:${MISSING_PACKAGES}"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  # shellcheck disable=SC2086
  apt-get install -y -qq ${MISSING_PACKAGES}
fi

# ---- Flutter SDK, pinned to .fvmrc, laid out the way fvm would ----
if [ ! -f "${MARKER}" ]; then
  echo "Installing Flutter ${FLUTTER_VERSION} into ${TARGET_DIR}"

  RELEASES_JSON="$(curl -fsSL --max-time 60 "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json")"
  ARCHIVE_PATH="$(echo "${RELEASES_JSON}" | jq -r --arg v "${FLUTTER_VERSION}" '.releases[] | select(.version == $v) | .archive' | head -n1)"
  ARCHIVE_SHA256="$(echo "${RELEASES_JSON}" | jq -r --arg v "${FLUTTER_VERSION}" '.releases[] | select(.version == $v) | .sha256' | head -n1)"

  if [ -z "${ARCHIVE_PATH}" ] || [ "${ARCHIVE_PATH}" = "null" ]; then
    echo "error: Flutter ${FLUTTER_VERSION} not found in releases_linux.json" >&2
    exit 1
  fi

  WORK_DIR="$(mktemp -d)"
  trap 'rm -rf "${WORK_DIR}"' EXIT

  ARCHIVE_FILE="${WORK_DIR}/flutter.tar.xz"
  curl -fsSL --max-time 900 -o "${ARCHIVE_FILE}" "https://storage.googleapis.com/flutter_infra_release/releases/${ARCHIVE_PATH}"

  echo "${ARCHIVE_SHA256}  ${ARCHIVE_FILE}" | sha256sum -c -

  tar -xJf "${ARCHIVE_FILE}" -C "${WORK_DIR}"
  mkdir -p "${FVM_VERSIONS_DIR}"
  rm -rf "${TARGET_DIR}"
  mv "${WORK_DIR}/flutter" "${TARGET_DIR}"

  "${TARGET_DIR}/bin/flutter" config --no-analytics --no-cli-animations >/dev/null

  touch "${MARKER}"
else
  echo "Flutter ${FLUTTER_VERSION} already installed at ${TARGET_DIR}"
fi

# ---- make FLUTTER/DART available exactly as CLAUDE.md's command cheat-sheet expects ----
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export FLUTTER=\"${TARGET_DIR}/bin/flutter\""
    echo "export DART=\"${TARGET_DIR}/bin/dart\""
    echo "export PATH=\"${TARGET_DIR}/bin:\${PATH}\""
  } >> "${CLAUDE_ENV_FILE}"
fi

echo "Fetching pub packages"
(cd "${REPO_DIR}" && "${TARGET_DIR}/bin/flutter" pub get)

echo "Flutter ${FLUTTER_VERSION} ready at ${TARGET_DIR}"

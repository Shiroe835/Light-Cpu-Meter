#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SOURCE_APP="${PROJECT_ROOT}/CPUMonitor.app"
TARGET_DIR="${1:-/Applications}"

if [ ! -d "${SOURCE_APP}" ]; then
    echo "Application bundle not found at ${SOURCE_APP}. Building first..."
    bash "${SCRIPT_DIR}/build.sh"
fi

echo "=== Installing CPU Monitor to ${TARGET_DIR} ==="
mkdir -p "${TARGET_DIR}"

# Quit existing running instance if any
pkill -x "CPUMonitor" 2>/dev/null || true

# Copy application
rm -rf "${TARGET_DIR}/CPUMonitor.app"
cp -R "${SOURCE_APP}" "${TARGET_DIR}/"

echo "=== Installation Complete ==="
echo "CPUMonitor.app installed to ${TARGET_DIR}/CPUMonitor.app"
echo "You can launch it via: open \"${TARGET_DIR}/CPUMonitor.app\""

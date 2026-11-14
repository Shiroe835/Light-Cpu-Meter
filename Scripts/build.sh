#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== Building CPU Monitor for macOS (Intel x86_64 + Universal) ==="
cd "${PROJECT_ROOT}"

# Ensure project file is up to date
python3 "${SCRIPT_DIR}/generate_project.py"

# Build with xcodebuild
mkdir -p build/DerivedData
TMPDIR=/tmp xcodebuild \
    -project CPUMonitor.xcodeproj \
    -scheme CPUMonitor \
    -configuration Release \
    -derivedDataPath "${PROJECT_ROOT}/build/DerivedData" \
    -destination 'generic/platform=macOS' \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    build

# Copy final application bundle
mkdir -p "${PROJECT_ROOT}/build/Release"
rm -rf "${PROJECT_ROOT}/build/Release/CPUMonitor.app" "${PROJECT_ROOT}/CPUMonitor.app"
cp -R "${PROJECT_ROOT}/build/DerivedData/Build/Products/Release/CPUMonitor.app" "${PROJECT_ROOT}/build/Release/"
cp -R "${PROJECT_ROOT}/build/Release/CPUMonitor.app" "${PROJECT_ROOT}/"

echo ""
echo "=== Build Successful ==="
echo "Application built at: ${PROJECT_ROOT}/CPUMonitor.app"
lipo -info "${PROJECT_ROOT}/CPUMonitor.app/Contents/MacOS/CPUMonitor"
echo "========================"

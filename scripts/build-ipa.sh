#!/usr/bin/env bash
#
# 在 macOS 上直接编译 AspectLab 并打成未签名 ipa。
# 不需要 Xcode 工程，不需要 CocoaPods，只依赖 Xcode 命令行工具。
#
# 用法：
#   bash scripts/build-ipa.sh
#
# 产物：
#   build/AspectLab-unsigned.ipa
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="AspectLab"
DISPLAY_NAME="宽高比实验室"
MIN_IOS="17.0"
BUNDLE_ID="com.aspectlab.app"
BUILD_DIR="$ROOT/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
PAYLOAD_DIR="$BUILD_DIR/Payload"
IPA_PATH="$BUILD_DIR/$APP_NAME-unsigned.ipa"

echo "==> 清理"
rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR" "$PAYLOAD_DIR"

echo "==> 检查工具链"
xcrun --sdk iphoneos --show-sdk-path >/dev/null
SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
echo "    SDK: $SDK_PATH"

SOURCES=()
while IFS= read -r -d '' f; do
  SOURCES+=("$f")
done < <(find "$ROOT/Sources" -name '*.swift' -print0)

if [ "${#SOURCES[@]}" -eq 0 ]; then
  echo "!! 没有找到 Swift 源文件" >&2
  exit 1
fi
echo "    源文件: ${#SOURCES[@]} 个"

echo "==> 编译（arm64 / iOS ${MIN_IOS}）"
xcrun --sdk iphoneos swiftc \
  -sdk "$SDK_PATH" \
  -F "$SDK_PATH/System/Library/Frameworks" \
  -target "arm64-apple-ios${MIN_IOS}" \
  -swift-version 5 \
  -module-name "$APP_NAME" \
  -parse-as-library \
  -O \
  -whole-module-optimization \
  -framework SwiftUI \
  -framework UIKit \
  -framework Foundation \
  -framework CoreGraphics \
  -framework Combine \
  -Xlinker -dead_strip \
  "${SOURCES[@]}" \
  -o "$APP_DIR/$APP_NAME"

echo "==> 组装 .app"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Info.plist"
if [ -d "$ROOT/Resources/Icons" ]; then
  cp "$ROOT/Resources/Icons/"*.png "$APP_DIR/" 2>/dev/null || true
fi

if [ ! -f "$APP_DIR/$APP_NAME" ]; then
  echo "!! 可执行文件缺失" >&2
  exit 1
fi

echo "==> 打包 ipa"
cp -R "$APP_DIR" "$PAYLOAD_DIR/"
(
  cd "$BUILD_DIR"
  rm -f "$APP_NAME-unsigned.ipa"
  ditto -c -k --sequesterRsrc --keepParent "Payload" "$APP_NAME-unsigned.ipa"
)

SIZE="$(du -h "$IPA_PATH" | cut -f1)"
echo ""
echo "完成: $IPA_PATH  ($SIZE)"
echo "未签名。用 SideStore / AltStore / Sideloadly 以自己的证书重签后再安装。"
echo ""
echo "校验:"
unzip -l "$IPA_PATH" | head -20

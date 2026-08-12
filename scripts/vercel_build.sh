#!/bin/bash
# سكربت بناء Flutter Web لبيئة Vercel
# يُنزّل Flutter SDK ويبني التطبيق للنشر على الويب
set -e

FLUTTER_VERSION="3.38.5-stable"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}.tar.xz"

echo "==> تنزيل Flutter SDK ${FLUTTER_VERSION}..."
curl -sSL -o flutter.tar.xz "$FLUTTER_URL"

echo "==> فك الضغط..."
tar xf flutter.tar.xz
rm flutter.tar.xz

export PATH="$PWD/flutter/bin:$PATH"

echo "==> إعداد Flutter..."
flutter config --no-analytics
flutter doctor -v

echo "==> تنزيل التبعيات..."
flutter pub get

echo "==> بناء التطبيق للويب..."
flutter build web --release

echo "==> البناء اكتمل بنجاح ✅"

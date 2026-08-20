#!/usr/bin/env bash
# بناء نسخة الويب على Vercel.
# السبب: حاوية البناء في Vercel لا تحتوي Flutter، فنجلبه هنا قبل البناء.
set -euo pipefail

# نثبّت الإصدار بدقّة لأن Dart بداخله (3.10.4) هو ما يحقّق قيد pubspec.yaml (^3.10.4)
FLUTTER_VERSION="3.38.5"
FLUTTER_DIR="${HOME:-/tmp}/flutter"

if [ ! -x "${FLUTTER_DIR}/bin/flutter" ]; then
  echo "==> جلب Flutter ${FLUTTER_VERSION}"
  git clone --depth 1 --branch "${FLUTTER_VERSION}" \
    https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"
# مالك مجلد الـ SDK قد يختلف عن مستخدم البناء، وgit يرفض العمل حينها
git config --global --add safe.directory "${FLUTTER_DIR}" || true

flutter --version
flutter pub get

# ‏--no-web-resources-cdn: نستضيف CanvasKit من نفس النطاق بدل gstatic،
# فلا يبقى التطبيق رهينة تحميل خارجي قد يُحجب أو يبطؤ.
flutter build web --release --no-web-resources-cdn

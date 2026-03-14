#!/usr/bin/env bash
set -e
OUT=artifacts/mobile_setup
mkdir -p "$OUT"
# System info
uname -a > "$OUT/uname.txt" 2>&1
if command -v lsb_release >/dev/null; then
  lsb_release -a > "$OUT/os_release.txt" 2>&1
else
  cat /etc/os-release > "$OUT/os_release.txt" 2>&1
fi
# Git info
git rev-parse --show-toplevel > "$OUT/git_root.txt" 2>&1 || true
git status --porcelain > "$OUT/git_status.txt" 2>&1
git remote -v > "$OUT/git_remote.txt" 2>&1
# Flutter / Dart
command -v flutter > "$OUT/flutter_path.txt" 2>&1 || true
flutter --version > "$OUT/flutter_version.txt" 2>&1 || true
flutter doctor --verbose > "$OUT/flutter_doctor.txt" 2>&1 || true
# Java / JDK
java -version > "$OUT/java_version.txt" 2>&1 || true
javac -version > "$OUT/javac_version.txt" 2>&1 || true
# Android SDK tools
command -v sdkmanager > "$OUT/sdkmanager_path.txt" 2>&1 || true
sdkmanager --list > "$OUT/sdkmanager_list.txt" 2>&1 || true
command -v avdmanager > "$OUT/avdmanager_path.txt" 2>&1 || true
emulator -list-avds > "$OUT/emulator_avds.txt" 2>&1 || true
# ADB
command -v adb > "$OUT/adb_path.txt" 2>&1 || true
adb devices -l > "$OUT/adb_devices.txt" 2>&1 || true
# Android Studio / SDK dir
ls -d "$HOME/Android/Sdk" > "$OUT/android_sdk_dir.txt" 2>&1 || true
command -v studio.sh > "$OUT/android_studio_exec.txt" 2>&1 || true
command -v android-studio > "$OUT/android_studio_exec.txt" 2>&1 || true
# iOS toolchain (Darwin only)
if [[ "$(uname -s)" == "Darwin" ]]; then
  xcodebuild -version > "$OUT/xcodebuild.txt" 2>&1 || true
  xcrun simctl list devices > "$OUT/simctl_devices.txt" 2>&1 || true
fi
# Docker / Node / npm / npx
command -v docker > "$OUT/docker_path.txt" 2>&1 || true
docker --version > "$OUT/docker_version.txt" 2>&1 || true
command -v node > "$OUT/node_path.txt" 2>&1 || true
node --version > "$OUT/node_version.txt" 2>&1 || true
command -v npm > "$OUT/npm_path.txt" 2>&1 || true
npm --version > "$OUT/npm_version.txt" 2>&1 || true
command -v npx > "$OUT/npx_path.txt" 2>&1 || true
npx --version > "$OUT/npx_version.txt" 2>&1 || true
# Map / mermaid CLI
command -v mmdc > "$OUT/mmdc_path.txt" 2>&1 || true
command -v wkhtmltoimage > "$OUT/wkhtmltoimage_path.txt" 2>&1 || true

# Docs creation
cat > docs/flutter_setup.md <<'EOF'
# Flutter Setup

Install Flutter SDK following https://flutter.dev/docs/get-started/install.
Ensure `flutter` is in your PATH.
Run `flutter doctor` and address any issues.
EOF

cat > docs/week2_plan.md <<'EOF'
# Week 2 Plan

- Day 1: Verify environment, install missing tools.
- Day 2: Create Flutter project or placeholder.
- Day 3: Run basic app, test on emulator.
- Day 4: CI pipeline setup.
- Day 5: Documentation and final packaging.
EOF

# Scripts creation
cat > scripts/run_emulator.sh <<'EOF'
#!/usr/bin/env bash
# Launch first available Android emulator
emulator=$(emulator -list-avds | head -n1)
if [[ -z "$emulator" ]]; then
  echo "No AVDs found."
  exit 1
fi
emulator -avd "$emulator"
EOF
chmod +x scripts/run_emulator.sh

cat > scripts/flutter_doctor_collect.sh <<'EOF'
#!/usr/bin/env bash
flutter doctor --verbose
EOF
chmod +x scripts/flutter_doctor_collect.sh

# Workflow creation
cat > .github/workflows/flutter-ci.yml <<'EOF'
name: Flutter CI

on:
  push:
    paths:
      - '**.dart'
      - 'pubspec.yaml'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter test
EOF

# Copy docs and scripts to artifacts
cp docs/flutter_setup.md "$OUT/docs_flutter_setup.md"
cp docs/week2_plan.md "$OUT/docs_week2_plan.md"
cp scripts/run_emulator.sh "$OUT/run_emulator.sh"
cp scripts/flutter_doctor_collect.sh "$OUT/flutter_doctor_collect.sh"

# Mobile app handling
if command -v flutter >/dev/null && [ ! -d mobile_app ]; then
  flutter create mobile_app > "$OUT/flutter_create.out" 2>&1 || true
  head -n 200 "$OUT/flutter_create.out" > "$OUT/flutter_create_head.txt" 2>&1 || true
  (cd mobile_app && flutter pub get) > "$OUT/flutter_pub_get.out" 2>&1 || true
else
  if [ -d mobile_app ]; then
    head -n 40 mobile_app/pubspec.yaml > "$OUT/mobile_pubspec_head.txt" 2>&1 || true
  else
    mkdir -p mobile_app
    echo "# Mobile App Placeholder" > mobile_app/README.md
    cp mobile_app/README.md "$OUT/mobile_app_README.md"
  fi
fi

# Update .gitignore
if ! grep -q '^# Mobile' .gitignore; then
  echo -e "\n# Mobile\n*.apk\n*.ipa\n/build/\n/.gradle/\n/.flutter-plugins\n/.flutter-plugins-dependencies\n/.packages\n.pub/\n" >> .gitignore
fi
cp .gitignore "$OUT/gitignore_after.txt"

# Log tails
[ -f artifacts/fix_run/uvicorn.log ] && tail -n 300 artifacts/fix_run/uvicorn.log > "$OUT/uvicorn_tail.log" || true
[ -f artifacts/fix_run/mdns_advertiser.log ] && tail -n 300 artifacts/fix_run/mdns_advertiser.log > "$OUT/mdns_tail.log" || true

# Git commit & push
git add docs/flutter_setup.md docs/week2_plan.md scripts/run_emulator.sh scripts/flutter_doctor_collect.sh .github/workflows/flutter-ci.yml mobile_app/README.md .gitignore || true
if git diff --cached --quiet; then
  echo "NO_STAGED_CHANGES" > "$OUT/git_commit_result.txt"
else
  git commit -m "chore(mobile): add Week-2 setup docs & workflow" > "$OUT/git_commit_out.txt" 2>&1 || true
  git rev-parse --short HEAD > "$OUT/git_commit_hash.txt" 2>&1 || true
  git push origin HEAD > "$OUT/git_push_out.txt" 2>&1 || true
fi

# Tarball creation
tar -czf artifacts/mobile_setup/week2_full_check.tar.gz -C artifacts mobile_setup || true

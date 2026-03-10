#!/usr/bin/env bash
# FAST Week-2 Mobile setup script
OUT=artifacts/mobile_setup
mkdir -p $OUT

# STEP 2 – System info
uname -a > $OUT/system_uname.txt 2>&1
cat /etc/os-release > $OUT/os_release.txt 2>&1 || true

# STEP 3 – Verify repository structure
pwd > $OUT/repo_path.txt
ls -1 > $OUT/repo_root_files.txt
if [[ -d backend && -d discovery ]]; then
  echo "PASS" > $OUT/repo_structure.txt
else
  echo "FAIL" > $OUT/repo_structure.txt
fi

# STEP 4 – Check Flutter installation (FAST)
which flutter > $OUT/flutter_path.txt 2>&1 || echo "NOT FOUND" > $OUT/flutter_path.txt
flutter --version > $OUT/flutter_version.txt 2>&1 || true
if grep -q "Flutter" $OUT/flutter_version.txt; then
  echo "PASS" > $OUT/flutter_installed.txt
else
  echo "FAIL" > $OUT/flutter_installed.txt
fi

# STEP 5 – Check Dart
which dart > $OUT/dart_path.txt 2>&1 || echo "NOT FOUND" > $OUT/dart_path.txt
dart --version > $OUT/dart_version.txt 2>&1 || true
if grep -q "Dart" $OUT/dart_version.txt; then
  echo "PASS" > $OUT/dart_installed.txt
else
  echo "FAIL" > $OUT/dart_installed.txt
fi

# STEP 6 – Check Java / Android toolchain
which java > $OUT/java_path.txt 2>&1 || echo "NOT FOUND" > $OUT/java_path.txt
java -version > $OUT/java_version.txt 2>&1 || true
# java -version outputs to stderr
if java -version 2>&1 | grep -qE "java version|openjdk version"; then
  echo "PASS" > $OUT/java_installed.txt
else
  echo "FAIL" > $OUT/java_installed.txt
fi

# STEP 7 – Check Android SDK directory
echo $ANDROID_HOME > $OUT/android_home.txt 2>&1 || true
ls $HOME/Android/Sdk > $OUT/android_sdk_dir.txt 2>&1 || true
if [ -s $OUT/android_sdk_dir.txt ]; then
  echo "PASS" > $OUT/android_sdk_detected.txt
else
  echo "FAIL" > $OUT/android_sdk_detected.txt
fi

# STEP 8 – Check ADB
which adb > $OUT/adb_path.txt 2>&1 || echo "NOT FOUND" > $OUT/adb_path.txt
adb devices > $OUT/adb_devices.txt 2>&1 || true
if adb --version >/dev/null 2>&1; then
  echo "PASS" > $OUT/adb_working.txt
else
  echo "FAIL" > $OUT/adb_working.txt
fi

# STEP 9 – Check Node / npm
which node > $OUT/node_path.txt 2>&1 || echo "NOT FOUND" > $OUT/node_path.txt
node --version > $OUT/node_version.txt 2>&1 || true
which npm > $OUT/npm_path.txt 2>&1 || echo "NOT FOUND" > $OUT/npm_path.txt
npm --version > $OUT/npm_version.txt 2>&1 || true
if node --version >/dev/null 2>&1; then
  echo "PASS" > $OUT/node_installed.txt
else
  echo "FAIL" > $OUT/node_installed.txt
fi

# STEP 10 – Check Docker
which docker > $OUT/docker_path.txt 2>&1 || echo "NOT FOUND" > $OUT/docker_path.txt
docker --version > $OUT/docker_version.txt 2>&1 || true
if docker --version >/dev/null 2>&1; then
  echo "PASS" > $OUT/docker_installed.txt
else
  echo "FAIL" > $OUT/docker_installed.txt
fi

# STEP 11 – Prepare Flutter mobile project
if [ ! -d mobile_app ]; then
  if command -v flutter >/dev/null; then
    flutter create mobile_app > $OUT/flutter_create_output.txt 2>&1 || true
    if [ -d mobile_app ]; then
      (cd mobile_app && flutter pub get) > $OUT/flutter_pub_get.txt 2>&1 || true
    fi
  else
    mkdir -p mobile_app
    echo "Flutter mobile app placeholder" > mobile_app/README.md
  fi
fi

if [ -f mobile_app/pubspec.yaml ]; then
  head -n 20 mobile_app/pubspec.yaml > $OUT/mobile_pubspec_head.txt
  echo "PASS" > $OUT/mobile_app_created.txt
elif [ -f mobile_app/README.md ]; then
  echo "PASS (Placeholder)" > $OUT/mobile_app_created.txt
else
  echo "FAIL" > $OUT/mobile_app_created.txt
fi

# STEP 13 – Create Week-2 documentation
cat > docs/flutter_setup.md <<'EOF'
# Flutter Setup

Install Flutter SDK following https://flutter.dev/docs/get-started/install.
Run `flutter doctor` and resolve any issues.
Use `flutter emulators` to list and launch Android emulators.
Connect the app to the backend at http://localhost:8000.
Run the app with `flutter run`.
EOF

cat > docs/week2_plan.md <<'EOF'
# Week 2 Plan

Day 8 — Flutter project + MapLibre
Day 9 — Offline tiles
Day 10 — Tile server integration
Day 11 — Cache service worker
Day 12 — Sync incidents
Day 13 — OSRM backend
Day 14 — Offline navigation
EOF

cp docs/flutter_setup.md $OUT/docs_flutter_setup.md 2>/dev/null || true
cp docs/week2_plan.md $OUT/docs_week2_plan.md 2>/dev/null || true

# STEP 14 – Create helper scripts
cat > scripts/run_emulator.sh <<'EOF'
#!/usr/bin/env bash
flutter emulators
flutter emulators --launch
EOF
chmod +x scripts/run_emulator.sh

cat > scripts/flutter_check.sh <<'EOF'
#!/usr/bin/env bash
flutter --version
adb devices
EOF
chmod +x scripts/flutter_check.sh

cp scripts/run_emulator.sh $OUT/run_emulator.sh 2>/dev/null || true
cp scripts/flutter_check.sh $OUT/flutter_check.sh 2>/dev/null || true

# STEP 15 – Add Flutter CI workflow
mkdir -p .github/workflows
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
      - run: flutter analyze
      - run: flutter test
EOF

cp .github/workflows/flutter-ci.yml $OUT/flutter_ci.yml 2>/dev/null || true

# STEP 16 – Update .gitignore for Flutter
if ! grep -q "mobile_app/build/" .gitignore; then
  echo -e "\n# Flutter mobile app\nmobile_app/build/\nmobile_app/.dart_tool/\nmobile_app/.idea/" >> .gitignore
fi
cp .gitignore $OUT/gitignore_after.txt

# STEP 17 – Git commit (docs + setup only)
git add docs/flutter_setup.md docs/week2_plan.md scripts/run_emulator.sh scripts/flutter_check.sh .github/workflows/flutter-ci.yml mobile_app/README.md .gitignore 2>/dev/null || true
if git diff --cached --quiet; then
  echo "NO_STAGED_CHANGES" > $OUT/git_commit.txt
else
  git commit -m "chore(mobile): prepare Flutter environment for Week 2" > $OUT/git_commit.txt 2>&1 || true
  git rev-parse --short HEAD > $OUT/git_commit_hash.txt 2>&1 || true
  git push origin HEAD > $OUT/git_push.txt 2>&1 || true
fi

# STEP 18 – Package artifacts (avoid recursion)
tar -czf artifacts/week2_prep_fastcheck.tar.gz -C artifacts mobile_setup || true
mv artifacts/week2_prep_fastcheck.tar.gz artifacts/mobile_setup/week2_prep_fastcheck.tar.gz || true

# STEP 19 – Generate summary report
cat > $OUT/report_summary.txt <<EOF
Repo structure: $(cat $OUT/repo_structure.txt 2>/dev/null || echo "N/A")
Flutter installed: $(cat $OUT/flutter_installed.txt 2>/dev/null || echo "N/A")
Dart installed: $(cat $OUT/dart_installed.txt 2>/dev/null || echo "N/A")
Java installed: $(cat $OUT/java_installed.txt 2>/dev/null || echo "N/A")
Android SDK detected: $(cat $OUT/android_sdk_detected.txt 2>/dev/null || echo "N/A")
ADB working: $(cat $OUT/adb_working.txt 2>/dev/null || echo "N/A")
Node installed: $(cat $OUT/node_installed.txt 2>/dev/null || echo "N/A")
Docker installed: $(cat $OUT/docker_installed.txt 2>/dev/null || echo "N/A")
Mobile app created: $(cat $OUT/mobile_app_created.txt 2>/dev/null || echo "N/A")
Docs created: $( [ -f docs/flutter_setup.md -a -f docs/week2_plan.md ] && echo PASS || echo FAIL )
Scripts created: $( [ -f scripts/run_emulator.sh -a -x scripts/run_emulator.sh -a -f scripts/flutter_check.sh -a -x scripts/flutter_check.sh ] && echo PASS || echo FAIL )
CI workflow created: $( [ -f .github/workflows/flutter-ci.yml ] && echo PASS || echo FAIL )
Git commit result: $(head -n 1 $OUT/git_commit.txt 2>/dev/null || echo "N/A")
EOF

#!/usr/bin/env bash
set -euo pipefail

ROOT="$PWD/work"

# Prefer a Flutter project when pubspec.yaml and android/ are present.
FLUTTER_FILE="$(find "$ROOT" -type f -name pubspec.yaml -not -path '*/.dart_tool/*' | head -n 1 || true)"
if [ -n "$FLUTTER_FILE" ]; then
  PROJECT_DIR="$(dirname "$FLUTTER_FILE")"
  if [ ! -d "$PROJECT_DIR/android" ]; then
    echo "::error::Flutter project found, but its android/ directory is missing."
    exit 1
  fi
  echo "Flutter project: $PROJECT_DIR"
  cd "$PROJECT_DIR"

  # Install Flutter stable on the GitHub-hosted runner.
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$RUNNER_TEMP/flutter"
  echo "$RUNNER_TEMP/flutter/bin" >> "$GITHUB_PATH"
  export PATH="$RUNNER_TEMP/flutter/bin:$PATH"

  flutter --version
  flutter pub get
  flutter build apk --debug
  exit 0
fi

# Otherwise locate a native Android Gradle project.
GRADLE_FILE="$(find "$ROOT" -type f \( -name settings.gradle -o -name settings.gradle.kts \) | head -n 1 || true)"
if [ -z "$GRADLE_FILE" ]; then
  echo "::error::Could not find pubspec.yaml or settings.gradle(.kts) in the ZIP."
  exit 1
fi

PROJECT_DIR="$(dirname "$GRADLE_FILE")"
echo "Native Android project: $PROJECT_DIR"
cd "$PROJECT_DIR"

if [ ! -f ./gradlew ]; then
  echo "::error::Gradle wrapper (gradlew) is missing. Include gradlew and gradle/wrapper in the ZIP."
  exit 1
fi

chmod +x ./gradlew
./gradlew --no-daemon assembleDebug

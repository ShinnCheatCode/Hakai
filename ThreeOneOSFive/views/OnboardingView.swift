# FILE: .github/workflows/build.yml

name: Build ThreeOneOSFive

on:
  push:
    branches:
      - main
      - master
  pull_request:
    branches:
      - main
      - master
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: build-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    name: Build iOS app (unsigned)
    runs-on: macos-14
    timeout-minutes: 30

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 1

      - name: Select Xcode
        run: |
          sudo xcode-select -s /Applications/Xcode_15.4.app
          xcodebuild -version

      - name: Verify project files
        shell: bash
        run: |
          set -euo pipefail

          test -f "ThreeOneOSFive.xcodeproj/project.pbxproj"
          test -f "ThreeOneOSFive/Info.plist"
          test -f "ThreeOneOSFive/App.swift"
          test -d "ThreeOneOSFive/Assets.xcassets"

          echo "Project structure OK"

      - name: Check Xcode project
        shell: bash
        run: |
          set -euo pipefail
          xcodebuild -list \
            -project "ThreeOneOSFive.xcodeproj"

      - name: Build
        shell: bash
        run: |
          set -euo pipefail

          xcodebuild \
            -project "ThreeOneOSFive.xcodeproj" \
            -scheme "ThreeOneOSFive" \
            -configuration Release \
            -sdk iphoneos \
            -destination 'generic/platform=iOS' \
            -derivedDataPath "$RUNNER_TEMP/DerivedData" \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGN_IDENTITY="" \
            clean build

      - name: Locate built app
        id: locate
        shell: bash
        run: |
          set -euo pipefail

          APP_PATH=$(find "$RUNNER_TEMP/DerivedData/Build/Products" \
            -maxdepth 2 \
            -type d \
            -name "*.app" \
            | head -n 1)

          if [ -z "$APP_PATH" ]; then
            echo "No .app bundle found" >&2
            exit 1
          fi

          echo "Found app: $APP_PATH"
          echo "app_path=$APP_PATH" >> "$GITHUB_OUTPUT"
          echo "app_name=$(basename "$APP_PATH" .app)" >> "$GITHUB_OUTPUT"

      - name: Package unsigned IPA
        id: package
        shell: bash
        run: |
          set -euo pipefail

          APP_PATH="${{ steps.locate.outputs.app_path }}"
          APP_NAME="${{ steps.locate.outputs.app_name }}"

          rm -rf "$RUNNER_TEMP/Payload"
          mkdir -p "$RUNNER_TEMP/Payload"
          cp -R "$APP_PATH" "$RUNNER_TEMP/Payload/"

          cd "$RUNNER_TEMP"
          /usr/bin/zip -qry \
            "${APP_NAME}-unsigned.ipa" \
            Payload

          echo "ipa_path=$RUNNER_TEMP/${APP_NAME}-unsigned.ipa" >> "$GITHUB_OUTPUT"

      - name: Upload unsigned IPA
        uses: actions/upload-artifact@v4
        with:
          name: ThreeOneOSFive-unsigned
          path: ${{ steps.package.outputs.ipa_path }}
          if-no-files-found: error
          retention-days: 7
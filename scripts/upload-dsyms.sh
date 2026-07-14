#!/bin/sh
# Upload dSYMs to Sentry for a release build, run LOCALLY (keeps the auth token
# out of CI). Do this after each App Store / TestFlight release so crash reports
# in Sentry are symbolicated.
#
# Where to get the dSYMs:
#   - Xcode Cloud: open the build > Artifacts > download the archive/dSYMs, OR
#   - Xcode Organizer: Window > Organizer > right-click the archive > Show in
#     Finder > right-click the .xcarchive > Show Package Contents > dSYMs, OR
#   - App Store Connect: your app > (build) > Download dSYM.
#
# Usage:
#   scripts/upload-dsyms.sh /path/to/TrimrPix.xcarchive
#   scripts/upload-dsyms.sh /path/to/dSYMs
#
# The auth token is read from $SENTRY_AUTH_TOKEN, or from the gitignored
# Sentry.xcconfig in the repo root. It is never printed and never committed.
set -e

ORG=iamjarl
PROJECT=trimrpix-ios

INPUT="$1"
if [ -z "$INPUT" ]; then
    echo "usage: $0 <path-to-.xcarchive-or-dSYMs-folder>"
    exit 1
fi

TOKEN="$SENTRY_AUTH_TOKEN"
if [ -z "$TOKEN" ] && [ -f "Sentry.xcconfig" ]; then
    TOKEN=$(grep -E '^[[:space:]]*SENTRY_AUTH_TOKEN' Sentry.xcconfig | head -1 | sed 's/.*=[[:space:]]*//')
fi
if [ -z "$TOKEN" ]; then
    echo "No token found. Set SENTRY_AUTH_TOKEN, or add it to Sentry.xcconfig."
    exit 1
fi

sentry-cli --auth-token "$TOKEN" debug-files upload \
    --org "$ORG" --project "$PROJECT" --include-sources "$INPUT"

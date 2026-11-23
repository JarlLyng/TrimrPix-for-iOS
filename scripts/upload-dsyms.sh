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
#
# Region: an org auth token carries its own Sentry URL, and sentry-cli follows
# that rather than a configured one. This project ingests in the EU region
# (ingest.de.sentry.io), and org tokens from this organisation have uploaded to
# the EU org with no SENTRY_URL set, so none is set here. If an upload fails, or
# it reports success but the symbols never show up, try this before anything else:
#
#   SENTRY_URL=https://de.sentry.io scripts/upload-dsyms.sh <path>
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
    # Strip up to the FIRST '=' only. '.*=' is greedy and would strip to the last
    # one, and an org auth token contains '=' characters, so it would be truncated
    # into something that fails with 401.
    TOKEN=$(grep -E '^[[:space:]]*SENTRY_AUTH_TOKEN' Sentry.xcconfig | head -1 | sed 's/^[^=]*=[[:space:]]*//')
fi
if [ -z "$TOKEN" ]; then
    echo "No token found. Set SENTRY_AUTH_TOKEN, or add it to Sentry.xcconfig."
    exit 1
fi

# Passed through the environment, which sentry-cli reads natively, rather than as
# --auth-token: an argument is visible in the process list to every other process
# on the machine for as long as the upload runs, an environment variable is not.
SENTRY_AUTH_TOKEN="$TOKEN" sentry-cli debug-files upload \
    --org "$ORG" --project "$PROJECT" --include-sources "$INPUT"

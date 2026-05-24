#!/usr/bin/env bash
set -euo pipefail

version="${1:?version is required}"

perl -0pi -e "s/version = '[^']+'/version = '${version}'/" build.gradle

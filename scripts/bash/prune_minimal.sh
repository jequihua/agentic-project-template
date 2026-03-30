#!/usr/bin/env bash
set -euo pipefail
rm -rf 06_infra 07_app 08_pkg 09_ops 90_legacy_review
echo "Kept core workspaces only."

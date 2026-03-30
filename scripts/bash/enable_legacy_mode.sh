#!/usr/bin/env bash
set -euo pipefail
mkdir -p 90_legacy_review
for f in repo_map.md reuse_candidate_log.md legacy_risks.md feature_scope.md migration_decision_log.md CONTEXT.md; do touch "90_legacy_review/$f"; done
echo "Legacy mode enabled."

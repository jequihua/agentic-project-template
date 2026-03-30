$files=@('repo_map.md','reuse_candidate_log.md','legacy_risks.md','feature_scope.md','migration_decision_log.md','CONTEXT.md')
New-Item -ItemType Directory -Force 90_legacy_review | Out-Null
foreach($f in $files){ New-Item -ItemType File -Force ("90_legacy_review/"+$f) | Out-Null }
Write-Host "Legacy mode enabled."

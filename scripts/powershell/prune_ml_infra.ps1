Remove-Item -Recurse -Force 07_app,08_pkg,09_ops,90_legacy_review -ErrorAction SilentlyContinue
Write-Host "Kept core + infra."

Remove-Item -Recurse -Force 06_infra,07_app,08_pkg,09_ops,90_legacy_review -ErrorAction SilentlyContinue
Write-Host "Kept core workspaces only."

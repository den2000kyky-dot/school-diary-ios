param(
    [Parameter(Mandatory = $true)]
    [string] $RepoUrl
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path ".git")) {
    git init
}

git add .
git commit -m "iOS app"
git branch -M main

$existing = git remote get-url origin 2>$null
if ($existing) {
    git remote set-url origin $RepoUrl
} else {
    git remote add origin $RepoUrl
}

git push -u origin main
Write-Host "Готово. Открой репозиторий → вкладка Actions и дождись сборки Build iOS IPA."

param(
    [switch]$Global
)

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
Write-Host "Setting hooks path to .githooks in $repoRoot"

if ($Global) {
    git config --global core.hooksPath "$repoRoot/.githooks"
} else {
    git config --local core.hooksPath "$repoRoot/.githooks"
}

Write-Host "Hooks path set. Ensure the pre-commit is executable on Unix if needed."

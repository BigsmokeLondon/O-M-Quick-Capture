# =====================================================================
#  Link_To_GitHub.ps1  -  Quick Capture (O.M. Industries Inc)
#
#  WHAT THIS SCRIPT DOES
#  Turns this folder into a Git folder connected to the GitHub repo
#  O-M-Quick-Capture, WITHOUT changing or deleting any of your files.
#  After it runs you can use normal git commands here (git status,
#  git add, git commit, git push), or GitHub Desktop.
#
#  HOW TO RUN IT
#  Double-click Link_To_GitHub.bat (it just starts this script).
#  It is safe to run more than once.
# =====================================================================

$ErrorActionPreference = 'Stop'
$repoUrl = 'https://github.com/BigsmokeLondon/O-M-Quick-Capture.git'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path


# ---------------------------------------------------------------------
#  SECTION 1 - Is Git installed?
#
#  Git is the program that tracks changes and talks to GitHub. If it is
#  not on this PC we try to install it with winget (built into Windows
#  10/11). If that is not possible we stop and tell you where to get it.
# ---------------------------------------------------------------------
function Test-Git { return [bool](Get-Command git -ErrorAction SilentlyContinue) }

if (-not (Test-Git)) {
    Write-Host 'Git is not installed. Trying to install it with winget...'
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
        # Pick up the new install in this window without needing to reopen it
        $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
    }
    if (-not (Test-Git)) {
        throw 'Git is still not available. Install it from https://git-scm.com/download/win then run this again.'
    }
}


# ---------------------------------------------------------------------
#  SECTION 2 - Go to the project folder
#
#  Every git command below must run inside the Quick Capture folder.
# ---------------------------------------------------------------------
Set-Location -LiteralPath $dir


# ---------------------------------------------------------------------
#  SECTION 3 - Turn the folder into a git repository
#
#  "git init" creates a hidden .git folder where the history is kept.
#  We name the main branch "main" to match GitHub. If the folder is
#  already a git repository this step is skipped.
# ---------------------------------------------------------------------
if (-not (Test-Path (Join-Path $dir '.git'))) {
    git init -b main
}


# ---------------------------------------------------------------------
#  SECTION 4 - Connect it to the GitHub repo
#
#  "origin" is git's nickname for the GitHub copy. If origin already
#  exists we just make sure it points at the right address.
# ---------------------------------------------------------------------
$existing = git remote 2>$null
if ($existing -contains 'origin') {
    git remote set-url origin $repoUrl
} else {
    git remote add origin $repoUrl
}


# ---------------------------------------------------------------------
#  SECTION 5 - Download the GitHub history (your files are not touched)
#
#  "git fetch" only downloads. You may be asked to sign in to GitHub
#  the first time (a browser window opens).
# ---------------------------------------------------------------------
git fetch origin main


# ---------------------------------------------------------------------
#  SECTION 6 - Line your folder up with GitHub, keeping your files
#
#  "git reset" (mixed mode) tells git "the project history is what is on
#  GitHub" but leaves every file in this folder exactly as it is. Any
#  difference between your files and GitHub then shows up as a normal
#  change you can review and commit. Nothing is overwritten or deleted.
# ---------------------------------------------------------------------
git reset origin/main
git branch --set-upstream-to=origin/main main


# ---------------------------------------------------------------------
#  SECTION 7 - Show the result
#
#  "git status" lists any files that differ from GitHub. A clean result
#  means the folder and GitHub already match.
# ---------------------------------------------------------------------
Write-Host ''
Write-Host 'Done. This folder is now linked to:' $repoUrl
Write-Host ''
git status

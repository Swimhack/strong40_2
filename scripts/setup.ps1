param(
  [Parameter(Mandatory=$false)][string]$RepoName,
  [Parameter(Mandatory=$false)][bool]$Private
)

$ErrorActionPreference = 'Stop'

if (-not $RepoName -or $RepoName.Trim().Length -eq 0) { $RepoName = 'strong40' }
$privateBool = $true
if ($PSBoundParameters.ContainsKey('Private')) { $privateBool = [bool]$Private }

Write-Host "Creating assets folder structure..."
New-Item -ItemType Directory -Force -Path "$PSScriptRoot/../assets/images" | Out-Null

function Download-Image {
  param(
    [string]$Url,
    [string]$OutPath
  )
  Invoke-WebRequest -Uri $Url -OutFile $OutPath -UseBasicParsing
}

Write-Host "Downloading reference images..."
Download-Image "https://picsum.photos/id/416/1200/800" "$PSScriptRoot/../assets/images/hero-416-1200x800.jpg"
Download-Image "https://picsum.photos/id/416/1200/630" "$PSScriptRoot/../assets/images/og-416-1200x630.jpg"
Download-Image "https://picsum.photos/id/1019/600/400" "$PSScriptRoot/../assets/images/joint-1019-600x400.jpg"
Download-Image "https://picsum.photos/id/1020/600/400" "$PSScriptRoot/../assets/images/progressive-1020-600x400.jpg"
Download-Image "https://picsum.photos/id/1014/600/400" "$PSScriptRoot/../assets/images/busy-dad-1014-600x400.jpg"
Download-Image "https://picsum.photos/id/1025/600/400" "$PSScriptRoot/../assets/images/recovery-1025-600x400.jpg"

Write-Host "Initializing git..."
Set-Location "$PSScriptRoot/.."
if (-not (Test-Path ".git")) {
  cmd /c "git init . >nul 2>&1"
}

cmd /c "git checkout -B main >nul 2>&1"
cmd /c "git add -A >nul 2>&1"
cmd /c "git commit -m \"chore: initial Strong40 SPA with assets and docs\" >nul 2>&1"

Write-Host "Reading GitHub token from credentials.md..."
$credPath = Join-Path (Get-Location) 'credentials.md'
if (-not (Test-Path $credPath)) { throw "credentials.md not found" }
$token = (Get-Content $credPath) -join "`n" |
  Select-String -Pattern "github_pat_[A-Za-z0-9_]+|ghp_[A-Za-z0-9]+" -AllMatches |
  ForEach-Object { $_.Matches.Value } |
  Select-Object -First 1
if (-not $token) { throw "GitHub token not found in credentials.md" }

Write-Host "Creating GitHub repo via API..."
$headers = @{ Authorization = "token $token"; 'User-Agent' = 'strong40-setup' }
$body = @{ name = $RepoName; private = $privateBool; auto_init = $false; description = "Strong40 - Daily Strength Tips for Men Over 40" } | ConvertTo-Json

$headers['Accept'] = 'application/vnd.github+json'
$response = Invoke-RestMethod -Method Post -Uri "https://api.github.com/user/repos" -Headers $headers -Body $body -ContentType 'application/json'
$remote = $response.clone_url
if (-not $remote) { throw "Failed to create repo. Response: $($response | ConvertTo-Json -Depth 5)" }

# Ensure git user is configured locally
if (-not (git config user.name)) { git config user.name "Strong40 Bot" | Out-Null }
if (-not (git config user.email)) { git config user.email "devnull+strong40@example.com" | Out-Null }

Write-Host "Setting remote and pushing..."
cmd /c "git remote remove origin >nul 2>&1"

$fullName = $response.full_name # e.g., owner/repo
$remoteAuth = "https://$token@github.com/$fullName.git"
cmd /c "git remote add origin $remoteAuth >nul 2>&1"
cmd /c "git push -u origin main >nul 2>&1"

# Reset remote to tokenless https URL
cmd /c "git remote set-url origin $remote >nul 2>&1"

Write-Host "Done. Repo: $remote"



$ErrorActionPreference = 'Stop'

function Get-NetlifyTokenFromCredentials {
	param([string]$CredentialsPath)
	if (-not (Test-Path $CredentialsPath)) { throw "credentials.md not found at $CredentialsPath" }
	$content = Get-Content $CredentialsPath -Raw
	$m = [regex]::Match($content, 'nfp_[A-Za-z0-9]+')
	if (-not $m.Success) { throw 'Netlify API token not found in credentials.md' }
	return $m.Value
}

function New-DeployZip {
	param([string]$Root, [string]$ZipPath)
	if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
	$excludeDirs = @('.git', 'scripts')
	$excludeFiles = @('credentials.md', '.gitignore', 'README.md', '.netlify-site.json', '.live-url.txt', 'deploy.zip')
	$files = Get-ChildItem -Path $Root -Recurse -File | Where-Object {
		$rel = $_.FullName.Substring($Root.Length + 1)
		$top = ($rel -split "\\|") | Select-Object -First 1
		-Not ($excludeDirs -contains $top) -and -Not ($excludeFiles -contains $rel)
	}
	if ($files.Count -eq 0) { throw 'No files to deploy.' }
	Compress-Archive -Path $files.FullName -DestinationPath $ZipPath -Force | Out-Null
}

function Ensure-NetlifySite {
	param([string]$Token, [string]$CachePath)
	$headers = @{ Authorization = "Bearer $Token"; Accept = 'application/json'; 'User-Agent' = 'strong40-deployer' }
	if (Test-Path $CachePath) {
		try { return (Get-Content $CachePath -Raw | ConvertFrom-Json) } catch { Remove-Item $CachePath -Force }
	}
	# Try desired name first
	$siteBody = @{ name = 'strong40' } | ConvertTo-Json
	try {
		$resp = Invoke-RestMethod -Method Post -Uri 'https://api.netlify.com/api/v1/sites' -Headers $headers -Body $siteBody -ContentType 'application/json'
	} catch {
		# Fallback to auto-generated name with empty JSON
		$resp = Invoke-RestMethod -Method Post -Uri 'https://api.netlify.com/api/v1/sites' -Headers $headers -Body '{}' -ContentType 'application/json'
	}
	$resp | ConvertTo-Json -Depth 10 | Set-Content -Path $CachePath
	return $resp
}

function Rename-NetlifySite {
	param([string]$Token, [string]$SiteId, [string]$NewName)
	$headers = @{ Authorization = "Bearer $Token"; Accept = 'application/json'; 'User-Agent' = 'strong40-deployer' }
	$body = @{ name = $NewName } | ConvertTo-Json
	$uri = "https://api.netlify.com/api/v1/sites/$SiteId"
	return Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $body -ContentType 'application/json'
}

function Deploy-ZipToNetlify {
	param([string]$Token, [string]$SiteId, [string]$ZipPath)
	$headers = @{ Authorization = "Bearer $Token"; Accept = 'application/json'; 'User-Agent' = 'strong40-deployer'; 'Content-Type' = 'application/zip' }
	$uri = "https://api.netlify.com/api/v1/sites/$SiteId/deploys"
	$resp = Invoke-WebRequest -Method Post -Uri $uri -Headers $headers -InFile $ZipPath
	return ($resp.Content | ConvertFrom-Json)
}

function Wait-DeployReady {
	param([string]$Token, [string]$DeployId, [int]$TimeoutSec = 120)
	$headers = @{ Authorization = "Bearer $Token"; Accept = 'application/json'; 'User-Agent' = 'strong40-deployer' }
	$start = Get-Date
	while ($true) {
		$resp = Invoke-RestMethod -Method Get -Uri "https://api.netlify.com/api/v1/deploys/$DeployId" -Headers $headers
		if ($resp.state -eq 'ready') { return $resp }
		if (((Get-Date) - $start).TotalSeconds -ge $TimeoutSec) { throw "Deploy not ready after $TimeoutSec seconds. Current state: $($resp.state)" }
		Start-Sleep -Seconds 3
	}
}

$root = (Resolve-Path "$PSScriptRoot\..\").Path.TrimEnd('\\')
$token = Get-NetlifyTokenFromCredentials (Join-Path $root 'credentials.md')
$cache = Join-Path $root '.netlify-site.json'
$zip = Join-Path $root 'deploy.zip'

Write-Host 'Creating deploy archive...'
New-DeployZip -Root $root -ZipPath $zip

Write-Host 'Ensuring Netlify site exists...'
$site = Ensure-NetlifySite -Token $token -CachePath $cache

# Try to rename to requested custom subdomain
$desiredName = 'strong-40'
try {
	$site = Rename-NetlifySite -Token $token -SiteId $site.id -NewName $desiredName
	$site | ConvertTo-Json -Depth 10 | Set-Content -Path $cache
	Write-Host ("Renamed site to: {0}" -f $site.name)
} catch {
	Write-Host "Rename to '$desiredName' failed; continuing with current name..."
}

Write-Host ("Site: {0} ({1})" -f $site.name, $site.id)

Write-Host 'Deploying to Netlify...'
$deploy = Deploy-ZipToNetlify -Token $token -SiteId $site.id -ZipPath $zip
Write-Host ("Deploy created: {0} (state: {1})" -f $deploy.id, $deploy.state)

Write-Host 'Waiting for deploy to be ready...'
$ready = Wait-DeployReady -Token $token -DeployId $deploy.id -TimeoutSec 180

$liveUrl = if ($site.ssl_url) { $site.ssl_url } elseif ($site.url) { $site.url } else { $ready.ssl_url }
Write-Host ("Live URL: {0}" -f $liveUrl)

"$liveUrl" | Set-Content -Path (Join-Path $root '.live-url.txt')
Remove-Item $zip -Force -ErrorAction SilentlyContinue



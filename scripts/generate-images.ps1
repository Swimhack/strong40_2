$ErrorActionPreference = 'Stop'

function Get-OpenAIKeyFromCredentials {
  param([string]$CredentialsPath)
  if (-not (Test-Path $CredentialsPath)) { throw "credentials.md not found at $CredentialsPath" }
  $content = Get-Content $CredentialsPath -Raw
  # Look for typical OpenAI key formats. Adjust pattern as needed.
  $m = [regex]::Match($content, 'sk-[A-Za-z0-9_\-]{20,}')
  if (-not $m.Success) { throw 'OpenAI API key not found in credentials.md' }
  return $m.Value
}

function New-OpenAIImage {
  param(
    [Parameter(Mandatory=$true)][string]$ApiKey,
    [Parameter(Mandatory=$true)][string]$Prompt,
    [Parameter()][string]$Size = '1024x1024',
    [Parameter(Mandatory=$true)][string]$OutPath
  )
  $headers = @{ Authorization = "Bearer $ApiKey"; 'Content-Type' = 'application/json'; Accept = 'application/json' }
  $payload = @{ model = 'gpt-image-1'; prompt = $Prompt; size = $Size; n = 1 } | ConvertTo-Json -Depth 5
  $resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/images/generations' -Headers $headers -Body $payload
  if (-not $resp.data -or -not $resp.data[0].url) { throw "Image generation failed: $($resp | ConvertTo-Json -Depth 5)" }
  $url = $resp.data[0].url
  $dir = Split-Path -Parent $OutPath
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  Invoke-WebRequest -Uri $url -OutFile $OutPath -UseBasicParsing
}

$root = Resolve-Path "$PSScriptRoot/.."
$assets = Join-Path $root 'assets/images/generated'
New-Item -ItemType Directory -Force -Path $assets | Out-Null

$openaiKey = Get-OpenAIKeyFromCredentials (Join-Path $root 'credentials.md')

Write-Host 'Generating photorealistic images for Strong40...'

# Hero 1536x1024 (diverse, touch of grey)
New-OpenAIImage -ApiKey $openaiKey -Prompt "Photorealistic, editorial-quality fitness photograph featuring a fit man in his early-to-mid 40s with a subtle touch of grey hair. Ethnically diverse look (could be Black, White, Latino, or Asian). Performing a joint-friendly strength movement (goblet squat or kettlebell deadlift) with excellent form. Natural lighting, clean modern gym backdrop, confident expression. Subtle upward-trending progress motif. Brand vibe: Strong40, professional and inspiring." -Size '1536x1024' -OutPath (Join-Path $assets 'hero-strong40-1536x1024.png')

# Open Graph 1536x1024 (space for title, diverse)
New-OpenAIImage -ApiKey $openaiKey -Prompt "Photorealistic header-style image of a fit man in his 40s with a touch of grey, ethnically diverse representation. Dumbbell training, clean composition with negative space on right for title. Blue brand accents reminiscent of Strong40. Professional, inspiring, progressive, minimal background clutter." -Size '1536x1024' -OutPath (Join-Path $assets 'og-strong40-1536x1024.png')

# Joint-Friendly 1536x1024 (safe alignment)
New-OpenAIImage -ApiKey $openaiKey -Prompt "Photorealistic image of a 40+ man (diverse representation) demonstrating joint-friendly training: goblet squat with neutral spine and knees tracking properly. Subtle grey in hair, calm focused expression, soft natural lighting, clean background. Emphasis on safe alignment." -Size '1536x1024' -OutPath (Join-Path $assets 'joint-friendly-1536x1024.png')

# Progressive 1536x1024 (progress signal)
New-OpenAIImage -ApiKey $openaiKey -Prompt "Photorealistic image of a mature man in his 40s (diverse, touch of grey) following progressive overload: adding small plates to a barbell or increasing dumbbell weight. Confident, methodical. Clean gym background, clear progress signal, professional photo quality." -Size '1536x1024' -OutPath (Join-Path $assets 'progressive-1536x1024.png')

# Busy-Dad Friendly 1536x1024 (home, time-efficient)
New-OpenAIImage -ApiKey $openaiKey -Prompt "Photorealistic image of a 40-year-old dad (diverse, touch of grey) doing a time-efficient home workout with adjustable dumbbells. Small timer/clock visible. Minimal, practical home setting. Energetic but realistic. Professional photo quality." -Size '1536x1024' -OutPath (Join-Path $assets 'busy-dad-1536x1024.png')

# Recovery Focused 1536x1024 (mobility)
New-OpenAIImage -ApiKey $openaiKey -Prompt "Photorealistic image of a 40+ man (diverse, touch of grey) focusing on recovery: foam rolling or hip/hamstring mobility on a mat. Relaxed mood, warm natural lighting, uncluttered background. Emphasis on controlled technique and recovery." -Size '1536x1024' -OutPath (Join-Path $assets 'recovery-1536x1024.png')

Write-Host "Done. Generated images in: $assets"



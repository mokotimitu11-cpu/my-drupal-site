param(
    [string]$WorkspaceId = '3001a537-cc1c-47ed-866b-98c53a13ceee',
    [string]$CollectionPath = (Join-Path $PSScriptRoot 'carsforsale-regression.postman_collection.json')
)

$ErrorActionPreference = 'Stop'

$apiKey = if ($env:POSTMAN_API_KEY) { $env:POSTMAN_API_KEY } else { [Environment]::GetEnvironmentVariable('POSTMAN_API_KEY', 'User') }
if (-not $apiKey) {
    throw 'Set POSTMAN_API_KEY (Postman > Settings > API keys) before running this script.'
}

$collection = Get-Content -Path $CollectionPath -Raw -Encoding UTF8
$body = [Text.Encoding]::UTF8.GetBytes("{`"collection`": $collection}")

$response = Invoke-RestMethod -Method Post -Uri "https://api.getpostman.com/collections?workspace=$WorkspaceId" `
    -Headers @{ 'X-Api-Key' = $apiKey } -ContentType 'application/json; charset=utf-8' -Body $body

Write-Host "Created collection '$($response.collection.name)' (uid $($response.collection.uid)) in workspace $WorkspaceId"

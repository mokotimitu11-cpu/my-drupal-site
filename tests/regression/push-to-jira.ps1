param(
    [string]$BaseUrl = 'https://mokotimitu11.atlassian.net',
    [string]$ProjectKey = 'SCRUM',
    [string]$CsvPath = (Join-Path $PSScriptRoot 'carsforsale-homepage-regression.csv')
)

$ErrorActionPreference = 'Stop'

if (-not $env:JIRA_EMAIL -or -not $env:JIRA_API_TOKEN) {
    throw 'Set $env:JIRA_EMAIL and $env:JIRA_API_TOKEN before running this script.'
}

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:JIRA_EMAIL):$($env:JIRA_API_TOKEN)"))
$headers = @{ Authorization = "Basic $auth"; Accept = 'application/json' }

function New-JiraIssue($fields) {
    $body = [Text.Encoding]::UTF8.GetBytes((@{ fields = $fields } | ConvertTo-Json -Depth 5))
    Invoke-RestMethod -Method Post -Uri "$BaseUrl/rest/api/2/issue" -Headers $headers `
        -ContentType 'application/json; charset=utf-8' -Body $body
}

foreach ($row in Import-Csv -Path $CsvPath) {
    $fields = @{
        project     = @{ key = $ProjectKey }
        issuetype   = @{ name = $row.'Issue Type' }
        summary     = $row.Summary
        description = $row.Description
        labels      = @($row.Labels -split '\s+' | Where-Object { $_ })
        priority    = @{ name = $row.Priority }
    }

    try {
        $issue = New-JiraIssue $fields
    }
    catch {
        # Team-managed projects often hide the Priority field from the create screen.
        $details = $_.ErrorDetails.Message
        if ($details -notmatch 'priority') { throw "Failed to create '$($row.Summary)': $details" }
        $fields.Remove('priority')
        $fields.description = "Priority: $($row.Priority)`n`n$($row.Description)"
        $issue = New-JiraIssue $fields
    }

    Write-Host "Created $($issue.key): $($row.Summary)  ->  $BaseUrl/browse/$($issue.key)"
}

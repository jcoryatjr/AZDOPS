function Set-ADOPSPipelineSettings {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Organization,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Project,

        [Parameter(Mandatory)]
        $Values
    )

    # If user didn't specify org, get it from saved context
    if ([string]::IsNullOrEmpty($Organization)) {
        $Organization = GetADOPSDefaultOrganization
    }

    $Uri = "https://dev.azure.com/$Organization/$Project/_apis/build/generalsettings?$script:apiVersion"

    $Body =  $Values | ConvertTo-Json -Compress
    $Settings = InvokeADOPSRestMethod -Uri $Uri -Method 'PATCH' -Body $Body

    Write-Output $Settings
}
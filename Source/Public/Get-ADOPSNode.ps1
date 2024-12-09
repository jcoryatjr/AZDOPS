function Get-ADOPSNode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int32]$PoolId,

        [Parameter()]
        [string]$Organization
    )

    # If user didn't specify org, get it from saved context
    if ([string]::IsNullOrEmpty($Organization)) {
        $Organization = GetADOPSDefaultOrganization
    }

    $Uri = "https://dev.azure.com/$Organization/_apis/distributedtask/elasticpools/$PoolId/nodes?$script:apiVersion"

    $Method = 'GET'
    $NodeInfo = InvokeADOPSRestMethod -Uri $Uri -Method $Method

    if ($NodeInfo.psobject.properties.name -contains 'value') {
        Write-Output $NodeInfo.value
    } else {
        Write-Output $NodeInfo
    }
}
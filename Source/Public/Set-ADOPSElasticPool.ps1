function Set-ADOPSElasticPool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int]$PoolId,

        [Parameter(Mandatory)]
        $ElasticPoolObject,

        [Parameter()]
        [string]$Organization
    )

    # If user didn't specify org, get it from saved context
    if ([string]::IsNullOrEmpty($Organization)) {
        $Organization = GetADOPSDefaultOrganization
    }

    $Uri = "https://dev.azure.com/$Organization/_apis/distributedtask/elasticpools/$PoolId`?$script:apiVersion"

    if ($ElasticPoolObject.GetType().Name -eq 'String') {
        $Body = $ElasticPoolObject
    }
    else {
        try {
            $Body = $ElasticPoolObject | ConvertTo-Json -Depth 100
        }
        catch {
            throw 'Unable to convert the content of the ElasticPoolObject to json.'
        }
    }

    $Method = 'PATCH'
    $ElasticPoolInfo = InvokeADOPSRestMethod -Uri $Uri -Method $Method -Body $Body
    Write-Output $ElasticPoolInfo
}
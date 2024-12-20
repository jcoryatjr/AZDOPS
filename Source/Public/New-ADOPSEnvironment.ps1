function New-ADOPSEnvironment {
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Organization,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Project,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [string]$Description,

        [Parameter()]
        [string]$AdminGroup,

        [Parameter()]
        [switch]$SkipAdmin
    )

    # If user didn't specify org, get it from saved context
    if ([string]::IsNullOrEmpty($Organization)) {
        $Organization = GetADOPSDefaultOrganization
    }

    $Uri = "https://dev.azure.com/$organization/$project/_apis/distributedtask/environments?$script:apiVersion"

    $Body = [Ordered]@{
        name = $Name
        description = $Description
    } | ConvertTo-Json -Compress

    $InvokeSplat = @{
        Uri = $Uri
        Method = 'Post'
        Body = $Body
    }

    Write-Verbose "Setting up environment"
    $Environment = InvokeADOPSRestMethod @InvokeSplat

    if ($PSBoundParameters.ContainsKey('SkipAdmin')) {
        Write-Verbose 'Skipped admin group'
    }
    else {
        $secUri = "https://dev.azure.com/$organization/_apis/securityroles/scopes/distributedtask.environmentreferencerole/roleassignments/resources/$($Environment.project.id)_$($Environment.id)?$script:apiVersion"

        if ([string]::IsNullOrEmpty($AdminGroup)) {
            $AdmGroupPN = "[$project]\Project Administrators"
        }
        else {
            $AdmGroupPN = $AdminGroup
        }
        $ProjAdm = (Get-ADOPSGroup | Where-Object {$_.principalName -eq $AdmGroupPN}).originId

        $SecInvokeSplat = @{
            Uri = $secUri
            Method = 'Put'
            Body = "[{`"userId`":`"$ProjAdm`",`"roleName`":`"Administrator`"}]"
        }

        try {
            $SecResult = InvokeADOPSRestMethod @SecInvokeSplat
        }
        catch {
            Write-Error 'Failed to update environment security. The environment may still have been created.'
        }
    }

    Write-Output $Environment
}
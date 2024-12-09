#requires -modules ADOPS

<#
.SYNOPSIS
    Gets a git branch from AzureDevOps (ADO)
.DESCRIPTION
    Used by Start-AdoWorkItem
.NOTES
    Exported from early version of ADOPS module which they dropped but we use.
#>
function Get-ADOPSGitBranch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Project,

        [Parameter(Mandatory)]
        [string]$RepositoryId,

        [Parameter()]
        [string]$Organization,

        [Parameter( Mandatory )]
        [string]$BranchName
    )

    # If user didn't specify org, get it from saved context
    if ([string]::IsNullOrEmpty($Organization)) {
        $Organization = GetADOPSDefaultOrganization
    }

    $Uri = "https://dev.azure.com/$Organization/$Project/_apis/git/repositories/$RepositoryId/refs`?filter=heads/$BranchName&$script:apiVersion"

    try {
        $result = InvokeADOPSRestMethod -Uri $Uri -Method Get
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        $ErrorMessage = $_.ErrorDetails.Message | ConvertFrom-Json
        if ($ErrorMessage.message -like 'TF401019:*') {
            Write-Verbose "The Git branch with name or identifier $BranchName in repository $Repository does not exist or you do not have permissions for the operation you are attempting."
            $result = $null
        }
        elseif ($ErrorMessage.message -like 'TF200016:*') {
            Write-Verbose "The following project does not exist: $Project. Verify that the name of the project is correct and that the project exists on the specified Azure DevOps Server."
            $result = $null
        }
        else {
            Throw $_
        }
    }

    if ($result.psobject.properties.name -contains 'value') {
        return $result.value
    }
    else {
        return $result
    }
}
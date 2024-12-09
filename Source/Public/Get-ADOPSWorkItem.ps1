#requires -modules ADOPS
<#
.SYNOPSIS
    Gets a work item from AzureDevOps (ADO)
.DESCRIPTION
    Used by Start-AdoWorkItem
.NOTES
    Exported from early version of ADOPS module which they dropped but we use.
#>
function Get-ADOPSWorkItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Project,

        [Parameter(Mandatory)]
        [string]$Organization,

        [Parameter( Mandatory )]
        [int]$WorkItemId,

        [Parameter()]
        [string]
        $Expand
    )

    $Uri = "https://dev.azure.com/$Organization/$Project/_apis/wit/workitems/$WorkItemId`?$script:apiVersion$( if ( $Expand ) { "&`$expand=$Expand" })"

    try {
        $result = Invoke-ADOPSRestMethod -Uri $Uri -Method Get
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        $ErrorMessage = $_.ErrorDetails.Message | ConvertFrom-Json
        if ($ErrorMessage.message -like 'TF401019:*') {
            Write-Verbose "The work item with the identifier $WorkItemId does not exist or you do not have permissions for the operation you are attempting."
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
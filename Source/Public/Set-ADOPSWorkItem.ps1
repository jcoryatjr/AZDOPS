#requires -modules ADOPS
<#
.SYNOPSIS
    Updates an AzureDevOps (ADO) work item (task)
.DESCRIPTION
    Used by Start-AdoWorkItem
.NOTES
    Exported from early version of ADOPS module which they dropped but we use.
#>
function Set-ADOPSWorkItem {
    [CmdletBinding()]
    param(
        [Parameter( Mandatory )]
        [string]$Project,

        [Parameter( Mandatory )]
        [string]$Organization,

        [Parameter( Mandatory )]
        [int]$WorkItemId,

        [Parameter( Mandatory )]
        [hashtable[]]$Value
    )

    if (-not $Value.Count -or ($Value | Where-Object {$_.Count -lt 3 -or $_.Count -gt 4})) {
        # Must have one or more values specified and each value must have at three or four values
        return
    }

    try {
        $workItem = Get-ADOPSWorkItem -Project $Project -Organization $Organization -WorkItemId $WorkItemId

        if ( -not $workItem ) {
            return
        }
    }
    catch {
        throw $_
    }

    [hashtable[]]$body = @(@{
        op    = 'test'
        path  = '/rev'
        value = $workItem.rev
    })

    $body += $Value

    $Uri = "https://dev.azure.com/$Organization/$Project/_apis/wit/workitems/$WorkItemId`?$script:apiVersion"

    try {
        $result = InvokeADOPSRestMethod -Uri $Uri -Method Patch -Body ($Value | ConvertTo-Json -Depth 5 -AsArray ) -ContentType 'application/json-patch+json'
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
function Test-ADOPSYamlFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Project,

        [Parameter(Mandatory)]
        [ValidateScript({
                $_ -match '.*\.y[aA]{0,1}ml$'
            }, ErrorMessage = 'Fileextension must be ".yaml" or ".yml"')]
        [string]$File,

        [Parameter(Mandatory)]
        [int]$PipelineId,

        [Parameter()]
        [string]$Organization
    )

    # If user didn't specify org, get it from saved context
    if ([string]::IsNullOrEmpty($Organization)) {
        $Organization = GetADOPSDefaultOrganization
    }

    $Uri = "https://dev.azure.com/$Organization/$Project/_apis/pipelines/$PipelineId/runs?$script:apiVersion"

    $FileData = Get-Content $File -Raw

    $Body = @{
        previewRun         = $true
        templateParameters = @{}
        resources          = @{}
        yamlOverride       = $FileData
    } | ConvertTo-Json -Depth 10 -Compress

    $InvokeSplat = @{
        Uri          = $URI
        Method       = 'Post'
        Body         = $Body
    }

    try {
        $Result = InvokeADOPSRestMethod @InvokeSplat
        Write-Output "$file validation success."
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        if ($_.ErrorDetails.Message) {
            $r = $_.ErrorDetails.Message | ConvertFrom-Json
            if ($r.typeName -like '*PipelineValidationException*') {
                Write-Warning "Validation failed:`n$($r.message)"
            }
            else {
                throw $_
            }
        }
    }
}

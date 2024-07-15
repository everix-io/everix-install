[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $version,
    [string] $moduleName = "Everix-Install",
    [switch] $dryRun,
    [switch] $force
)
try {    
    $isVerbose = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Verbose") -and $VerbosePreference -eq "Continue"
    

    Write-Host "Will publish module '$moduleName' version '$version' to the PowerShell Gallery." -ForegroundColor Green

    # install PowerShellGet if not present
    if (-not (Get-Module -Name PowerShellGet -ListAvailable)) {
        Write-Host "🔧 Installing PowerShellGet module..." -ForegroundColor Green
        Install-Module -Name PowerShellGet -Force
        Update-Module -Name PowerShellGet
    }

    # install PSScriptAnalyzer if not present
    if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
        Write-Host "🔧 Installing PSScriptAnalyzer module..." -ForegroundColor Green
        Install-Module -Name PSScriptAnalyzer -Force
    }

    Write-Host "🔑 Getting required secrects from Vault..." -ForegroundColor Green
    # Get secret from vault using `vault`
    $publishApiKeySecretPath = "kv/external_accounts/ps-gallery"
    $publishApiKeyName = "publishApiKey"

    $psGallerySecret = vault kv get -format=json $publishApiKeySecretPath | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get publish API key from vault: exit code $LASTEXITCODE."
    }

    $publishApiKey = $psGallerySecret.data?.data?.$publishApiKeyName

    if ($null -eq $publishApiKey) {
        throw "Failed to get publish API key from vault: '$publishApiKeyName' not found."
    }

    Write-Host "🚀 Publishing Everix-Install module to the PowerShell Gallery..." -ForegroundColor Gree

    $modulePath = Resolve-Path (Join-Path $PSScriptRoot $moduleName)
    $moduleManifestPath = Join-Path $modulePath "$moduleName.psd1"

    Write-Host "🔍 Testing module manifest '$moduleManifestPath'..."
    $manifestResult = Test-ModuleManifest -Path $moduleManifestPath    
    if ($null -eq $manifestResult) {
        throw "Failed to test module manifest '$moduleManifestPath'."
    }    

    if ($manifestResult.Version.ToString() -ne $version) {        
        throw "Version in module manifest '$moduleManifestPath' does not match the version to publish: '$version'."
    }
    
    Write-Host "🔍 Running PSScriptAnalyzer on the module..."
    $analysisResults = Invoke-ScriptAnalyzer -Path $modulePath -Recurse

    $hasErrors = $false
    if ($analysisResults.Count -gt 0) {        
        $analysisResults | ForEach-Object {
            if ($_.Severity -eq "Error") {
                Write-Host "⚠️ $($_.RuleName): $($_.Message) at $($_.Extent.File):$($_.Extent.StartLineNumber)"
                $hasErrors = $true
            }            
        }
        # Consider whether to halt the script based on the severity of issues found
        # throw "PSScriptAnalyzer identified blocking issues."
    }

    if ($hasErrors) {
        throw "PSScriptAnalyzer identified blocking issues."
    } else {
        Write-Host "✅ PSScriptAnalyzer found no blocking issues."
    }

    Write-Host "🚀 Publishing module '$moduleName' version '$version' to the PowerShell Gallery..." -ForegroundColor Green
    $result = Publish-Module -Path $modulePath -NuGetApiKey $publishApiKey -Verbose:$isVerbose -Force:$force -WhatIf:$dryRun -Repository PSGallery
    Write-Verbose "Publish-Module result: $result"

    Write-Host "✅ Module '$moduleName' version '$version' was published to the PowerShell Gallery." -ForegroundColor Green

    # Verify the module was published
    if (!$dryRun) {
        $publishedModule = Find-Module -Name $moduleName -RequiredVersion $version -Repository PSGallery
        if ($null -eq $publishedModule) {
            throw "Failed to find published module '$moduleName' in the PowerShell Gallery."
        }
    } else {
        Write-Host "What if: Module '$moduleName' version '$version' was published to the PowerShell Gallery."
    }
} catch {
    Write-Error "Failed to publish."
    Write-Error "$($_.Exception)"
    exit 1
}
function Use-EverixControl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Version,
        [string] $EverixControlLocation = "$HOME/everix-control",
        [ValidateSet("Process", "User", "Machine")]
        [string] $Scope = "User"
    )

    try {
    
        $EverixControlLocation = [IO.Path]::GetFullPath($EverixControlLocation)    
        $Versions = Get-EverixControlVersions -everixControlLocation $EverixControlLocation

        # check if version is in the list
        if ($Versions -contains $Version) {
            Write-Host "✅ Found everix-control version '$Version' in '$EverixControlLocation'." -ForegroundColor Green
        } else {
            Write-Error "everix-control version '$Version' not found in '$EverixControlLocation'."
            Write-Output "Available versions: $($Versions -join ', ')"
        
            exit 1
        }

        Write-Host "⌛ Setting everix-control version '$Version' in the environment for $Scope scope..."

        [Environment]::SetEnvironmentVariable("EVERIX_CONTROL_VERSION", $Version, $Scope)                
        $env:EVERIX_CONTROL_VERSION = $Version

        Write-Host "🚀 everix-control version '$Version' is now set in the environment: you can use 'Start-EverixControl' (alias 'everix-control')" -ForegroundColor Green
    } catch {
        Write-Error $_.Exception.Message
    }
}
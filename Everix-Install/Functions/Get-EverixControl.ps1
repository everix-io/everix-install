<#
.SYNOPSIS
 lists the versions of everix-control available in the specified location.
#>
function Get-EverixControl {
    param(
        [string] $EverixControlLocation = "$HOME/everix-control"
    )

    try {
        $EverixControlLocation = [IO.Path]::GetFullPath($EverixControlLocation)
        $Versions = Get-EverixControlVersions -everixControlLocation $EverixControlLocation

        $currentlyUsed = $env:EVERIX_CONTROL_VERSION

        foreach ($v in $Versions) {
            if ($v -eq $currentlyUsed) {
                Write-Output "  * $v (currently in use)"
            } else {
                Write-Output "    $v"
            }
        }        
    } catch {
        Write-Error $_.Exception.Message
    }
}
function Start-EverixControl {
    [CmdletBinding()]
    param ()

    # Import the dynamic parameters from the everix-control script of the selected version
    dynamicparam {
        $everixControlLocation = [IO.Path]::GetFullPath("$HOME/everix-control")
    
        if (-not (Test-Path $everixControlLocation)) {
            Write-Error "everix-control location not found at '$everixControlLocation': make sure you ran Install-EverixControl"
            exit 1
        }
        
        $version = $env:EVERIX_CONTROL_VERSION        
        if (!$version) {
            Write-Error "everix-control version not provided and not set in the environment."
            exit 1
        }

        $everixControlPath = Join-Path $everixControlLocation $version "everix-control.ps1"

        if (-not (Test-Path $everixControlPath)) {
            Write-Error "everix-control version '$version' not found in '$everixControlLocation'."
            exit 1
        }
        
        $everixControlCommand = Get-Command $everixControlPath

        if ($null -eq $everixControlCommand) {
            Write-Error "Failed to get command for everix-control script at '$everixControlPath'."
            exit 1
        }

        $everixControlCommand | Import-DynamicParamsFromCommand | New-DynamicParamsDict        
    }

    begin {
        try {                        
            $everixControlParams = Select-ParametersForCommand -Command $everixControlCommand -Parameters $PSBoundParameters
            
            Write-Verbose "Invoking '$everixControlPath' with parameters: $($everixControlParams | Format-List | Out-String)"
            & $everixControlCommand @everixControlParams
            
            
        } catch {
            Write-Error $_.Exception
            return
        }
    }

    end {
        & $everixControlPath @PSBoundParameters
    }
    
}
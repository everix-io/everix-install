# . { # example of how to access the common parameter $server
#     param(
#         [string] $server
#     )

#     Execute-Workflow {
#         Write-Host "Aggregation File: $aggregationFile"
#         Write-Host "Server: $server"
#         Aggregate -AggregationFile $aggregationFile
#     }

# } @PSBoundParameters

function AddParam {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        $type,
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $name
        # [System.Attribute[]] $attributes
    )

    throw "Should only be called from DefineDynamicParams"
}

function New-DynamicParamsDict {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('param')]
        [System.Management.Automation.RuntimeDefinedParameter[]] $params
    )

    begin {
        $paramsDict = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    }

    process {
        $params | Add-DynamicParam -paramsDict $paramsDict
    }

    end {
        return $paramsDict
    }
}

function Invoke-WithBoundParams {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $commandName,
        [Parameter(Mandatory = $true)]
        $BoundParameters
    )

    dynamicparam {
        $command = Get-Command -Name $commandName

        if (!$command) {
            throw "Command not found: $commandName"
        }

        $command | Import-DynamicParamsFromCommand | New-DynamicParamsDict
    }

    process {
        $command = Get-Command -Name $commandName

        # execute command with only the bound parameters corresponding to the dynamic parameters (filtered)
        $commandParams = $command.Parameters.Values
        $filteredBoundParams = @{}

        foreach ($param in $commandParams) {
            if ($BoundParameters.ContainsKey($param.Name)) {
                $filteredBoundParams[$param.Name] = $BoundParameters[$param.Name]
            }

            if ($PsBoundParameters.ContainsKey($param.Name)) {
                $filteredBoundParams[$param.Name] = $PsBoundParameters[$param.Name]
            }
        }

        Write-Host $filteredBoundParams

        & $commandName @filteredBoundParams
    }
}


function Import-DynamicParameters {
    return {
        foreach ($currentScriptParamName in $PSCmdlet.MyInvocation.MyCommand.Parameters.Keys) {
            $currentScriptParam = $PSCmdlet.MyInvocation.MyCommand.Parameters[$currentScriptParamName]
            if (!$currentScriptParam.IsDynamic) {
                continue
            }

            if ($PSBoundParameters.ContainsKey($currentScriptParamName)) {
                $currentScriptParamValue = $PSBoundParameters[$currentScriptParamName]
                Set-Variable -Name $currentScriptParamName -Value $currentScriptParamValue
            }

            # $currentScriptParam.Attributes | ConvertTo-Json -Depth 2 | Out-String

            # otherwise set default
            if ($currentScriptParam.DefaultValue) {
                Write-Host "Default: "
                $defaultValue = $currentScriptParam.Attributes.DefaultValue

                if ($null -eq $defaultValue) {
                    continue
                }

                $defaultValue | Out-String
                Set-Variable -Name $currentScriptParamName -Value $defaultValue
            }
        }
    }.ToString()
}


function Select-ParametersForCommand {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $command,

        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [hashtable] $BoundParameters
    )

    process {
        $commandInfo = Get-Command -Name $command

        if (!$command) {
            throw "Command not found: $command"

        }

        $commandParams = $commandInfo.Parameters.Values
        $filteredBoundParams = @{}



        foreach ($param in $commandParams) {
            if ($BoundParameters.ContainsKey($param.Name)) {
                $filteredBoundParams[$param.Name] = $BoundParameters[$param.Name]
            }

            if ($PsBoundParameters.ContainsKey($param.Name)) {
                $filteredBoundParams[$param.Name] = $PsBoundParameters[$param.Name]
            }
        }

        return $filteredBoundParams
    }
}

function WithDefaults-For {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Command,

        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [hashtable] $BoundParameters
    )

    dynamicparam {
        $commandInfo = Get-Command -Name $command

        if (!$commandInfo) {
            throw "Command not found: $command"
        }
        $dict = $commandInfo | Import-DynamicParamsFromCommand -MakeNonMandatory | New-DynamicParamsDict

        return $dict
    }

    begin {
        $defaultCommandParams = $PSBoundParameters | Where-Object { $_.Key -ne "Command" -and $_.Key -ne "BoundParameters" }
        $boundCommandParams = $BoundParameters | Select-ParametersForCommand $Command

        Write-Host "Bound"
        ConvertTo-Json $boundCommandParams

        $params = $defaultCommandParams | Override-HashtableWith $boundCommandParams

        return $params
    }
}

function Execute-Workflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [scriptblock] $block,
        [string] $server = "dev",
        [string] $epicId,
        [Parameter(Mandatory = $true)]
        [string] $asOfDate,

        [string] $scenario,
        [string] $operationType = "UNSET_OPERATION_TYPE", # e.g. "PRICE:RESULT", "PNL:RESULT", "ETL:BOOTSTRAP" etc.
        [string] $operationDisplayName, # e.g. "Price", "PNL", "ETL" etc.

        [string] $triggeredBy = "System",
        [switch] $dontMonitor,
        [switch] $dryRun,
        [switch] $noPause
    )

    $isVerbose = $PSBoundParameters['Verbose'] -eq $true

    Import-Module ([IO.Path]::Combine($PSScriptRoot, "../../../scripts/flo/run", "utils.psm1")) -Force -Global -DisableNameChecking -Verbose:$false
    Import-Module ([IO.Path]::Combine($PSScriptRoot, "../../../scripts/flo/run", "base-templates.psm1")) -Force -Global -DisableNameChecking -Verbose:$false
    Import-Module ([IO.Path]::Combine($PSScriptRoot, "../../../scripts/flo/run", "xpl-commons.psm1")) -Force -Global -DisableNameChecking -Verbose:$false
    # Import-Module ([IO.Path]::Combine($PSScriptRoot, "../../../tags.psm1")) -Force -Global -DisableNameChecking -Verbose:$false


    # print all the parameters
    Write-Host "-------------------------------------"
    Write-Host "Executing workflow with parameters:"
    Write-Host "-------------------------------------"
    foreach ($key in ($PSBoundParameters.Keys | Where-Object { $_ -ne "block" })) {
        Write-Host "$($key): $($PSBoundParameters[$key])"
    }
    Write-Host "-------------------------------------"

    Start-Workflow

    # execute the definition block of the workflow
    # IMPORTANT: the variables from the calling function scope will not be available in the block automatically
    # you need to pass them explicitly in the script block:
    # Execute-Workflow { param($server, $epicId) Write-Host "My server is: $server" }

    # below we create a new script block to capture only epicId and server variables

    # Opposed to & $block, Invoke-Command -ScriptBlock $block will capture all the variables from the calling function scope
    Invoke-Command -NoNewScope -ScriptBlock $block

    # & {
    #     $closure = $block.GetNewClosure()
    #     & $closure
    # } @PSBoundParameters

    Write-Host "-------------------------------------"

    $wfFilePath = [System.IO.Path]::GetTempFileName() + ".json"

    $wfMetadata = @{
        DisplayName   = $operationDisplayName ?? $operationType
        Scenario      = $scenario ?? "$operationType @ $asOfDate"
        AsOfDate      = $asOfDate
        OperationType = $operationType
        TriggeredBy   = $triggeredBy
        EpicId        = $epicId
    }

    Save-Workflow $wfFilePath -Metadata $wfMetadata -Context $wfContext
    Run-Workflow $wfFilePath -DryRun:$dryRun -Server $server -Verbose:$isVerbose -DontMonitor:$dontMonitor
    Write-Host "===> EpicId: $epicId" -ForegroundColor Green

    if (-not $noPause) {
        Pause
    }
}


function Params-For {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $command
    )

    dynamicparam {
        (Get-Command $command) | Import-DynamicParamsFromCommand | New-DynamicParamsDict
    }

    process {
        return $PSBoundParameters
    }
}

function PartialParams-For {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $command
    )

    dynamicparam {
        (Get-Command $command) | Import-DynamicParamsFromCommand -MakeNonMandatory | New-DynamicParamsDict
    }

    process {
        return $PSBoundParameters | Select-ParametersForCommand $command
    }
}

function Override-HashtableWith {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable] $override,

        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [hashtable] $base
    )

    begin {
        $result = @{}
    }

    process {
        foreach ($key in $base.Keys) {
            $result[$key] = $base[$key]
        }

        foreach ($key in $override.Keys) {
            $result[$key] = $override[$key]
        }
    }

    end {
        return $result
    }
}

function Add-DynamicParam {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.RuntimeDefinedParameterDictionary] $paramsDict,

        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('param')]
        [System.Management.Automation.RuntimeDefinedParameter[]] $params
    )

    begin {
        # intentionally empty
    }

    process {
        foreach ($param in $params) {
            $paramsDict.Add($param.Name, $param)
        }
    }

    end {
    }
}

function New-DynamicParam {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        $type,
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $name,
        [Parameter(Position = 2)]
        $attributes,
        [switch] $Mandatory
    )

    if ($type.GetType() -eq [string]) {
        if ($type.StartsWith("[") -and $type.EndsWith("]")) {
            $type = $type.Substring(1, $type.Length - 2)
        }

        $actualType = Invoke-Expression "[$type]"
    } else {
        $actualType = $type
    }

    $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

    $hasParamAttr = $false
    if ($attributes) {
        foreach ($attr in $attributes) {
            if ($attr -is [System.Management.Automation.ParameterAttribute]) {
                $hasParamAttr = $true

                $paramAttr = [System.Management.Automation.ParameterAttribute]$attr

                $paramAttr.Mandatory = $Mandatory
                # $paramAttr.ValueFromPipeline = $false
                # $paramAttr.ValueFromPipelineByPropertyName = $false
            }

            if ($attr -is [System.Attribute]) {
                $attributeCollection.Add($attr)
            } else {
                throw "Invalid attribute: $attr"
            }

        }
    }

    if (!$hasParamAttr) {
        $paramAttr = New-Object System.Management.Automation.ParameterAttribute
        $paramAttr.Mandatory = $Mandatory
        $attributeCollection.Add($paramAttr)
    }


    # $ageAttribute.Position = 3
    # $ageAttribute.Mandatory = $true
    # $ageAttribute.HelpMessage = "This product is only available for customers 21 years of age and older. Please enter your age:"

    #create an attributecollection object for the attribute we just created.

    $runtimeDefinedParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($name, $actualType, $attributeCollection)
    return $runtimeDefinedParameter

}

function Import-DynamicParams {
    [CmdletBinding(DefaultParameterSetName = "Block")]
    param (
        [Parameter(ParameterSetName = "Block", Mandatory = $true)]
        [scriptblock] $block,

        [Parameter(ParameterSetName = "Command", Mandatory = $true)]
        [System.Management.Automation.CommandInfo] $command
    )

    begin {
        $params = @()
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            "Block" { $params = $params + @(Import-DynamicParamsFromBlock -block $block) }
            "Command" { $params = $params + @(Import-DynamicParamsFromCommand -command $command) }
            Default { throw "Invalid parameter set name: $($PSCmdlet.ParameterSetName)" }
        }
    }

    end {
        return $params
    }

}

function Import-DynamicParamsFromBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [scriptblock] $block
    )

    begin {
        $params = @()
    }

    process {
        $functionName = "FUNC_" + [System.Guid]::NewGuid().ToString().Replace("-", "")

        Invoke-Expression "function $functionName { $block }"

        $command = Get-Command $functionName

        $params = $params + @(Import-DynamicParamsFromCommand $command)
    }

    end {
        return $params
    }
}

$POWERSHELL_COMMON_PARAMS = @(
    "Verbose",
    "Debug",
    "ErrorAction",
    "WarningAction",
    "InformationAction",
    "ErrorVariable",
    "WarningVariable",
    "InformationVariable",
    "OutVariable",
    "OutBuffer",
    "PipelineVariable",
    "ProgressAction"
)

function Test-CommonPowerShellParameter {
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ParameterMetadata] $param
    )



    return $POWERSHELL_COMMON_PARAMS -contains $param.Name
}

function Import-DynamicParamsFromCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Management.Automation.CommandInfo] $command,
        [switch] $makeNonMandatory
    )

    begin {
        $params = @()
    }

    process {
        $commandParams = $command.Parameters

        foreach ($param in $commandParams.Values) {
            $paramName = $param.Name
            $paramType = $param.ParameterType

            if (Test-CommonPowerShellParameter $param) {
                continue
            }

            $mandatory = $param.Attributes `
            | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } `
            | ForEach-Object { $_.Mandatory }

            if ($makeNonMandatory) {
                $mandatory = $false
            }

            $params += New-DynamicParam $paramType $paramName $param.Attributes -Mandatory:$mandatory
        }
    }

    end {
        return $params
    }
}

function Import-DynamicParams {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $BoundParameters
    )

    $scriptBlockText = foreach ($key in $BoundParameters.Keys) {
        "Write-Host `$PSBoundParameters['$key']"
        "Set-Variable -Name `"$key`" -Value (`$PSBoundParameters['$key'])"
    }

    return [scriptblock]::Create($scriptBlockText -join "`n")
}

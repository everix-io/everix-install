# Dot source public/private functions
$dotSourceParams = @{
    Filter      = '*.ps1'
    Recurse     = $true
    ErrorAction = 'Stop'
}

$shared = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Shared') @dotSourceParams )
$functions = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Functions') @dotSourceParams )

foreach ($import in @($shared + $functions)) {
    try {
        . $import.FullName
    } catch {
        throw "Unable to dot source [$($import.FullName)]"
    }
}

New-Alias -Name Everix-Control -Value Start-EverixControl
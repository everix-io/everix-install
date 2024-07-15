function Get-EverixControlVersions {
    param (
        $everixControlLocation = "$HOME/everix-control"
    )

    $everixControlLocation = [IO.Path]::GetFullPath($everixControlLocation)

    if (-not (Test-Path $everixControlLocation)) {
        throw "everix-control location not found at '$everixControlLocation'"
    }

    $versions = Get-ChildItem -Path $everixControlLocation -Directory | Select-Object -ExpandProperty Name

    return $versions
}
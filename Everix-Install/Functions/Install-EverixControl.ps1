function Install-EverixControl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
    
        [string] $Version = "latest",
        [string] $Owner = "everix-io",
        [string] $Repo = "everix-install",
        [string] $InstallDir = "$HOME/everix-control",
        [string] $GithubToken
    )

    $apiUrlBase = "https://api.github.com/repos/$Owner/$Repo"

    $getReleasesUrl = "$apiUrlBase/releases"

    try {
        $InstallDir = [IO.Path]::GetFullPath($InstallDir)
        if (-not (Test-Path $InstallDir)) {
            Write-Host "⌛ Creating everix-control install directory '$InstallDir'..." -ForegroundColor Green
            New-Item -ItemType Directory -Path $InstallDir | Out-Null
        }

        $headers = @{}

        if ($GithubToken) {
            Write-Host "🔑 Will authenticate with GitHub using the provided token." -ForegroundColor Green
            $headers.Add("Authorization", "token $GithubToken")
        }

        Write-Host "⌛ Getting everix-control version '$Version' from GitHub..." -ForegroundColor Green

        # Determine the URL based on the version requested
        if ($Version -eq "latest" -or !$Version) {
            $getReleaseUrl = "$apiUrlBase/releases/latest"
        } else {
            $getReleaseUrl = "$apiUrlBase/releases/tags/$Version"
        }

        Write-Verbose "Requesting '$getReleaseUrl'..."
        $response = Invoke-RestMethod -Uri $getReleaseUrl -Method Get -StatusCodeVariable StatusCode
        Write-Verbose "Status code: $StatusCode"

        Write-Verbose "Response: $($response | ConvertTo-Json -Depth 5)"

        if ($StatusCode -eq 404) {
            throw "Failed to find everix-control version '$Version' in '$apiUrlBase': are you sure you entered an existing version?"
        }        
    
        if ($null -eq $response) {
            throw "Failed to get everix-control version '$Version' from '$apiUrlBase'."
        }

        $tag = $response.tag_name
        Write-Host "✅ Found everix-control release with tag '$tag':" -ForegroundColor Green
        Write-Host "   Release name: $($response.name)" -ForegroundColor DarkBlue
        Write-Host "   Published at: $($response.published_at)" -ForegroundColor DarkBlue
        Write-Host "   GitHub Link: $($response.html_url)" -ForegroundColor DarkBlue

        $assetsUrl = $response.assets_url

        Write-Verbose "Requesting '$assetsUrl'..."
        $assetsResponse = Invoke-RestMethod -Uri $assetsUrl -Method Get
        Write-Verbose "Response: $($assetsResponse | ConvertTo-Json -Depth 5)"

        if ($null -eq $assetsResponse) {
            throw "Failed to get everix-control assets from $assetsUrl."
        }       

        $everixControlZipAsset = $assetsResponse | Where-Object {
            $_.name -eq "everix-control.zip"
        }

        if ($null -eq $everixControlZipAsset) {
            throw "Failed to find 'everix-control.zip' asset in the release."
        }

        $everixControlZipAssetDownloadUrl = $everixControlZipAsset.browser_download_url

        Write-Host "❓ Do you want to download this version? [Y/N] " -ForegroundColor Yellow -NoNewline
        $answer = Read-Host

        if ($answer -ne "Y" -and $answer -ne "y") {
            Write-Host "🚫 Aborted by the user" -ForegroundColor Red
            exit 0
        }            
    
        $InstallDirWithVersion = "$InstallDir\$tag"
        # create output directory if doesn't exist
        if (Test-Path $InstallDirWithVersion) {
            Write-Host "⌛ Removing existing directory '$InstallDirWithVersion'..." -ForegroundColor Yellow
            Remove-Item -Recurse -Force $InstallDirWithVersion | Out-Null
            New-Item -ItemType Directory -Path $InstallDirWithVersion | Out-Null
        } else {
            New-Item -ItemType Directory -Path $InstallDirWithVersion | Out-Null
        }

        Write-Host "⬇️  Downloading everix-control version '$tag'..." -ForegroundColor Green

        $downloadPath = "$InstallDirWithVersion\everix-control.zip"
        Write-Verbose "Downloading '$everixControlZipAssetDownloadUrl' to '$downloadPath'..."
        Invoke-WebRequest -Uri $everixControlZipAssetDownloadUrl -OutFile $downloadPath
    
        Write-Host "📦 Uncompressing everix-control.zip..." -ForegroundColor Green
        Expand-Archive -Path $downloadPath -DestinationPath $InstallDirWithVersion -Force

        # check `everix-control.ps1` exists
        $everixControlScriptPath = "$InstallDirWithVersion\everix-control.ps1"
        if (-not (Test-Path $everixControlScriptPath)) {
            throw "Failed to find 'everix-control.ps1' in the unzipped release."
        }

        # remove zip file
        Remove-Item -Path $downloadPath

        Write-Host "✅ everix-control version '$tag' unzipped to '$InstallDirWithVersion'." -ForegroundColor Green
        Write-Host
        Write-Host "💡 To select this version type:"
        Write-Host "   Use-EverixControl -Version $tag" -ForegroundColor DarkCyan
         

    } catch {
        Write-Error "Failed to install everix-control version '$Version' from $apiUrlBase."
        Write-Error $_
    
        exit 1
    }
}
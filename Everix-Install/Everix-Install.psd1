@{
    RootModule        = 'Everix-Install.psm1'
    ModuleVersion     = '1.0.1'
    GUID              = 'a1af4558-82e6-4921-a0a4-faa53e6c3901'
    Author            = 'Everix'
    CompanyName       = 'Everix'
    Copyright         = 'Copyright (c) Everix. All rights reserved.'
    Description       = 'Everix-Install is a PowerShell module to install Everix.'
    PowerShellVersion = '5.0'
    FunctionsToExport = @(
        'Install-EverixControl',
        'Use-EverixControl',
        'Start-EverixControl',
        'Get-EverixControl'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @('everix-control')
    ModuleList        = @()    
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('Everix', 'Installation')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/everix-io/everix-install/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/everix-io/everix-install'

            # A URL to an icon representing this module.
            IconUri      = 'https://everix.io/wp-content/uploads/2021/03/cropped-Logo-Square-Only-1000_with-square-1-192x192.png'

            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of Everix-Install module.'
        } # End of PSData hashtable

        # Other private data fields
    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    HelpInfoURI       = 'https://github.com/everix-io/everix-install/blob/main/README.md'
}
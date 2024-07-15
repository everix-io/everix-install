# Everix-Install PowerShell module

Installation script for Everix on-premises installations. It functions similarly to the `nvm` tool for Node.js. It contains three functions:

- `Install-EverixControl` - Installs the Everix Control script of the latest or specified version.
- `Use-EverixControl` - Sets the Everix Control script to be used in the current session.
- `Get-EverixControl` - Gets all the installed script vesrions as well as the currently used one.
- `Start-EverixControl` - Starts the currently active Everix Control script.

## Installation

```powershell
Install-Module Everix -Source PSGallery
```

## Updating

```powershell
Update-Module Everix
```

## Usage

### Installing the `everix-control` script

To install the latest version of Everix Control:

```powershell
Install-EverixControl
```

To install a specific version of Everix Control:

```powershell
Install-EverixControl -Version 1.0.0
```

The command will download the script and place it in the `$HOME/everix-control` directory under the versioned subdirectory.

### Using the `everix-control` script

To use the specific version of Everix Control for the User scope:

```powershell
Use-EverixControl -Version 1.0.0
```

The version to use must be installed first using `Install-EverixControl`.

To use the version on the session (Process) level:

```powershell
Use-EverixControl -Version 1.0.0 -Scope Process
```

To use the version on the Machine level:

```powershell
Use-EverixControl -Version 1.0.0 -Scope Machine
```

### Starting the `everix-control` script

Then to perform Everix installation and control Everix cluster you can start the script:

```powershell
Start-EverixControl -DistribRootDir "/path/to/unzipped/everix/distribution"
```

Or use the alias:

```powershell
everix-control -DistribRootDir "/path/to/unzipped/everix/distribution"
```

All the parameters of `everix-control` script can be passed to `Start-EverixControl` function, and autocomplete will also be available when you type.

Repository for things related to Everix installation and control scripts.

# Everix-Install

See [Everix-Install/README.md](Everix-Install/README.md) for more information.

# Publishing

As a prerequisite you have to have access to Everix Vault set up on the machine.

To publish the module to the PowerShell Gallery, run the following command:

1. Update the version in the module manifest (`EverixInstall.psd1`).

2. Run the following command with the same version as in the module manifest:

```powershell
./Publish-EverixInstallModule.ps1 -Version 1.0.X
```

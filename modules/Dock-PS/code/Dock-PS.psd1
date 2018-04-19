#
# Module manifest for module 'Dock-PS'
#

@{

# Script module or binary module file associated with this manifest.
ModuleToProcess = '.\Dock-PS.psm1'

# Version number of this module.
ModuleVersion = '1.2'

# ID used to uniquely identify this module
GUID = '6f0e21d4-cd97-464b-aa6d-a53cc99c5614'

# Author of this module
Author = 'Gee Law'

# Company or vendor of this module
CompanyName = 'N/A'

# Copyright statement for this module
Copyright = '(c) 2017 by Gee Law, all rights reserved.'

# Description of the functionality provided by this module
Description = 'Dock PowerShell to a side of the screen.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the Windows PowerShell host required by this module
PowerShellHostName = 'ConsoleHost'

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
DotNetFrameworkVersion = '3.5'

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
ScriptsToProcess = @('.\Dock-PS.prepare.ps1')

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = @('Move-Host', 'Pop-Host', 'Resize-Host')

# Cmdlets to export from this module
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module
AliasesToExport = @('dock', 'undock', 'resize')

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('utility', 'utilities', 'dock', 'docking', 'snap', 'snapping', 'productivity', 'console', 'interactive')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/GeeLaw/PowerShellThingies/tree/master/modules/Dock-PS'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/GeeLaw/PowerShellThingies/tree/master/modules/Dock-PS'

        # A URL to an icon representing this module.
        IconUri = 'https://raw.githubusercontent.com/GeeLaw/PowerShellThingies/master/modules/Dock-PS/logo.png'

        # ReleaseNotes of this module
        ReleaseNotes = 'Migrate project to another repository. Fix logo.'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://github.com/GeeLaw/PowerShellThingies/tree/master/modules/Dock-PS'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

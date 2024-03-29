@{
    # Version number of this module.
    moduleVersion = '8.8.3.0'

    # ID used to uniquely identify this module
    GUID              = 'cc8dc021-fa5f-4f96-8ecf-dfd68a6d9d48'

    # Author of this module
    Author            = 'Microsoft Corporation'

    # Company or vendor of this module
    CompanyName       = 'Microsoft Corporation'

    # Copyright statement for this module
    Copyright         = '(c) Microsoft Corporation. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'The xPSDesiredStateConfiguration module is a part of the Windows PowerShell Desired State Configuration (DSC) Resource Kit, which is a collection of DSC Resources produced by the PowerShell Team. This module contains the xDscWebService, xWindowsProcess, xService, xPackage, xArchive, xRemoteFile, xPSEndpoint and xWindowsOptionalFeature resources. Please see the Details section for more information on the functionalities provided by these resources.

All of the resources in the DSC Resource Kit are provided AS IS, and are not supported through any Microsoft standard support program or service. The "x" in xPSDesiredStateConfiguration stands for experimental, which means that these resources will be fix forward and monitored by the module owner(s).'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '4.0'

    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion        = '4.0'

    # Functions to export from this module
    FunctionsToExport = '*'

    # Cmdlets to export from this module
    CmdletsToExport   = '*'

    # Root module
    RootModule        = 'DSCPullServerSetup\PublishModulesAndMofsToPullServer.psm1'

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/PowerShell/xPSDesiredStateConfiguration/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/PowerShell/xPSDesiredStateConfiguration'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
        ReleaseNotes = '- Ports fix for the following issue:
  [Issue 142](https://github.com/PowerShell/PSDscResources/issues/142)
  Fixes issue where MsiPackage Integration tests fail if the test HttpListener
  fails to start. Moves the test HttpListener objects to dynamically assigned,
  higher numbered ports to avoid conflicts with other services, and also checks
  to ensure that the ports are available before using them. Adds checks to
  ensure that no outstanding HTTP server jobs are running before attempting to
  setup a new one. Also adds additional instrumentation to make it easier to
  troubleshoot issues with the test HttpListener objects in the future.

'

        } # End of PSData hashtable
    } # End of PrivateData hashtable
}





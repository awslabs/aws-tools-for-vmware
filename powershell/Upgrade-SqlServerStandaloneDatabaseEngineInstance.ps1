# AWS Upgrade Utility for SQL Server
# Copyright 2019, Amazon Web Services, Inc. or its affiliates. All rights reserved.
# =======================================================================================

<#PSScriptInfo
    .VERSION 0.1.0

    .GUID 8f4b7f93-a23d-442a-b9a4-c8014bf5f927

    .AUTHOR Amazon Web Services, Inc.

    .COMPANYNAME Amazon Web Services, Inc.

    .COPYRIGHT Copyright 2019, Amazon Web Services, Inc. or its affiliates. All rights reserved.

    .TAGS AWS SqlServer SQL Server MSSQL upgrade compatibility VMware PowerCLI VM VirtualMachine PSEdition_Core PSEdition_Desktop Windows Linux Mac macOS

    .LICENSEURI https://github.com/awslabs/aws-tools-for-vmware/blob/master/LICENSE

    .PROJECTURI https://github.com/awslabs/aws-tools-for-vmware/blob/master/powershell/Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1

    .ICONURI

    .EXTERNALMODULEDEPENDENCIES 

    .REQUIREDSCRIPTS

    .EXTERNALSCRIPTDEPENDENCIES

    .RELEASENOTES
    ### 0.1.0
    First version published to PowerShellGallery.

    .PRIVATEDATA
#>

<#
    .SYNOPSIS
    Upgrade a standalone SQL Server Database Engine instance in-place.

    .DESCRIPTION
    ### What this tool does

    This will perform an *impactful*, in-place, major version upgrade, such as
    SQL Server 2008 SP4 -> 2017 or 2008 R2 SP3 -> 2016, on a standalone
    SQL Server Database Engine instance on a Windows operating system. It can
    be run either locally, or remotely if deployed on a Windows VM in a vSphere
    environment such as VMware Cloud on AWS. You must supply your own
    SQL Server installation media and product key / license.

    The compatibility level of each database deployed on the target SQL Server
    instance will not be modified by this script, and *should* remain the same,
    but please test thoroughly.

    Please see the links below for additional resources such as Microsoft's
    best practices for planning your SQL Server instance upgrades, breaking
    changes and backwards compatibility, et cetera.

    Again, the upgrade process is impactful, so please test thoroughly and plan
    for application downtime.

    ### What this tool does not do

    !!! danger "Backups are *NOT* included"
        Backups are *NOT* included. Please make sure that you have implemented
        and verified proper backups, and that you have a recovery plan
        established that meets the recovery plan objective (RPO) and recovery
        time objective (RTO).

    This tool does not accommodate the intricacies of upgrading any
    high availability (HA) SQL Server instance types including:

    - Replicated Databases
    - Mirrored Databases
    - Log Shipping Instances
    - Failover Cluster Instances (FCI)
    - AlwaysOn Availability Groups (AAG)

    This tool does not accommodate edition upgrades within the same version of
    SQL Server either.

    The checks run prior to the upgrade cannot test for every eventuality. In
    fact, most of the requirements and compatibility testing is delegated to
    Microsoft's SQL Server installation media since it was built with a robust
    testing framework. Please test thoroughly.

    ### Local upgrades
    For local upgrades, this script requires elevated privileges and must be
    run from PowerShell launched with the 'Run as Administrator' option.

    ### Remote upgrades
    For VMware PowerCLI-based remote upgrades, HTTPS (443/tcp) connectivity is
    required to the ESXi hosts as well as vCenter for executing commands in the
    VM's guest operating system via the VMware Guest Operations API. This
    connectivity is not permitted by default, such as in VMware Cloud on AWS,
    but can be configured.

    This tool does not attempt to install or import the required PowerCLI
    modules, nor does it attempt to establish a PowerCLI session with vCenter.
    For VMware PowerCLI installation instructions, please see:
    https://www.powershellgallery.com/packages/VMware.PowerCLI/. Once
    installed, run `Import-Module -Name 'VMware.VimAutomation.Core'` to import
    the subset of modules required. To learn more about how to establish a
    PowerCLI session, run `Get-Help -Name 'Connect-VIServer' -Detailed`, which
    includes a few examples.

    All target VMs must be powered on, and VMware Tools must be installed and
    running in the guest operating system of each Windows VM.

    The supplied credentials will be used on each VM to access the guest
    operating system, and must have administrative privileges. Because feature:
    https://powercli.ideas.aha.io/ideas/PCLI-I-101 has neither been accepted
    nor released by the PowerCLI team, Windows User Account Control (UAC) must
    be disabled in each guest operating system as well.

    Multiple VMs can be specified in the same command for batch upgrades via an
    array of VM IDs or names, as well as wildcard globbing of VM names;
    however, the SQL Server instance on each VM is upgraded iteratively, not
    concurrently. Please plan accordingly.

    .INPUTS
    System.String

    .NOTES
    ### Security
    To reduce the risk of unintended code execution, a file hash must be
    supplied for the setup file, which will be compared to a file hash of the
    specified setup file in an attempt to confirm file integrity and that the
    correct media has been loaded before launching the upgrade. Additionally,
    a few properties will be checked in an attempt to confirm that a
    SQL Server setup file has been specified.

    .EXAMPLE
    ./Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 -FilePath 'D:\setup.exe' -FileHash $sha256FileHash -IAcceptSqlServerLicenseTerms -WhatIf
    Performs a 'dry run test' of a local, in-place upgrade of the default
    SQL Server Database Engine instance (MSSQLSERVER) that would install in the
    default directory, and validates the integrity of the specified SQL Server
    setup file by comparing the SHA256 file hashes.

    Since a product key / license was not supplied, the instance would be
    upgraded into Evaluation mode unless upgraded to SQL Server Express
    edition.

    .EXAMPLE
    ./Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 -FilePath 'D:\setup.exe' -FileHash $sha256FileHash -IAcceptSqlServerLicenseTerms
    Implements the previous example.

    Since a product key / license was not supplied, the instance will be
    upgraded into Evaluation mode unless upgraded to SQL Server Express
    edition.

    .EXAMPLE
    ./Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 -FilePath 'E:\setup.exe' -FileHash $md5FileHash -Algorithm 'MD5' -InstanceName 'SQLEXPRESS' -InstanceDirectory 'D:\MSSQL' -ProductKey $productKey -IAcceptSqlServerLicenseTerms
    Performs a local, in-place upgrade of the SQLEXPRESS SQL Server Database
    Engine instance that will install in the specified directory, validates the
    integrity of the specified SQL Server setup file by comparing the MD5 file
    hashes, and applies the specified product key.

    .EXAMPLE
    ./Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 'E:\setup.exe' $md5FileHash 'MD5' 'SQLEXPRESS' 'D:\MSSQL' $productKey $true
    The same in-place upgrade as in the example above using positional
    arguments.

    .EXAMPLE
    ./Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 -FilePath 'O:\setup.exe' -FileHash $md5FileHash -Algorithm 'MD5' -IAcceptSqlServerLicenseTerms -Credential (Get-Credential) -VmName 'SQL1', 'MSSQL*'
    Performs a remote, PowerCLI-based in-place upgrade of the default
    SQL Server Database Engine instance (MSSQLSERVER) on the SQL1 VM, as well
    as any VM with a name starting 'MSSQL' (due to the '*' wildcard). It will
    install in the default directory, and validates the integrity of the
    specified SQL Server setup file by comparing the MD5 file hashes.

    .EXAMPLE
    ./Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 -FilePath 'D:\setup.exe' -FileHash $sha512FileHash -Algorithm 'SHA512' -IAcceptSqlServerLicenseTerms -Credential (Get-Credential) -VmID 'VirtualMachine-vm-42'
    Performs a remote, PowerCLI-based in-place upgrade of the default
    SQL Server Database Engine instance (MSSQLSERVER) on the VM with MoRef ID
    'VirtualMachine-vm-42'. It will install in the default directory, and
    validates the integrity of the specified SQL Server setup file by comparing
    the SHA512 file hashes.

    .EXAMPLE
    ( Get-VM -Name '*SQL*' ).ID | ./Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 -FilePath 'D:\setup.exe' -FileHash $sha256FileHash -IAcceptSqlServerLicenseTerms -Credential (Get-Credential)
    Performs a remote, PowerCLI-based in-place upgrade of the default
    SQL Server Database Engine instance (MSSQLSERVER) on all VMs with 'SQL' in
    the name. It will install in the default directory, and validates the
    integrity of the specified SQL Server setup file by comparing the SHA256
    file hashes.

    .LINK
    https://awslabs.github.io/aws-tools-for-vmware/powershell/Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1/

    .LINK
    https://github.com/awslabs/aws-tools-for-vmware/blob/master/powershell/Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1

    .LINK
    https://docs.microsoft.com/sql/database-engine/install-windows/supported-version-and-edition-upgrades

    .LINK
    https://docs.microsoft.com/sql/database-engine/install-windows/upgrade-database-engine

    .LINK
    https://docs.microsoft.com/sql/database-engine/install-windows/plan-and-test-the-database-engine-upgrade-plan

    .LINK
    https://docs.microsoft.com/sql/sql-server/install/hardware-and-software-requirements-for-installing-sql-server

    .LINK
    https://docs.microsoft.com/sql/database-engine/sql-server-database-engine-backward-compatibility

    .LINK
    https://github.com/awslabs/aws-tools-for-vmware/issues/new

    .LINK
    https://console.aws.amazon.com/support/home#/case/create?issueType=technical
#>

[CmdletBinding( DefaultParameterSetName = 'Local', SupportsShouldProcess = $true, ConfirmImpact = 'High' )]
[OutputType( [string] )]

param (
    <#
    Specifies the path to the SQL Server installation media.

    Example: D:\setup.exe
    #>
    [Parameter(
        Mandatory = $true,
        Position = 0
    )]
    [ValidateNotNull()]
    [System.IO.FileInfo]
    $FilePath,

    <#
    Specifies the expected SQL Server setup file hash. This can be obtained via
    the `Get-FileHash` cmdlet, the `certutil.exe -HashFile` command, or similar
    tools.
    #>
    [Parameter(
        Mandatory = $true,
        Position = 1
    )]
    [ValidateLength( 32, 128 )]
    [string]
    $FileHash,

    # Specifies the setup file hash algorithm.
    [Parameter( Position = 2 )]
    [ValidateSet( 'MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512' )]
    [string]
    $Algorithm = 'SHA256',

    # Specifies the target SQL Server instance name.
    [Parameter(
        Position = 3,
        ValueFromPipelineByPropertyName = $true
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $InstanceName = 'MSSQLSERVER',

    # Specifies a non-default installation directory for shared components.
    [Parameter(
        Position = 4,
        ValueFromPipelineByPropertyName = $true
    )]
    [ValidateNotNull()]
    [System.IO.FileInfo]
    $InstanceDirectory,

    # Specifies the product key for the edition of SQL Server.
    [Parameter(
        Position = 5,
        ValueFromPipelineByPropertyName = $true
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $ProductKey,

    <#
    Required to acknowledge acceptance of Microsoft's license terms for
    SQL Server.

    Reference: https://docs.microsoft.com/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt#Upgrade
    #>
    [Parameter(
        Mandatory = $true,
        Position = 6
    )]
    [ValidateSet( $true )]
    [switch]
    $IAcceptSqlServerLicenseTerms,

    <#
    Specifies the Windows guest operating system credentials with
    administrative rights. Used for updating the SQL Server instance.
    #>
    [Parameter(
        ParameterSetName = 'Remote: VM by ID',
        Mandatory = $true,
        Position = 7
    )]
    [Parameter(
        ParameterSetName = 'Remote: VM by Name',
        Mandatory = $true,
        Position = 7
    )]
    [ValidateScript( { $_.GetNetworkCredential().Password.Length -gt 0 } )]
    [pscredential]
    $Credential,

    <#
    Specifies the vSphere managed object reference identifier (MoRef ID) of
    one or more target VMs.

    Example: VirtualMachine-vm-431
    #>
    [Parameter(
        ParameterSetName = 'Remote: VM by ID',
        Mandatory = $true,
        Position = 8,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [ValidatePattern( '^VirtualMachine-vm-\d+$' )]
    [Alias( 'ID' )]
    [string[]]
    $VmID,

    <#
    The name of one or more target VMs. Accepts wildcard characters.

    Example: SQL1, MSSQL*
    #>
    [Parameter(
        ParameterSetName = 'Remote: VM by Name',
        Mandatory = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [Alias( 'Name' )]
    [string[]]
    $VmName
)

begin {
    #region Functions
    function Get-LocalizedMessage {
        [CmdletBinding()]
        [OutputType( [string] )]

        param (
            # Specifies the key to lookup in the localized messages hash table
            [Parameter(
                Mandatory = $true,
                Position = 0,
                ValueFromPipeline = $true
            )]
            [ValidateNotNullOrEmpty()]
            [string]
            $Key,

            # Strings to insert into the message body.
            [Parameter(
                Position = 1,
                ValueFromRemainingArguments = $true
            )]
            [string[]]
            $Parameters
        )

        begin {
            $messages = @{
                'en-US' = @{
                    Beginning                          = 'Beginning: "{0}"'
                    Processing                         = "Processing: `"{0}`" with ParameterSetName `"{1}`" and Parameters:{2}"
                    Ending                             = 'Ending: "{0}"'

                    NoProductKeyUpgrade                = 'proceed with *NO PRODUCT KEY*'
                    Name                               = 'Name'
                    ID                                 = 'ID'
                    PowerState                         = 'PowerState'

                    ProductName                        = 'Microsoft SQL Server'
                    Comment                            = 'SQL'
                    CompanyName                        = 'Microsoft Corporation'

                    Local                              = 'local'
                    Remote                             = 'remote'
                    StartingPreFlight                  = 'Starting {0} mode pre-flight checks.'
                    StartingUpgrade                    = "`nStarting {0} mode SQL Server Database Engine instance upgrade.`n"

                    VerifyingCurrentSessionPermissions = 'Verifying current session permissions...'
                    VerifyingOperatingSystem           = 'Verifying operating system...'
                    VerifyingInstallationMediaExists   = 'Verifying installation media exists...'
                    VerifyingFileProperties            = 'Verifying file properties...'
                    VerifyingFileIntegrity             = 'Verifying file integrity...'
                    VerifyingInstance                  = 'Verifying SQL Server instance exists...'

                    TargetWithBackupWarning            = '{0} (MAKE SURE THAT YOU HAVE VERIFIED BACKUPS!)'

                    CurrentSessionIsUsingBuiltinRole   = 'Current session is using the {0} role.'
                    CurrentSessionNotUsingBuiltinRole  = 'Current session is not using the {0} role. Run this script as an {0}.'

                    OperatingSystemPass                = 'Windows operating system.'
                    OperatingSystemFail                = 'This tool only accommodates SQL Server upgrades on Windows operating systems.'

                    FileNotFound                       = 'File not found: "{0}".'
                    FileFound                          = 'File found: "{0}".'

                    FilePropertiesPass                 = 'File properties found on: "{0}" match known SQL Server installation file properties.'
                    FilePropertiesFail                 = 'File properties found on: "{0}" do not match known SQL Server installation file properties.'

                    FileIntegrityPass                  = 'File integrity confirmed: "{0}".'
                    FileIntegrityFail                  = 'File integrity failed: "{0}" Expected: "{1}" Actual: "{2}" Algorithm: "{3}".'

                    InstanceNotFound                   = 'SQL Server instance not found: "{0}"'
                    InstanceFound                      = 'SQL Server instance found: "{0}"'

                    PreFlightFailed                    = "`nOne or more pre-flight checks failed. Please remediate."

                    InstallModule                      = "Please install the VMware.PowerCLI module (reference: https://www.powershellgallery.com/packages/VMware.PowerCLI/)."
                    ImportModule                       = "Please import the VMware PowerCLI Core module (example: Import-Module -Name 'VMware.VimAutomation.Core')."
                    ConnectvCenter                     = "Please connect to vCenter (example: Connect-VIServer -Server 'vcenter.sddc.vmwarevmc.com')."

                    VmNotFound                         = 'VM with {0} "{1}" was not found using the specified filter(s).'
                    VmFound                            = 'VM(s) found:{0}'

                    VerifyingVmStatus                  = 'Verifying status of VM Name: "{0}" ID: "{1}"...'
                    VmPoweredOn                        = 'VM Name: "{0}" ID: "{1}" is powered on.'
                    VmPoweredOff                       = 'VM Name: "{0}" ID: "{1}" is powered off.'
                    VMwareToolsAreRunning              = 'VMware Tools are running in VM Name: "{0}" ID: "{1}".'
                    VMwareToolsNotRunning              = 'VMware Tools are not running in VM Name: "{0}" ID: "{1}".'

                    WhatIf                             = 'What if: Performing the operation "{0}" on target "{1}".'

                    UpgradePass                        = 'Completed successfully.'
                    UpgradeFail                        = 'Completed with errors.'
                }
            }
        }

        process {
            if ( $Key ) {
                if ( $PSCulture -in $messages.Keys ) {
                    $culture = $PSCulture
                }
                else {
                    $culture = 'en-US'
                }

                $message = $messages[$culture][$Key]
                if ( $Parameters ) {
                    $message = $message -f $Parameters
                }

                if ( $message ) {
                    $message
                }
                else {
                    $key
                }
            }
        }
    }

    # ===================================================================================
    function Write-Message {
        [CmdletBinding( DefaultParameterSetName = 'Message' )]
        [OutputType( [void] )]

        param (
            [Parameter(
                ParameterSetName = 'Message',
                Position = 0,
                ValueFromPipeline = $true
            )]
            [AllowEmptyString()]
            [string]
            $Message,

            [Parameter( ParameterSetName = 'Key' )]
            [ValidateNotNullOrEmpty()]
            [string]
            $Key,

            [Parameter( Position = 1 )]
            [ValidateSet( 'SUCCESS', 'WARNING', 'ERROR', 'INFO', 'VERBOSE' )]
            [string]
            $Mode = 'INFO',

            [Parameter(
                Position = 2,
                ValueFromRemainingArguments = $true
            )]
            [AllowNull()]
            [string[]]
            $Parameters
        )

        process {
            if ( $PSCmdlet.ParameterSetName -eq 'Key' ) {
                $Message = Get-LocalizedMessage -Key $Key -Parameters $Parameters
            }

            switch ( $Mode ) {
                'SUCCESS' {
                    Write-Host -Object "[+] ${Message}" -ForegroundColor 'Green' -BackgroundColor 'Black'
                }

                'ERROR' {
                    # Uses ForegroundColor Red and BackgroundColor Black
                    $Host.UI.WriteErrorLine( "[-] ${Message}" )

                    # Set ErrorVariable parameter and $error
                    Write-Error -Message $Message -ErrorAction 'SilentlyContinue'
                }

                'VERBOSE' {
                    Write-Verbose -Message $Message
                }

                default {
                    Write-Host -Object $Message
                }
            }
        }
    }

    # ===================================================================================
    function Test-Role {
        [CmdletBinding()]
        [OutputType( [bool] )]

        param (
            [Parameter( Position = 0 )]
            [ValidateSet(
                'AccountOperator',
                'Administrator',
                'BackupOperator',
                'Guest',
                'PowerUser',
                'PrintOperator',
                'Replicator',
                'SystemOperator',
                'User'
            )]
            [System.Security.Principal.WindowsBuiltInRole]
            $BuiltInRole = 'Administrator'
        )

        process {
            try {
                $currentSessionIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
                $currentSessionPrincipal = New-Object -TypeName 'System.Security.Principal.WindowsPrincipal' -ArgumentList $currentSessionIdentity
            }
            catch {
                Write-Message -Key 'ErrorVerifyingPSWindowsUser' -Mode 'ERROR'
                Write-Message -Message $_.Exception.Message -Mode 'ERROR'
                $false
            }

            if ( $currentSessionPrincipal.IsInRole( $BuiltInRole ) ) {
                $true
            }
            else {
                $false
            }
        }
    }

    function Out-UpgradeResult {
        [CmdletBinding()]
        [OutputType( [string] )]

        param (
            [Parameter(
                Mandatory = $true,
                Position = 0,
                ValueFromPipeline = $true
            )]
            [ValidateNotNullOrEmpty()]
            [string]
            $InputObject
        )

        process {
            $InputObject

            if ( $InputObject -match '(?:Exception type|The following error occurred):' ) {
                Write-Message -Key 'UpgradeFail' -Mode 'ERROR'
            }
            else {
                Write-Message -Key 'UpgradePass' -Mode 'SUCCESS'
            }
        }
    }
    #endregion

    # ===================================================================================
    $scriptName = $MyInvocation.MyCommand.Name
    Write-Message -Key 'Beginning' -Mode 'VERBOSE' -Parameters $scriptName

    #region Temporarily disable progress bars
    $progressBarAction = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    #endregion

    #region Read-only variables
    Set-Variable -Name 'FilePath' -Value $FilePath -Option 'ReadOnly' -WhatIf:$false
    Set-Variable -Name 'FileHash' -Value ( $FileHash -replace '\s', '' ).ToLower() -Option 'ReadOnly' -WhatIf:$false
    Set-Variable -Name 'Algorithm' -Value $Algorithm -Option 'ReadOnly' -WhatIf:$false
    New-Variable -Name 'parameterSetNameVmID' -Value 'Remote: VM by ID' -Option 'ReadOnly' -WhatIf:$false
    New-Variable -Name 'parameterSetNameVmName' -Value 'Remote: VM by Name' -Option 'ReadOnly' -WhatIf:$false
    New-Variable -Name 'role' -Value 'Administrator' -Option 'ReadOnly' -WhatIf:$false
    New-Variable -Name 'noProductKeyUpgrade' -Value ( Get-LocalizedMessage -Key 'NoProductKeyUpgrade' ) -Option 'ReadOnly' -WhatIf:$false
    New-Variable -Name 'name' -Value ( Get-LocalizedMessage -Key 'Name' ) -Option 'ReadOnly' -WhatIf:$false
    New-Variable -Name 'id' -Value ( Get-LocalizedMessage -Key 'ID' ) -Option 'ReadOnly' -WhatIf:$false
    New-Variable -Name 'productName' -Value ( Get-LocalizedMessage -Key 'ProductName' ) -Option 'ReadOnly' -WhatIf:$false
    New-Variable -Name 'comment' -Value ( Get-LocalizedMessage -Key 'Comment' ) -Option 'ReadOnly' -WhatIf:$false
    New-Variable -Name 'companyName' -Value ( Get-LocalizedMessage -Key 'CompanyName' ) -Option 'ReadOnly' -WhatIf:$false
    New-Variable -Name 'powerState' -Value ( Get-LocalizedMessage -Key 'PowerState' ) -Option 'ReadOnly' -WhatIf:$false
    New-Variable -Name 'local' -Value ( Get-LocalizedMessage -Key 'Local' ) -Option 'ReadOnly' -WhatIf:$false
    New-Variable -Name 'remote' -Value ( Get-LocalizedMessage -Key 'Remote' ) -Option 'ReadOnly' -WhatIf:$false
    New-Variable -Name 'vmGuestMessagePrefixLength' -Value 37 -Option 'ReadOnly' -WhatIf:$false
    #endregion
}

process {
    $parameters = $PSBoundParameters |
        Format-Table -AutoSize |
        Out-String
    Write-Message -Key 'Processing' -Mode 'VERBOSE' -Parameters $scriptName, $PSCmdlet.ParameterSetName, $parameters

    $preflightStatus = $true

    #region Build SQL Server upgrade command for this instance
    $command = "& '${FilePath}' /ACTION=Upgrade /Q /INSTANCENAME=${InstanceName} /INDICATEPROGRESS"
    if ( $IAcceptSqlServerLicenseTerms -eq $true ) {
        $command += ' /IACCEPTSQLSERVERLICENSETERMS'
    }
    if ( $null -ne $InstanceDirectory ) {
        $command += " /INSTANCEDIR='${InstanceDirectory}'"
    }
    if ( $ProductKey.Length -gt 0 ) {
        $command += " /PID=${ProductKey}"
    }
    elseif ( $PSCmdlet.ShouldProcess( $InstanceName, $noProductKeyUpgrade ) -ne $true -and $WhatIfPreference -ne $true ) {
        return
    }
    #endregion

    if ( $PSCmdlet.ParameterSetName -eq 'Local' ) {
        Write-Message -Key 'StartingPreFlight' -Mode 'VERBOSE' -Parameters $local

        #region Verify Windows operating system
        Write-Message -Key 'VerifyingOperatingSystem' -Mode 'VERBOSE'
        if ( $PSVersionTable.PSVersion.Major -lt 6 -or ( $IsCoreCLR -eq $true -and $IsWindows -eq $true ) ) {
            Write-Message -Key 'OperatingSystemPass' -Mode 'SUCCESS'
        }
        else {
            Write-Message -Key 'OperatingSystemFail' -Mode 'ERROR'
            return
        }
        #endregion

        #region Verify PowerShell is running with elevated privileges
        Write-Message -Key 'VerifyingCurrentSessionPermissions' -Mode 'VERBOSE'
        $isValid = Test-Role -BuiltInRole $role
        if ( $isValid -eq $true ) {
            Write-Message -Key 'CurrentSessionIsUsingBuiltinRole' -Mode 'SUCCESS' -Parameters $role
        }
        else {
            Write-Message -Key 'CurrentSessionNotUsingBuiltinRole' -Mode 'ERROR' -Parameters $role
            $preflightStatus = $false
        }
        #endregion

        #region Verify installation media
        Write-Message -Key 'VerifyingInstallationMediaExists' -Mode 'VERBOSE'
        if ( $FilePath.Exists -eq $true ) {
            Write-Message -Key 'FileFound' -Mode 'SUCCESS' -Parameters $FilePath.FullName
        }
        else {
            Write-Message -Key 'FileNotFound' -Mode 'ERROR' -Parameters $FilePath.FullName
            $preflightStatus = $false
        }
        #endregion

        #region Verify setup file properties
        Write-Message -Key 'VerifyingFileProperties' -Mode 'VERBOSE'
        if (
            ( $FilePath.VersionInfo.ProductName -eq $productName ) -and
            ( $FilePath.VersionInfo.Comments -eq $comment ) -and
            ( $FilePath.VersionInfo.CompanyName -eq $companyName )
        ) {
            Write-Message -Key 'FilePropertiesPass' -Mode 'SUCCESS' -Parameters $FilePath.FullName
        }
        else {
            Write-Message -Key 'FilePropertiesFail' -Mode 'ERROR' -Parameters $FilePath.FullName
            $preflightStatus = $false
        }
        #endregion

        #region Verify setup file integrity
        Write-Message -Key 'VerifyingFileIntegrity' -Mode 'VERBOSE'
        $hash = & "${Env:SystemRoot}\System32\certutil.exe" -HashFile $FilePath $Algorithm |
            Select-Object -Index 1
        # Remove whitespace and set to lowercase
        $hash = ( $hash -replace '\s', '' ).ToLower()
        if ( $FileHash -eq $hash ) {
            Write-Message -Key 'FileIntegrityPass' -Mode 'SUCCESS' -Parameters $FilePath.FullName
        }
        else {
            Write-Message -Key 'FileIntegrityFail' -Mode 'ERROR' -Parameters $FilePath.FullName, $FileHash, $hash, $Algorithm
            $preflightStatus = $false
        }
        #endregion

        #region Verify SQL Server instance exists
        Write-Message -Key 'VerifyingInstance' -Mode 'VERBOSE'

        $instances = ( Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Microsoft SQL Server' ).InstalledInstances
        if ( $InstanceName -in $instances ) {
            Write-Message -Key 'InstanceFound' -Mode 'SUCCESS' -Parameters $InstanceName
        }
        else {
            Write-Message -Key 'InstanceNotFound' -Mode 'ERROR' -Parameters $InstanceName
            $preflightStatus = $false
        }
        #endregion

        #region Upgrade local SQL Server instance!
        if ( $preflightStatus -eq $true ) {
            if ( $WhatIfPreference -eq $true ) {
                Write-Message -Key 'WhatIf' -Mode 'INFO' -Parameters $command, $Env:COMPUTERNAME
            }
            else {
                $targetWithBackupWarning = Get-LocalizedMessage -Key 'TargetWithBackupWarning' -Parameters $Env:COMPUTERNAME
                if ( $PSCmdlet.ShouldProcess( $targetWithBackupWarning, $command ) -eq $true ) {
                    Write-Message -Key 'StartingUpgrade' -Parameters $local
                    try {
                        $output = Invoke-Expression -Command $command -ErrorAction 'Stop'
                    }
                    catch {
                        Write-Message -Message $_.Exception.Message -Mode 'ERROR'
                    }

                    $output |
                        Out-String |
                        Out-UpgradeResult
                }
            }
        }
        else {
            Write-Message -Key 'PreFlightFailed'
        }
        #endregion
    }
    else {
        Write-Message -Key 'StartingPreFlight' -Mode 'VERBOSE' -Parameters $remote

        # Verify that PowerCLI module is installed
        $powerCliModuleInstallState = Get-Module -Name 'VMware.VimAutomation.Core' -ListAvailable -ErrorAction 'SilentlyContinue'
        # Verify that PowerCLI module is imported
        $powerCliModuleImportState = Get-Module -Name 'VMware.VimAutomation.Core' -ErrorAction 'SilentlyContinue'
        if ( $null -eq $powerCliModuleInstallState ) {
            Write-Message -Key 'InstallModule' -Mode 'ERROR'
            $preflightStatus = $false
        }
        elseif ( $null -eq $powerCliModuleImportState ) {
            Write-Message -Key 'ImportModule' -Mode 'ERROR'
            $preflightStatus = $false
        }
        # Verify that vCenter is connected
        elseif ( $Global:DefaultVIServer.IsConnected -ne $true ) {
            Write-Message -Key 'ConnectvCenter' -Mode 'ERROR'
            $preflightStatus = $false
        }
        else {
            #region Get VM(s)
            $splat = @{
                ErrorAction = 'Stop'
            }
            if ( $PSCmdlet.ParameterSetName -eq $parameterSetNameVmID ) {
                $splat.ID = $VmID
            }
            elseif ( $PSCmdlet.ParameterSetName -eq $parameterSetNameVmName ) {
                $splat.Name = $VmName
            }

            try {
                $vms = Get-VM @splat
            }
            catch {
                Write-Message -Message $_.Exception.Message -Mode 'ERROR'
                $preflightStatus = $false
            }
            #endregion

            #region Verify that at least one VM was found
            $count = ( $vms | Measure-Object ).Count
            if ( $PSCmdlet.ParameterSetName -eq $parameterSetNameVmID -and $count -lt 1 ) {
                $vmIdList = $VmID -join ', '
                Write-Message -Key 'VmNotFound' -Mode 'ERROR' -Parameters $id, $vmIdList
                $preflightStatus = $false
            }
            elseif ( $PSCmdlet.ParameterSetName -eq $parameterSetNameVmName -and $count -lt 1 ) {
                $vmNameList = $VmName -join ', '
                Write-Message -Key 'VmNotFound' -Mode 'ERROR' -Parameters $name, $vmNameList
                $preflightStatus = $false
            }
            else {
                $vmList = $vms |
                    Format-Table -AutoSize -Property $name, @{ Name = $id; Expression = { $_.ID } }, $PowerState |
                    Out-String
                Write-Message -Key 'VmFound' -Mode 'SUCCESS' -Parameters $vmList
            }
            #endregion

            foreach ( $vm in $vms ) {
                $parameters = $vm.Name, $vm.ID

                $splat = @{
                    VM              = $vm
                    GuestCredential = $Credential
                    ScriptType      = 'PowerShell'
                    Confirm         = $false
                    WhatIf          = $false
                    ErrorAction     = 'Stop'
                }

                #region Verify VM power state
                Write-Message -Key 'VerifyingVmStatus' -Mode 'VERBOSE' -Parameters $parameters
                if ( $vm.PowerState -eq 'PoweredOn' ) {
                    Write-Message -Key 'VmPoweredOn' -Mode 'SUCCESS' -Parameters $parameters
                }
                else {
                    Write-Message -Key 'VmPoweredOff' -Mode 'ERROR' -Parameters $parameters
                    continue
                }
                #endregion

                #region Verify VMware Tools
                if ( $vm.ExtensionData.Guest.ToolsRunningStatus -eq 'guestToolsRunning' ) {
                    Write-Message -Key 'VMwareToolsAreRunning' -Mode 'SUCCESS' -Parameters $parameters
                }
                else {
                    Write-Message -Key 'VMwareToolsNotRunning' -Mode 'ERROR' -Parameters $parameters
                    continue
                }
                #endregion

                #region Verify installation media
                Write-Message -Key 'VerifyingInstallationMediaExists' -Mode 'VERBOSE'

                $splat.ScriptText = "Test-Path -Path '${FilePath}' -PathType 'Leaf'"
                try {
                    $output = Invoke-VMScript @splat
                }
                catch {
                    $message = $_.Exception.Message.ToString().Substring( $vmGuestMessagePrefixLength )
                    Write-Message -Message $message -Mode 'ERROR'
                    continue
                }

                if ( $output.ExitCode -eq 0 -and $output.ScriptOutput -match '^True' ) {
                    Write-Message -Key 'FileFound' -Mode 'SUCCESS' -Parameters $FilePath.FullName
                }
                else {
                    Write-Message -Key 'FileNotFound' -Mode 'ERROR' -Parameters $FilePath.FullName
                    continue
                }
                #endregion

                #region Verify setup file properties
                Write-Message -Key 'VerifyingFileProperties' -Mode 'VERBOSE'

                $splat.ScriptText = @"
`$file = Get-Item -Path '${FilePath}'
`$file.VersionInfo.ProductName -eq '${productName}' -and
    `$file.VersionInfo.Comments -eq '${comment}' -and
    `$file.VersionInfo.CompanyName -eq '${companyName}'
"@
                try {
                    $output = Invoke-VMScript @splat
                }
                catch {
                    $message = $_.Exception.Message.ToString().Substring( $vmGuestMessagePrefixLength )
                    Write-Message -Message $message -Mode 'ERROR'
                    continue
                }

                if ( $output.ExitCode -eq 0 -and $output.ScriptOutput -match '^True' ) {
                    Write-Message -Key 'FilePropertiesPass' -Mode 'SUCCESS' -Parameters $FilePath.FullName
                }
                else {
                    Write-Message -Key 'FilePropertiesFail' -Mode 'ERROR' -Parameters $FilePath.FullName
                    continue
                }
                #endregion

                #region Verify setup file integrity
                Write-Message -Key 'VerifyingFileIntegrity' -Mode 'VERBOSE'

                $splat.ScriptText = @"
`$hash = & "`${Env:SystemRoot}\System32\certutil.exe" -HashFile $FilePath $Algorithm |
    Select-Object -Index 1
# Remove whitespace and set to lowercase
'${FileHash}' -eq ( `$hash -replace '\s', '' ).ToLower()
"@
                try {
                    $output = Invoke-VMScript @splat
                }
                catch {
                    $message = $_.Exception.Message.ToString().Substring( $vmGuestMessagePrefixLength )
                    Write-Message -Message $message -Mode 'ERROR'
                    continue
                }

                if ( $output.ExitCode -eq 0 -and $output.ScriptOutput -match '^True' ) {
                    Write-Message -Key 'FileIntegrityPass' -Mode 'SUCCESS' -Parameters $FilePath.FullName
                }
                else {
                    Write-Message -Key 'FileIntegrityFail' -Mode 'ERROR' -Parameters $FilePath.FullName, $FileHash, $hash, $Algorithm
                    continue
                }
                #endregion

                #region Verify SQL Server instance exists
                Write-Message -Key 'VerifyingInstance' -Mode 'VERBOSE'

                $instances = ( Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Microsoft SQL Server' ).InstalledInstances
                if ( $InstanceName -in $instances ) {
                    Write-Message -Key 'InstanceFound' -Mode 'SUCCESS' -Parameters $InstanceName
                }
                else {
                    Write-Message -Key 'InstanceNotFound' -Mode 'ERROR' -Parameters $InstanceName
                    $preflightStatus = $false
                }
                #endregion

                #region Upgrade remote SQL Server instance!
                $splat.ScriptText = $command
                if ( $WhatIfPreference -eq $true ) {
                    Write-Message -Key 'WhatIf' -Mode 'INFO' -Parameters $command, $vm.Name
                }
                else {
                    $targetWithBackupWarning = Get-LocalizedMessage -Key 'TargetWithBackupWarning' -Parameters $vm.Name
                    if ( $PSCmdlet.ShouldProcess( $targetWithBackupWarning, $command ) -eq $true ) {
                        Write-Message -Key 'StartingUpgrade' -Parameters $remote
                        try {
                            $output = Invoke-VMScript @splat
                        }
                        catch {
                            $message = $_.Exception.Message.ToString().Substring( $vmGuestMessagePrefixLength )
                            Write-Message -Message $message -Mode 'ERROR'
                            continue
                        }

                        Out-UpgradeResult -InputObject $output.ScriptOutput
                    }
                }
            }
        }

        if ( $preflightStatus -ne $true ) {
            Write-Message -Key 'PreFlightFailed'
        }
    }
}

end {
    $ProgressPreference = $progressBarAction

    Write-Message -Key 'Ending' -Mode 'VERBOSE' -Parameters $scriptName
}

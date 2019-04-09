---
external help file:
Module Name:
online version: https://awslabs.github.io/aws-tools-for-vmware/powershell/Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1/
schema: 2.0.0
---

# Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1

## SYNOPSIS
Upgrade a standalone SQL Server Database Engine instance in-place.

## SYNTAX

### Local (Default)
```
Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 [-FilePath] <FileInfo> [-FileHash] <String>
 [[-Algorithm] <String>] [[-InstanceName] <String>] [[-InstanceDirectory] <FileInfo>] [[-ProductKey] <String>]
 [-IAcceptSqlServerLicenseTerms] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Remote: VM by Name
```
Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 [-FilePath] <FileInfo> [-FileHash] <String>
 [[-Algorithm] <String>] [[-InstanceName] <String>] [[-InstanceDirectory] <FileInfo>] [[-ProductKey] <String>]
 [-IAcceptSqlServerLicenseTerms] [-Credential] <PSCredential> -VmName <String[]> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Remote: VM by ID
```
Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 [-FilePath] <FileInfo> [-FileHash] <String>
 [[-Algorithm] <String>] [[-InstanceName] <String>] [[-InstanceDirectory] <FileInfo>] [[-ProductKey] <String>]
 [-IAcceptSqlServerLicenseTerms] [-Credential] <PSCredential> [-VmID] <String[]> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
### What this tool does

This will perform an *impactful*, in-place, major version upgrade, such as
SQL Server 2008 SP4 -\> 2017 or 2008 R2 SP3 -\> 2016, on a standalone
SQL Server Database Engine instance on a Windows operating system.
It can
be run either locally, or remotely if deployed on a Windows VM in a vSphere
environment such as VMware Cloud on AWS.
You must supply your own
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

!!!
danger "Backups are *NOT* included"
    Backups are *NOT* included.
Please make sure that you have implemented
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

The checks run prior to the upgrade cannot test for every eventuality.
In
fact, most of the requirements and compatibility testing is delegated to
Microsoft's SQL Server installation media since it was built with a robust
testing framework.
Please test thoroughly.

### Security
To reduce the risk of unintended code execution, a file hash must be
supplied for the setup file, which will be compared to a file hash of the
specified setup file in an attempt to confirm file integrity and that the
correct media has been loaded before launching the upgrade.
Additionally,
a few properties will be checked in an attempt to confirm that a
SQL Server setup file has been specified.

### Local upgrades
For local upgrades, this script requires elevated privileges and must be
run from PowerShell launched with the 'Run as Administrator' option.

### Remote upgrades
For VMware PowerCLI-based remote upgrades, HTTPS (443/tcp) connectivity is
required to the ESXi hosts as well as vCenter for executing commands in the
VM's guest operating system via the VMware Guest Operations API.
This
connectivity is not permitted by default, such as in VMware Cloud on AWS,
but can be configured.

This tool does not attempt to install or import the required PowerCLI
modules, nor does it attempt to establish a PowerCLI session with vCenter.
For VMware PowerCLI installation instructions, please see:
https://www.powershellgallery.com/packages/VMware.PowerCLI/.
Once
installed, run \`Import-Module -Name 'VMware.VimAutomation.Core'\` to import
the subset of modules required.
To learn more about how to establish a
PowerCLI session, run \`Get-Help -Name 'Connect-VIServer' -Detailed\`, which
includes a few examples.

All target VMs must be powered on, and VMware Tools must be installed and
running in the guest operating system of each Windows VM.

The supplied credentials will be used on each VM to access the guest
operating system, and must have administrative privileges.
Because feature:
https://powercli.ideas.aha.io/ideas/PCLI-I-101 has neither been accepted
nor released by the PowerCLI team, Windows User Account Control (UAC) must
be disabled in each guest operating system as well.

Multiple VMs can be specified in the same command for batch upgrades via an
array of VM IDs or names, as well as wildcard globbing of VM names;
however, the SQL Server instance on each VM is upgraded iteratively, not
concurrently.
Please plan accordingly.

## EXAMPLES

### EXAMPLE 1
```
./Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 -FilePath 'D:\setup.exe' -FileHash $sha256FileHash -IAcceptSqlServerLicenseTerms -WhatIf
```

Performs a 'dry run test' of a local, in-place upgrade of the default
SQL Server Database Engine instance (MSSQLSERVER) that would install in the
default directory, and validates the integrity of the specified SQL Server
setup file by comparing the SHA256 file hashes.

Since a product key / license was not supplied, the instance would be
upgraded into Evaluation mode unless upgraded to SQL Server Express
edition.

### EXAMPLE 2
```
./Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 -FilePath 'D:\setup.exe' -FileHash $sha256FileHash -IAcceptSqlServerLicenseTerms
```

Implements the previous example.

Since a product key / license was not supplied, the instance will be
upgraded into Evaluation mode unless upgraded to SQL Server Express
edition.

### EXAMPLE 3
```
./Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 -FilePath 'E:\setup.exe' -FileHash $md5FileHash -Algorithm 'MD5' -InstanceName 'SQLEXPRESS' -InstanceDirectory 'D:\MSSQL' -ProductKey $productKey -IAcceptSqlServerLicenseTerms
```

Performs a local, in-place upgrade of the SQLEXPRESS SQL Server Database
Engine instance that will install in the specified directory, validates the
integrity of the specified SQL Server setup file by comparing the MD5 file
hashes, and applies the specified product key.

### EXAMPLE 4
```
./Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 'E:\setup.exe' $md5FileHash 'MD5' 'SQLEXPRESS' 'D:\MSSQL' $productKey $true
```

The same in-place upgrade as in the example above using positional
arguments.

### EXAMPLE 5
```
./Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 -FilePath 'O:\setup.exe' -FileHash $md5FileHash -Algorithm 'MD5' -IAcceptSqlServerLicenseTerms -Credential (Get-Credential) -VmName 'SQL1', 'MSSQL*'
```

Performs a remote, PowerCLI-based in-place upgrade of the default
SQL Server Database Engine instance (MSSQLSERVER) on the SQL1 VM, as well
as any VM with a name starting 'MSSQL' (due to the '*' wildcard).
It will
install in the default directory, and validates the integrity of the
specified SQL Server setup file by comparing the MD5 file hashes.

### EXAMPLE 6
```
./Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 -FilePath 'D:\setup.exe' -FileHash $sha512FileHash -Algorithm 'SHA512' -IAcceptSqlServerLicenseTerms -Credential (Get-Credential) -VmID 'VirtualMachine-vm-42'
```

Performs a remote, PowerCLI-based in-place upgrade of the default
SQL Server Database Engine instance (MSSQLSERVER) on the VM with MoRef ID
'VirtualMachine-vm-42'.
It will install in the default directory, and
validates the integrity of the specified SQL Server setup file by comparing
the SHA512 file hashes.

### EXAMPLE 7
```
( Get-VM -Name '*SQL*' ).ID | ./Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1 -FilePath 'D:\setup.exe' -FileHash $sha256FileHash -IAcceptSqlServerLicenseTerms -Credential (Get-Credential)
```

Performs a remote, PowerCLI-based in-place upgrade of the default
SQL Server Database Engine instance (MSSQLSERVER) on all VMs with 'SQL' in
the name.
It will install in the default directory, and validates the
integrity of the specified SQL Server setup file by comparing the SHA256
file hashes.

## PARAMETERS

### -FilePath
Specifies the path to the SQL Server installation media.

Example: D:\setup.exe

```yaml
Type: System.IO.FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileHash
Specifies the expected SQL Server setup file hash.
This can be obtained via
the \`Get-FileHash\` cmdlet, the \`certutil.exe -HashFile\` command, or similar
tools.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Algorithm
Specifies the setup file hash algorithm.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: SHA256
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstanceName
Specifies the target SQL Server instance name.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: MSSQLSERVER
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -InstanceDirectory
Specifies a non-default installation directory for shared components.

```yaml
Type: System.IO.FileInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ProductKey
Specifies the product key for the edition of SQL Server.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -IAcceptSqlServerLicenseTerms
Required to acknowledge acceptance of Microsoft's license terms for
SQL Server.

Reference: https://docs.microsoft.com/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt#Upgrade

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: True
Position: 7
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Specifies the Windows guest operating system credentials with
administrative rights.
Used for updating the SQL Server instance.

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: Remote: VM by Name, Remote: VM by ID
Aliases:

Required: True
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VmID
Specifies the vSphere managed object reference identifier (MoRef ID) of
one or more target VMs.

Example: VirtualMachine-vm-431

```yaml
Type: System.String[]
Parameter Sets: Remote: VM by ID
Aliases: ID

Required: True
Position: 9
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -VmName
The name of one or more target VMs.
Accepts wildcard characters.

Example: SQL1, MSSQL*

```yaml
Type: System.String[]
Parameter Sets: Remote: VM by Name
Aliases: Name

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: True
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
## OUTPUTS

### System.String
## NOTES
Version: 0.1.0

## RELATED LINKS

[https://awslabs.github.io/aws-tools-for-vmware/powershell/Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1/](https://awslabs.github.io/aws-tools-for-vmware/powershell/Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1/)

[https://github.com/awslabs/aws-tools-for-vmware/blob/master/powershell/Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1](https://github.com/awslabs/aws-tools-for-vmware/blob/master/powershell/Upgrade-SqlServerStandaloneDatabaseEngineInstance.ps1)

[https://docs.microsoft.com/sql/database-engine/install-windows/supported-version-and-edition-upgrades](https://docs.microsoft.com/sql/database-engine/install-windows/supported-version-and-edition-upgrades)

[https://docs.microsoft.com/sql/database-engine/install-windows/upgrade-database-engine](https://docs.microsoft.com/sql/database-engine/install-windows/upgrade-database-engine)

[https://docs.microsoft.com/sql/database-engine/install-windows/plan-and-test-the-database-engine-upgrade-plan](https://docs.microsoft.com/sql/database-engine/install-windows/plan-and-test-the-database-engine-upgrade-plan)

[https://docs.microsoft.com/sql/sql-server/install/hardware-and-software-requirements-for-installing-sql-server](https://docs.microsoft.com/sql/sql-server/install/hardware-and-software-requirements-for-installing-sql-server)

[https://docs.microsoft.com/sql/database-engine/sql-server-database-engine-backward-compatibility](https://docs.microsoft.com/sql/database-engine/sql-server-database-engine-backward-compatibility)

[https://github.com/awslabs/aws-tools-for-vmware/issues/new](https://github.com/awslabs/aws-tools-for-vmware/issues/new)

[https://console.aws.amazon.com/support/home#/case/create?issueType=technical](https://console.aws.amazon.com/support/home#/case/create?issueType=technical)


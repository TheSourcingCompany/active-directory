<#PSScriptInfo
.VERSION 1.0.0
.GUID a8b9b735-a13d-4901-8edd-a2eb3a589183
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/ComputerManagementDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/ComputerManagementDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module ComputerManagementDsc

<#
    .DESCRIPTION
        This configuration sets the machine name to 'Server01' and
        joins the 'Contoso' domain.
        Note: this requires an AD credential to join the domain.
#>
Configuration ConfigureExchange
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $Admincreds,
        $DomainName,
        $ComputerName

    )

    Import-DscResource -Module ComputerManagementDsc
    Import-DscResource -Module xPendingReboot
    Import-DscResource -Module xExchange
    Import-DscResource -Module xDownloadfile
    Import-DscResource -Module StorageDsc

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)


    Node localhost
    {
        Computer JoinDomain {
            Name       = $ComputerName
            DomainName = $DomainName
            Credential = $DomainCreds # Credential to join to domain
        }

        xPendingReboot Reboot1 {

            Name = 'AfterDomainJoin'

        }



        WindowsFeature NETWCFHTTPActivation45 {
            Ensure = 'Present'
            Name   = 'NET-WCF-HTTP-Activation45'
        }

        WindowsFeature NetFW45 {
            Ensure = 'Present'
            Name   = 'NET-Framework-45-Features'
        }
        WindowsFeature RPCProxy {
            Ensure = 'Present'
            Name   = 'RPC-over-HTTP-proxy'
        }
        WindowsFeature RSATClus {
            Ensure = 'Present'
            Name   = 'RSAT-Clustering'
        }
        WindowsFeature RSATClusCmd {
            Ensure = 'Present'
            Name   = 'RSAT-Clustering-CmdInterface'
        }
        WindowsFeature RSATClusMgmt {
            Ensure = 'Present'
            Name   = 'RSAT-Clustering-Mgmt'
        }
        WindowsFeature RSATClusPS {
            Ensure = 'Present'
            Name   = 'RSAT-Clustering-PowerShell'
        }
        WindowsFeature WebConsole {
            Ensure = 'Present'
            Name   = 'Web-Mgmt-Console'
        }
        WindowsFeature WAS {
            Ensure = 'Present'
            Name   = 'WAS-Process-Model'
        }
        WindowsFeature WebAsp {
            Ensure = 'Present'
            Name   = 'Web-Asp-Net45'
        }
        WindowsFeature WBA {
            Ensure = 'Present'
            Name   = 'Web-Basic-Auth'
        }
        WindowsFeature WCA {
            Ensure = 'Present'
            Name   = 'Web-Client-Auth'
        }
        WindowsFeature WDA {
            Ensure = 'Present'
            Name   = 'Web-Digest-Auth'
        }
        WindowsFeature WDB {
            Ensure = 'Present'
            Name   = 'Web-Dir-Browsing'
        }
        WindowsFeature WDC {
            Ensure = 'Present'
            Name   = 'Web-Dyn-Compression'
        }
        WindowsFeature WebHttp {
            Ensure = 'Present'
            Name   = 'Web-Http-Errors'
        }
        WindowsFeature WebHttpLog {
            Ensure = 'Present'
            Name   = 'Web-Http-Logging'
        }
        WindowsFeature WebHttpRed {
            Ensure = 'Present'
            Name   = 'Web-Http-Redirect'
        }
        WindowsFeature WebHttpTrac {
            Ensure = 'Present'
            Name   = 'Web-Http-Tracing'
        }
        WindowsFeature WebISAPI {
            Ensure = 'Present'
            Name   = 'Web-ISAPI-Ext'
        }
        WindowsFeature WebISAPIFilt {
            Ensure = 'Present'
            Name   = 'Web-ISAPI-Filter'
        }
        WindowsFeature WebLgcyMgmt {
            Ensure = 'Present'
            Name   = 'Web-Lgcy-Mgmt-Console'
        }
        WindowsFeature WebMetaDB {
            Ensure = 'Present'
            Name   = 'Web-Metabase'
        }
        WindowsFeature WebMgmtSvc {
            Ensure = 'Present'
            Name   = 'Web-Mgmt-Service'
        }
        WindowsFeature WebNet45 {
            Ensure = 'Present'
            Name   = 'Web-Net-Ext45'
        }
        WindowsFeature WebReq {
            Ensure = 'Present'
            Name   = 'Web-Request-Monitor'
        }
        WindowsFeature WebSrv {
            Ensure = 'Present'
            Name   = 'Web-Server'
        }
        WindowsFeature WebStat {
            Ensure = 'Present'
            Name   = 'Web-Stat-Compression'
        }
        WindowsFeature WebStatCont {
            Ensure = 'Present'
            Name   = 'Web-Static-Content'
        }
        WindowsFeature WebWindAuth {
            Ensure = 'Present'
            Name   = 'Web-Windows-Auth'
        }
        WindowsFeature WebWMI {
            Ensure = 'Present'
            Name   = 'Web-WMI'
        }
        WindowsFeature WebIF {
            Ensure = 'Present'
            Name   = 'Windows-Identity-Foundation'
        }
        WindowsFeature RSATADDS {
            Ensure = 'Present'
            Name   = 'RSAT-ADDS'
        }



        xDownloadfile DownloadNet48 {

            SourcePath               = "https://go.microsoft.com/fwlink/?linkid=2088631"
            DestinationDirectoryPath = "C:\Temp"
            Filename                 = "ndp48-x86-x64-allos-enu.exe"
        }


        Script NetFrameworkInstall {
            GetScript  = {

            }

            SetScript  = {
                Start-Process -FilePath 'c:\Temp\ndp48-x86-x64-allos-enu.exe' -ArgumentList '/q /norestart' -Wait
            }

            TestScript = {
                Get-ChildItem 'HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' |
                Get-ItemPropertyValue -Name Release |
                ForEach-Object { $_ -ge 528049 }
            }
            DependsOn  = '[xDownloadfile]DownloadNet48'
        }

        xDownloadfile DownloadUcmaRuntimeSetup {

            SourcePath               = "https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe"
            DestinationDirectoryPath = "C:\Temp"
            Filename                 = "UcmaRuntimeSetup.exe"
        }

        Package UCMA {
            Ensure    = 'Present'
            Name      = 'Microsoft Unified Communications Managed API 4.0, Core
                    Runtime 64-bit'
            Path      = 'c:\Temp\UcmaRuntimeSetup.exe'
            ProductID = 'ED98ABF5-B6BF-47ED-92AB-1CDCAB964447'
            Arguments = '/q'
            DependsOn = '[xDownloadfile]DownloadUcmaRuntimeSetup'

        }

        xDownloadfile Exchange2016 {

            SourcePath               = "https://download.microsoft.com/download/0/b/7/0b702b8b-03ab-4553-9e2c-c73bb0c8535f/ExchangeServer2016-x64-CU20.ISO"
            DestinationDirectoryPath = "C:\Temp"
            Filename                 = "ExchangeServer2016-x64-CU20.ISO"
        }

        MountImage ISO
        {
            ImagePath   = 'c:\temp\ExchangeServer2016-x64-CU20.iso'
            DriveLetter = 'S'
            DependsOn   = '[xDownloadfile]Exchange2016'
        }

        WaitForVolume WaitForISO
        {
            DriveLetter      = 'S'
            RetryIntervalSec = 5
            RetryCount       = 10
            DependsOn        = '[MountImage]ISO'
        }

        xExchInstall InstallExchange
        {
            Path       = "S:\Setup.exe"
            Arguments  = "/mode:Install /role:Mailbox /OrganizationName:""default"" /Iacceptexchangeserverlicenseterms"
            Credential = $DomainCreds
            DependsOn  = '[WaitForVolume]WaitForISO'
        }

        xPendingReboot AfterExchangeInstall {
            Name      = "AfterExchangeInstall"

            DependsOn = '[xExchInstall]InstallExchange'
        }

    }
}

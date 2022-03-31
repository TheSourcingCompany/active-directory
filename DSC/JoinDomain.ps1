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
Configuration JoinDomain
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential,
        $DomainName,
        $ComputerName

    )

    Import-DscResource -Module ComputerManagementDsc

    Node localhost
    {
        Computer JoinDomain {
            Name       = $ComputerName
            DomainName = $DomainName
            Credential = $Credential # Credential to join to domain
        }
    }
}

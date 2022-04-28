configuration ConfigureMgmt
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

    Import-DscResource -Module ComputerManagementDsc, xPendingReboot

    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature RSAT-ADDS
        {
            Ensure = "Present"
            Name = "RSAT-ADDS"
        }

        WindowsFeature RSAT-DNS-Server
        {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]RSAT-ADDS"
        }

        WindowsFeature GPMC 
        {
            Ensure = "Present"
            Name = "GPMC"
            DependsOn = "[WindowsFeature]RSAT-DNS-Server"
        }

        Computer JoinDomain {
            Name       = $ComputerName
            DomainName = $DomainName
            Credential = $DomainCreds # Credential to join to domain
            DependsOn = "[WindowsFeature]GPMC"
        }

        xPendingReboot Reboot1 {
            Name = 'AfterDomainJoin'
        }
    }
}

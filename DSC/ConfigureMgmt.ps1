configuration ConfigureMgmt
{
   param
    ()

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature RSATADDS
        {
            Ensure = "Present"
            Name = "RSAT-ADDS"
        }

        WindowsFeature RSATDNSServer
        {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]RSATADDSTools"
        }

        WindowsFeature GPMC 
        {
            Ensure = "Present"
            Name = "GPMC"
            DependsOn = "[WindowsFeature]RSATDNSServer"
        }

    }
}

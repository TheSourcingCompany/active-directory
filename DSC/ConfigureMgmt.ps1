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

    }
}

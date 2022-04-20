Configuration ConfigureAVD {

    Import-DscResource -Name xDownloadFile
    Import-DscResource -Name xPendingReboot

    Node Localhost {

            xDownloadFile Office365ODT
        {
            SourcePath               = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_14729-20228.exe"
            DestinationDirectoryPath = "C:\Temp"
            FileName                 = "odt.exe"
        }

        xDownloadFile Virtual-Desktop-Optimization-Tool
        {
            SourcePath               =      "https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip"
            DestinationDirectoryPath = "C:\Temp\"
            FileName                 = "Virtual-Desktop-Optimization-Tool.zip"
        }

        Archive VDOTExtract { #ResourceName
            Destination = "C:\Temp\VDOT"
            Path        = "C:\Temp\Virtual-Desktop-Optimization-Tool.zip"
            Force       = $true
            Ensure      = "Present"
            DependsOn   = '[xDownloadFile]Virtual-Desktop-Optimization-Tool'
        }

        Script DeployVDOT {
            SetScript  = {

                $LocalPath = "C:\Temp\VDOT"

                $ExtractedFolder = Get-ChildItem $LocalPath | ? { $_.name -ilike "*-main*" }

                Set-location $ExtractedFolder.FullName

                $AppxpackagesConfigurationFile = Get-ChildItem -Path "2009\Configurationfiles\appxPackages.json"
                $Appxjson = Get-Content $AppxpackagesConfigurationFile -Raw
                $AppxObj = ConvertFrom-Json $Appxjson

                $AppxPackages = @()

                foreach ($AppxPackage in $AppxObj) {

                    $AppxPackage.vdistate = "Disabled"

                    $AppxPackages += $AppxPackage

                }

                Set-Content "2009\Configurationfiles\appxPackages.json" -Value $($AppxPackages | ConvertTo-Json)

                .\Windows_VDOT.ps1 -WindowsVersion 2009 -Optimizations @('All', 'WindowsMediaPlayer', 'AppxPackages', 'ScheduledTasks', 'Autologgers', 'Services', 'NetworkOptimizations', 'LGPO')  -AcceptEULA

            }
            TestScript = { return $false }
            GetScript  = { "" }
            DependsOn  = '[xDownloadFile]TeamsWideInstaller'
        }

                Script ExtractODT {
            SetScript  = {

             Start-Process -FilePath 'C:\Temp\odt.exe' -ArgumentList '/quiet /extract:"C:\Temp\ODT"' -Wait

            }
            TestScript = {  Test-path "C:\Temp\ODT\setup.exe" }
            GetScript  = { "" }
            DependsOn = '[xDownloadFile]Office365ODT'
        }

        File ConfigurationXML {
            DestinationPath = 'C:\Temp\configuration.xml'
            Ensure          = "Present"
            Force           = $true
            Contents        = '<Configuration ID="f048c565-e231-4e15-ad1d-d8f76a1e2a50">
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="nl-nl" />
      <Language ID="en-us" />
      <ExcludeApp ID="Access" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="Publisher" />
      <ExcludeApp ID="Bing" />
    </Product>
    <Product ID="ProofingTools">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Property Name="SharedComputerLicensing" Value="1" />
  <Property Name="FORCEAPPSHUTDOWN" Value="FALSE" />
  <Property Name="DeviceBasedLicensing" Value="0" />
  <Property Name="SCLCacheOverride" Value="0" />
  <Updates Enabled="TRUE" />
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>'
            DependsOn       = '[xDownloadFile]Office365ODT'

        }

        Package Office365 {

            Ensure    = "Present"
            Name      = "Microsoft 365-apps voor ondernemingen - nl-nl"
            Path      = "C:\Temp\ODT\setup.exe"
            ProductId = ""
            Arguments = "/configure C:\Temp\Configuration.xml"
            DependsOn = '[File]ConfigurationXML'
        }

        xDownloadFile TeamsWideInstaller
        {
            SourcePath               = "https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true"
            DestinationDirectoryPath = "C:\Temp"
            FileName                 = "TeamsMachineWideInstaller.msi"
        }

        Registry SetIsWVDEnvRegkey { #ResourceName
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Teams"
            ValueName = "IsWVDEnvironment"
            Force     = $true
            ValueData = 1
            ValueType = "Dword"
            Ensure    = "Present"
        }

        Registry HideShutDown { #ResourceName
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\default\Start\HideShutDown"
            ValueName = "value"
            Force     = $true
            ValueData = 1
            ValueType = "Dword"
            Ensure    = "Present"
        }

        Registry HideRestart { #ResourceName
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\default\Start\HideRestart"
            ValueName = "value"
            Force     = $true
            ValueData = 1
            ValueType = "Dword"
            Ensure    = "Present"
        }

        Script RemoveBogusTeamsInstaller {
            SetScript  = {
                $MyApp = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "Teams Machine-Wide Installer" }
                if ($MyApp) { $MyApp.Uninstall() }

            }
            TestScript = { return $false }
            GetScript  = { "" }
            DependsOn  = '[xDownloadFile]TeamsWideInstaller'
        }

        Script InstallTeamsInstaller {
            SetScript  = {

                msiexec /i "C:\Temp\TeamsMachineWideInstaller.msi" /l*v "C:\Temp\TeamsMachineWideInstaller.log" ALLUSER=1
                start-sleep -seconds 60
            }
            TestScript = { return $false }
            GetScript  = { "" }
            DependsOn  = '[Script]RemoveBogusTeamsInstaller'
        }

        Script SetTimeZone {
            SetScript  = {

                Set-TimeZone -Id "W. Europe Standard Time"

            }
            TestScript = { return $false }
            GetScript  = { "" }
            DependsOn  = '[Script]InstallTeamsInstaller'
        }

    }


}

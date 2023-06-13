configuration CreateADPDC
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$ADConnectAccountCreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$TestAccountCreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$DSRMCreds,

        [Int]$RetryCount = 20,
        [Int]$RetryIntervalSec = 30,

        [Parameter(Mandatory)]
        [String]$customerCode, 

        [Parameter(Mandatory)]
        [String]$customerName


    )


    Function New-SWRandomPassword {
        [CmdletBinding(DefaultParameterSetName = 'FixedLength', ConfirmImpact = 'None')]
        [OutputType([String])]
        Param (
            # Specifies minimum password length
            [Parameter(Mandatory = $false,
                ParameterSetName = 'RandomLength'
            )]
            [ValidateScript({
                    $_ -gt 0
                })]
            [Alias('Min')]
            [int]$MinPasswordLength = 20,
            # Specifies maximum password length
    
            [Parameter(Mandatory = $false,
                ParameterSetName = 'RandomLength')]
            [ValidateScript({
                    if ($_ -ge $MinPasswordLength) {
                        $true
                    }
                    else {
                        Throw 'Max value cannot be less than min value.'
                    }
                })]
            [Alias('Max')]
            [int]$MaxPasswordLength = 25,
            # Specifies a fixed password length
    
            [Parameter(Mandatory = $false,
                ParameterSetName = 'FixedLength')]
            [ValidateRange(1, 2147483647)]
            [int]$PasswordLength = 20,
            # Specifies an array of strings containing charactergroups from which the password will be generated.
    
            # At least one char from each group (string) will be used.
    
            [String[]]$InputStrings = @('abcdefghijkmnpqrstuvwxyz', 'ABCEFGHJKLMNPQRSTUVWXYZ', '23456789', '[],\&!+=^-_#:;*.<>()%?$'),
            # Specifies a string containing a character group from which the first character in the password will be generated.
    
            # Useful for systems which requires first char in password to be alphabetic.
    
            [String]$FirstChar,
            # Specifies number of passwords to generate.
    
            [ValidateRange(1, 2147483647)]
            [int]$Count = 1
        )
        Begin {
            Function Get-Seed {
                # Generate a seed for randomization
                $RandomBytes = New-Object -TypeName 'System.Byte[]' 4
                $Random = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider'
                $Random.GetBytes($RandomBytes)
                [BitConverter]::ToUInt32($RandomBytes, 0)
            }
        }
        Process {
            For ($iteration = 1; $iteration -le $Count; $iteration++) {
                $Password = @{
                }
                # Create char arrays containing groups of possible chars
                [char[][]]$CharGroups = $InputStrings
                
                # Create char array containing all chars
                $AllChars = $CharGroups | ForEach-Object {
                    [Char[]]$_
                }
                
                # Set password length
                if ($PSCmdlet.ParameterSetName -eq 'RandomLength') {
                    if ($MinPasswordLength -eq $MaxPasswordLength) {
                        # If password length is set, use set length
                        $PasswordLength = $MinPasswordLength
                    }
                    else {
                        # Otherwise randomize password length
                        $PasswordLength = ((Get-Seed) % ($MaxPasswordLength + 1 - $MinPasswordLength)) + $MinPasswordLength
                    }
                }
                
                # If FirstChar is defined, randomize first char in password from that string.
                if ($PSBoundParameters.ContainsKey('FirstChar')) {
                    $Password.Add(0, $FirstChar[((Get-Seed) % $FirstChar.Length)])
                }
                # Randomize one char from each group
                Foreach ($Group in $CharGroups) {
                    if ($Password.Count -lt $PasswordLength) {
                        $Index = Get-Seed
                        While ($Password.ContainsKey($Index)) {
                            $Index = Get-Seed
                        }
                        $Password.Add($Index, $Group[((Get-Seed) % $Group.Count)])
                    }
                }
                
                # Fill out with chars from $AllChars
                for ($i = $Password.Count; $i -lt $PasswordLength; $i++) {
                    $Index = Get-Seed
                    While ($Password.ContainsKey($Index)) {
                        $Index = Get-Seed
                    }
                    $Password.Add($Index, $AllChars[((Get-Seed) % $AllChars.Count)])
                }
                Write-Output -InputObject $( -join ($Password.GetEnumerator() | Sort-Object -Property Name | Select-Object -ExpandProperty Value))
            }
        }
    }

  
    Import-DscResource -ModuleName 'ActiveDirectoryDsc'
    Import-DscResource -ModuleName 'ComputerManagementDSC'
    Import-DscResource -ModuleName 'StorageDsc'
    Import-DscResource -ModuleName 'NetworkingDSC'

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)
    
    $BedrijfOUs = "Beheer Accounts", "NEH Beheer Accounts", "Contacts", "Disabled Users", "Gebruikers", "Groepen", "Resource Accounts", "Servers", "Service Accounts", "Werkstations"
    $GebruikerOUs = "Test OU", "Test SE"
    $GroepenOUs = "Afdelingen", "Applicatie Groepen", "Distributie Groepen", "Security Groepen"
    $ServerOUs = "DMZ Servers", "Test Servers", "Productie Servers"
    $WerkstationOUs = "Surfaces", "Desktops", "Laptops"

    $RootOUPath = "DC=$($DomainName.Split('.')[0]),DC=$($DomainName.Split('.')[1])"
    $BedrijfOUPath = "OU=$customerName, DC=$($DomainName.Split('.')[0]),DC=$($DomainName.Split('.')[1])"
    $GebruikersOUPath = "OU=Gebruikers,$BedrijfOUPath"
    $GroepenOUPath = "OU=Groepen,$BedrijfOUPath"
    $ServerOUPath = "OU=Servers,$BedrijfOUPath"
    $WerkstationOUPath = "OU=Werkstations,$BedrijfOUPath"

    Node localhost
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature DNS {
            Ensure = "Present"
            Name   = "DNS"
        }

        Script EnableDNSDiags {
            SetScript  = {
                Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics"
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = "[WindowsFeature]DNS"
        }

        WindowsFeature DnsTools {
            Ensure    = "Present"
            Name      = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
        }

        WindowsFeature 'ADDS' {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }

        WindowsFeature ADDSTools {
            Ensure = "Present"
            Name   = "RSAT-ADDS"
        }
    
        WindowsFeature 'RSAT' {
            Name   = 'RSAT-AD-PowerShell'
            Ensure = 'Present'
        }

        DnsServerAddress DnsServerAddress {
            Address        = '127.0.0.1'
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn      = "[WindowsFeature]DNS"
        }
    
        WaitForDisk Disk2 {
            DiskId           = 2
            RetryIntervalSec = $RetryIntervalSec
            RetryCount       = $RetryCount
        }
    
        Disk ADDataDisk {
            DiskId      = 2
            DriveLetter = "F"
            DependsOn   = "[WaitForDisk]Disk2"
        }

        ADDomain $DomainName {
            DomainName                    = $DomainName
            Credential                    = $admincreds
            SafemodeAdministratorPassword = $DSRMCreds
            ForestMode                    = 'WinThreshold'
            DomainMode                    = 'WinThreshold'
            DatabasePath                  = "F:\NTDS"
            LogPath                       = "F:\NTDS"
            SysvolPath                    = "F:\SYSVOL"
            DependsOn                     = @("[WindowsFeature]ADDS", "[Disk]ADDataDisk")
        }

        PendingReboot AfterDomainInstall {
            Name = 'AfterDomainInstall'
        }

        Registry DisableCEIP {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\Microsoft\SQMClient\Windows'
            ValueName = 'CEIPEnable'
            ValueData = '0'
            ValueType = 'DWord'
        }

            
        ADOrganizationalUnit RootOUPath {
            Name   = $customerName
            Path   = $RootOUPath
            Ensure = "Present"
        }

        foreach ($BedrijfOU in $BedrijfOUs) {
            ADOrganizationalUnit $BedrijfOU {
                Ensure = "Present"
                Name   = $BedrijfOU
                Path   = $BedrijfOUPath
            }
        }

        foreach ($GebruikerOU in $GebruikerOUs) {
            ADOrganizationalUnit $GebruikerOU {
                Ensure = "Present"
                Name   = $GebruikerOU
                Path   = $GebruikersOUPath
            }
        }

        foreach ($GroepenOU in $GroepenOUs) {
            ADOrganizationalUnit $GroepenOU {
                Ensure = "Present"
                Name   = $GroepenOU
                Path   = $GroepenOUPath
            }
        }

        foreach ($ServerOU in $ServerOUs) {
            ADOrganizationalUnit $ServerOU {
                Ensure = "Present"
                Name   = $ServerOU
                Path   = $ServerOUPath
            }
        }

        foreach ($WerkstationOU in $WerkstationOUs) {
            ADOrganizationalUnit $WerkstationOU {
                Ensure = "Present"
                Name   = $WerkstationOU
                Path   = $WerkstationOUPath
            }
        }


        File CentralStoreEN {
            DestinationPath = "C:\Windows\SYSVOL\sysvol\$($DomainName)\Policies\PolicyDefinitions\en-US"
            Type            = "Directory"
            Ensure          = "Present"
        }

        File ADMXFiles {
            SourcePath      = "C:\Windows\PolicyDefinitions\"
            DestinationPath = "C:\Windows\SYSVOL\sysvol\$($DomainName)\Policies\PolicyDefinitions"
            Type            = "Directory"
            Recurse         = $true
            Ensure          = "Present"
        }

        ADGroup APPL_OFFICE {
            GroupName   = "APPL_OFFICE"
            GroupScope  = "Global"
            DisplayName = "APPL_OFFICE"
            Path        = "OU=Applicatie Groepen,$($GroepenOUPath)"
            Ensure      = "Present"
        }
    
        # Create APPL_SSLVPN_customerCode group
        ADGroup APPL_SSLVPN_customerCode {
            GroupName   = "APPL_SSLVPN_$customerCode"
            GroupScope  = "Universal"
            DisplayName = "APPL_SSLVPN_$customerCode"
            Path        = "OU=Applicatie Groepen,$($GroepenOUPath)"
            Ensure      = "Present"
        }

        ADUser TestNeh {
            Ensure               = 'Present'
            UserName             = $TestAccountCreds.Username
            DisplayName          = 'Test Account NEH'
            DomainName           = $DomainName
            CannotChangePassword = $true
            PasswordNeverExpires = $true
            Enabled              = $true
            Path                 = "OU=Test OU,$GebruikersOUPath"
            GivenName            = 'Test Account'
            Surname              = 'NEH'
            Description          = 'Test Account NEH'
            Password             = $TestAccountCreds
            PSDSCRunasCredential = $admincreds
        }

        ADUser SvcAADSUser {
            Ensure               = 'Present'
            UserName             = $ADConnectAccountCreds.Username
            DisplayName          = 'Service Account Azure ADSync'
            DomainName           = $DomainName
            CannotChangePassword = $true
            PasswordNeverExpires = $true
            Enabled              = $true
            Path                 = "OU=Service Accounts,$BedrijfOUPath"
            GivenName            = 'Service Account'
            Surname              = 'AADS'
            Description          = 'Service Account AADS (NOOIT UITSCHAKELEN!)'
            Password             = $ADConnectAccountCreds
            PSDSCRunasCredential = $admincreds
        }

        TimeZone Timezone {
            TimeZone         = 'W. Europe Standard Time'
            IsSingleInstance = 'Yes'
        }

        Script NtpServer {
            SetScript  = {
                $reg = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters -Name ntpserver
                If ($reg.ntpserver -ne 'nl.pool.ntp.org') {
                    w32tm /config /manualpeerlist:'nl.pool.ntp.org' /syncfromflags:manual
                    w32tm /config /update
                    w32tm /resync
                }
            }
            TestScript = {
                $reg = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters -Name ntpserver
                return $reg.ntpserver -eq 'nl.pool.ntp.org'
            }
            GetScript  = { return @{} }
        }

    }

}

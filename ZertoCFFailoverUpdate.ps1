<#########################################################
Zerto Post-Failover Script to change public DNS A Records

Written by Justin Paul, Zerto Tech Alliance Architect

This script can be used to change A Record IP addresses
after server does a failover to a a different site.

This script requires the PoshSecurity.com CloudFlare modules
https://github.com/poshsecurity/Posh-CloudFlare

##########################################################>
Import-Module -Name .\Posh-CloudFlare.psd1

<# Cloud Flare Client Details #>

$CloudFlareAPIToken     = 'API-Token'
$CloudFlareEmailAddress = 'me@myco.com'

<# Array of server's that need to be updated #>

$ServersToUpdate = 
@(
[pscustomobject]@{fqdn="server1.mydomain.com";NewIp="1.1.1.1"},
[pscustomobject]@{fqdn="server2.mydomain.com";NewIp="2.2.2.2"}
)

function CFUpdateRecords
{
    foreach ($items in $ServersToUpdate)
    {
        # Build Variables
        $fqdn = $items.fqdn
        $fqdn = $fqdn.split(".")

        $CloudFlareDomain = $fqdn[1] + "." + $fqdn[2]

        $CFHost = $fqdn[0]

        $content = $items.NewIp

        # Execute API call
        Update-CFDNSRecord -APIToken $CloudFlareAPIToken -Email $CloudFlareEmailAddress -Zone $CloudFlareDomain -EnableCloudFlare -Name $CFHost -Content $content -Type A
 
    }
}

#Get Zerto Operation from Zerto Virtual Manager
$Operation = $env:ZertoOperation

#Uncomment the line below if you want to manually run the script for testing
#$Operation = "MoveBeforeCommit"

$VPG = $env:ZertoVPGName
$time = Get-Date
 
#If Zerto Operation is a Test Quit!
if ($Operation -eq "Test") {
    "$time VPG: $VPG was tested." >> "C:\DR_IPChange_Log.txt"
    Exit
}
 
#If Zerto Operation is "REAL" meaning Failover or Move, Execute the IP change function

if ($Operation -eq "FailoverBeforeCommit") {
    "$time Failover before commit was performed. VPG: $VPG" >> "C:\DR_IPChange_Log.txt"
    #Run the function
    CFUpdateRecords
}
 
if ($Operation -eq "MoveBeforeCommit"){
    "$time Move before commit was performed. VPG: $VPG" >> "C:\DR_IPChange_Log.txt"
    #Run the function
    CFUpdateRecords
}
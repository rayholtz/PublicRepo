<#
    This script updates the IP Address in a DNS entry
    This script was written by Ray Holtz on 6/12/2019
#>

$HostName = Read-Host -Prompt "Host to update IP for?"
$ZoneName = Read-Host -Prompt "What zone to modify record in? (domain name)"

do {
    $NewIP = Read-Host -Prompt "What IP address to change to?"

    try {
        [IPAddress] $NewIP > $null 2>&1
        $r = 1
    }
    catch {
        Write-Host "That was not a vaild IP address.  Please Try Again" -BackgroundColor DarkYellow -ForegroundColor DarkRed
        $r = 0
    }

} until ( $r -eq "1" )


#$NewObj = Get-DnsServerResourceRecord -Name $HostNAme -ZoneName $ZoneName -RRType "A"
#$OldObj = Get-DnsServerResourceRecord -Name $HostNAme -ZoneName $ZoneName -RRType "A"
#$NewObj.RecordData  = $ipaddress

#$NewObj.TimeToLive = [System.TimeSpan]::FromHours(2)

$NewObj.RecordData.ipv4address=[System.Net.IPAddress]::parse($NewIP)
Set-DnsServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName $ZoneName -PassThru


Write-host "$HostName.$ZoneName is now $NewIP"








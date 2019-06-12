<#
    This script updates the IP Address in a DNS entry
    This script was written by Ray Holtz on 6/12/2019
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$HostName,
    [Parameter(Mandatory = $true)]
    [string]$ZoneName,    
    [Parameter(Mandatory = $true)]
    [string]$DNSserver,    
    [Parameter(Mandatory = $true)]
    [string]$NewIP
)

<#
$HostName = Read-Host -Prompt "Host to update IP for?"
$ZoneName = Read-Host -Prompt "What zone to modify record in? (domain name)"
$DNSserver = Read-Host -Prompt "Which DNS Server should this change be made on?"
#>
$pattern = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"

do {
#   $NewIP = Read-Host -Prompt "What IP address to change to?"
    if ($NewIP -match $pattern) {
        $r = 1
    } else {
        Write-Host "That was not a vaild IP address.  Please Try Again" -BackgroundColor DarkYellow -ForegroundColor DarkRed
        $r = 0
        $NewIP = Read-Host -Prompt "What IP address to change to?"
    }

} until ( $r -eq "1" )

$NewObj = Get-DnsServerResourceRecord -Name $HostName -ZoneName $ZoneName -RRType "A" -ComputerName $DNSserver
$OldObj = Get-DnsServerResourceRecord -Name $HostName -ZoneName $ZoneName -RRType "A" -ComputerName $DNSserver

#$NewObj.TimeToLive = [System.TimeSpan]::FromHours(2)

$NewObj.RecordData.ipv4address=[System.Net.IPAddress]::parse($NewIP)
Set-DnsServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName $ZoneName -PassThru -ComputerName $DNSserver

#$NewObj|Format-List
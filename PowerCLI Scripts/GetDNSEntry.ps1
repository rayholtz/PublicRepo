<#
    This script was written by Ray Holtz
    It is a quick, easy way to query DNS so you don't have to wait for
      the DNS GUI to load or refresh.
#>



param (
    [String]$IP,
    [String]$Hostname,
    [String]$Zone,
    [String]$Computername="<dnsserver>"
)

import-module dnsserver

If (!$IP -and !$Hostname) {
    
    Write-Warning "There is no -IP or -Hostname defined, please pass one of these as an Parameter"
    Write-Warning "Quitting..."
    exit
}

If (!$Zone) {
    
    Write-Warning "Thee is no -Zone defined, please enter this as a Parameter"
    Write-Warning "Quitting..."
    exit
}

$rrzone = Get-DnsServerResourceRecord -ComputerName $Computername -ZoneName $Zone

#write-host "$Hostname.$Zone"

If (!$IP) {

#    Write-Host "No IP entered, running check on Hostname"
    $rrzone | Where-Object {$_.hostname -like "*$Hostname*"}

}
Else {

#    Write-Host "No Hostname entered, running check on IP"
    $rrzone | Where-Object {$_.RecordData.ipv4address -eq "$IP"}

}


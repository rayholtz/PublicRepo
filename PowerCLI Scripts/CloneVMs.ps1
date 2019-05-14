<# CloneVM.ps1
	Creates a new VM based on a template and Customization of your choosing.
    This script was written by Ray Holtz on 10/30/2014
    It was updated on 2/26/2018 to be less specific to the template, and take more paramaters
    It was updated to v3 on 5/14/2018. the script initially creates the drives in the 'Template_03' datastore then Storage vMotions the VMDKs to the proper datastores
    It was updated on 5/14/2019 to make vCenterSvr,SubnetMask,DNSservers and Gateway variables more generic, and post to Github.
#>

Param(
	[Parameter(Position=0,Mandatory=$True)]
    [STRING]$FileName,
    [Parameter(Position=1,Mandatory=$True)]
    [String]$vCenterSvr,
    [Parameter(Position=2)]
    [STRING]$Template,
    [Parameter(Position=3)]
    [STRING]$GuestCustomization 
)


$SubnetMask = "x.x.x.x"
$DNSservers = @("y.y.y.y","z.z.z.z")

Write-Host "Importing VMWare PowerCLI Modules"
Import-Module vmware.vimautomation.core

Write-Host "Connecting to $vCenterSvr"
try {
    Connect-VIServer $vCenterSvr
}
catch {
    Write-Error "Could not connect to vCenter Server.  Try again."
    exit 
}

While (!$Template) {
    $VMList = Get-VM -Name "*tplt"
    $TpltList= Get-Template -Name "*tplt"
    $VMList + $TpltList | Sort-Object | Select-Object @{N="Templates";E={@($_.Name)}} | Out-String
    Write-Host "Which Template do you want to use? " -foregroundColor Yellow -nonewline
    $Template = Read-Host 

}

while (!$GuestCustomization) {
    Get-OSCustomizationSpec | Sort-Object Name | Select-Object Name,Description | Out-String
    Write-Host "Which Guest Customization do you want to use? " -foregroundcolor Yellow -nonewline
    $GuestCustomization = Read-Host 
}

#VMware Credentials

#$secpasswd = ConvertTo-SecureString "^MW@r3svc" -AsPlainText -Force
#$VMcreds = New-Object System.Management.Automation.PSCredential ("vmwaresvc", $secpasswd)

## Imports CSV file and runs through building the VM(s)
Import-Csv $filename -UseCulture | ForEach-Object{

    $time = get-date
    Write-Host "Started deploying $($_.VMName) at" $time
    Write-Host ""
    Write-Host ""

    <# Definitions of the variables in the CSV File
    $_.VMName is the VMname.
    $_.DestHost	is the Destination host to build the VM on.
    $_.NumCPU is the number of CPUs.
    $_.VMMem is the memory in the VM.
    $_.DSos is the Datastore for the OS drive * VM files.
    $_.DSPage is for the PageFile Volume.
    $_.DSData is for the Data Volume(s).
    $_.EDriveSize is the size of the D Drive in GB.
    $_.FDriveSize is the size of the F Drive in GB.
    $_.IPAddr is the IP Address to assign to the VM.
    #>

    # Modify the OSCustomization for the IP Address 

    Write-Host "Editing the CustomizationSpec for $($_.VMName)"
    $cs = Set-OSCustomizationSpec -OSCustomizationSpec $GuestCustomization

    $IPByte = $($_.IPAddr).split(".")
    $Gateway = ($IPByte[0]+"."+$IPByte[1]+"."+$IPByte[2]+".4")

    $cs | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $_.IPaddr -SubnetMask $SubnetMask -DefaultGateway $Gateway -Dns $DNSservers

    Write-Host "Cloning the template for $($_.VMName)"
    # Create the VM based on a template
    New-VM -VM $Template -Name $_.VMName -VMHost $_.DestHost -Datastore Template_03 -OSCustomizationSpec $cs -Confirm:$false 

    Write-Host "Editing Memory and CPU of $($_.VMName)"
    # Modify the Memory and CPU of the VM
    Set-VM -VM $_.VMName -MemoryGB $_.VMMem -NumCpu $_.VMCpu -Confirm:$false

    if ($Template = "W2016-Vis9-Tplt") {
        # Do Nothing
    }
    else {

        Write-Host "Adding Drive E: to $($_.VMName)"
        # Check to see if EDriveSize is NOT NULL,  then add a E Drive for Data if needed
        If($_.EDriveSize) {
            New-HardDisk -VM $_.VMName -CapacityGB $_.EDriveSize -Datastore $_.DSData -StorageFormat Thin -Confirm:$false
        }
        Else{
            Write-Host "There is no E: Drive to add"
        }

        Write-Host "Adding Drive F: to $($_.VMName)"
        # Check to see if FDriveSize is NOT NULL,  then add a F Drive for Data if needed
        If($_.FDriveSize) {
            New-HardDisk -VM $_.VMName -CapacityGB $_.FDriveSize -Datastore $_.DSData -StorageFormat Thin -Confirm:$false
        }
        Else{
            Write-Host "There is no F: Drive to add"
        }
    }

    Write-Host "Powering on $($_.VMName)"
    # Power on the VM
    Start-VM -VM $_.VMName
    Open-VMConsoleWindow $_.VMName

    Write-Host "Migrating the OS Drive for $($_.VMName)"
    # Migrate the OS Drive to the OS Datastore
    $OSVol = $_.DSos
    Get-HardDisk -vm $_.VMName | Where-Object {$_.Name -eq "Hard disk 1"} | ForEach-Object {Move-HardDisk -harddisk $_ -Datastore $OSVol -Storageformat Thin -Confirm:$false -RunAsync}

    Write-Host "Migrating the PageFile for $($_.VMName)"
    # Migrate the Pagefile Drive to the Pagefile Datastore
    $PageVol = $_.DSPage
    Get-HardDisk -vm $_.VMName | Where-Object {$_.Name -eq "Hard disk 2"} | ForEach-Object {Move-HardDisk -harddisk $_ -Datastore $PageVol -Storageformat Thin -Confirm:$false -RunAsync}

        # Manage E: or F: drives
    if ($Template = "W2016-Vis9-Tplt") {
        Write-Host "Migrating the Data Drive for $($_.VMName)"
        # Migrate the Data Drive to the Data Datastore
        $DataVol = $_.DSData
        Get-HardDisk -vm $_.VMName | Where-Object {$_.Name -eq "Hard disk 3"} | ForEach-Object {Move-HardDisk -harddisk $_ -Datastore $DataVol -Storageformat Thin -Confirm:$false -RunAsync}
    }
    
    $time = get-date
    Write-Host "Completed deploying $($_.VMName) at" $time
    Write-Host ""
    Write-Host ""

    Write-Host -ForegroundColor Cyan "Close and reopen PowerCLI to run another Clone Process"
        # close and open based on comment #6 on https://communities.vmware.com/thread/443716?start=0&tstart=0
}

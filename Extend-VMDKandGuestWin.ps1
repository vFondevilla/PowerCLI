## Script for extending the VMDK and guest filesystem in Windows 2012R2

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string]$vcenter,
    [Parameter(Mandatory=$True)]
    [String]$target,
    [string]$username,
    [string]$password
)

#If anything fails, we want to stop the Script
$ErrorActionPreference = "Stop"

# We'll load the snap-in or module ( Thx to Chris Wahl for the base code! http://wahlnetwork.com/2015/04/13/powercli-modules-snapins/)
$powercli = Get-PSSnapin VMware.VimAutomation.Core -Registered

if ( (Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null) {
    try
    {
    switch ($powercli.Version.Major)
        {
        {$_ -ge 6}
            {
            Import-Module VMware.VimAutomation.Core -ErrorAction Stop
            Write-Host "PowerCLI 6+ module imported"
            }
        5
            {
            Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop
            Write-Host "PowerCLI 5 snapin added; recommend upgrading your PowerCLI version"
            }
        default {throw "This script requires PowerCLI version 5 or later"}
        }
    }
catch {throw "Could not load the required VMware.VimAutomation.Core cmdlets"}
}


## If creds not provided, a popUp will appear asking for them
if ($username -eq $null -or $password -eq $null) {
    connect-viserver $vcenter   
}
else {
    connect-viserver $vcenter -user $username -password $password
}

Write-Output "Connected to $vcenter"

Write-Output "Retrieving VM $target"
$VM = get-VM $target

Write-Output "Actual stats of VM $target"
$VM | get-HardDisk | FT Parent, Name, CapacityGB -Autosize

$disk = Read-Host "Select VMDK disk you want to extend (enter only numbers):"
$disk = "Hard Disk " + $disk
$DiskSize = Read-Host "Enter new VMDK size:"

$volume = Read-Host "Select Guest Volume you want to extend (enter only single letter):"

$guestUser = Read-Host "Put administrative creds (local administrator)"
$GuestPassword = Read-Host "Put Administrative password"
$GuestPassword = ConvertTo-SecureString $GuestPassword -AsplainText -Force

write-output $guestUser $GuestPassword $DiskSize $volume
write-output "echo rescan > C:\diskpart.txt && ECHO SELECT Volume $volume >> C:\DiskPart.txt && ECHO EXTEND >> C:\DiskPart.txt && ECHO EXIT >> C:\DiskPart.txt && DiskPart.exe /s C:\DiskPart.txt && DEL C:\DiskPart.txt /Q"

get-HardDisk -vm $target | where { $_.Name -eq $disk} | Set-HardDisk -CapacityGB $DiskSize -Confirm:$false
#get-HardDisk -vm $target | where { $_.Name -eq $disk} | Set-HardDisk -CapacityGB $DiskSize -Confirm:$false
Invoke-VMScript -vm $target -ScriptText "echo rescan > C:\diskpart.txt && ECHO SELECT Volume $volume >> C:\DiskPart.txt && ECHO EXTEND >> C:\DiskPart.txt && ECHO EXIT >> C:\DiskPart.txt && DiskPart.exe /s C:\DiskPart.txt && DEL C:\DiskPart.txt /Q" -ScriptType BAT -GuestUser $GuestUser -GuestPassword $GuestPassword



Disconnect-viserver -confirm:$false
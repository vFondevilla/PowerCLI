<#
 
.SYNOPSIS
Scripting de las CPUs y sockets para Presence. Por el documento de requerimientos, no se puede hacer oversubscribing de CPU y los servidores
de VMware tendrían que ser dedicados a Presence.
Este script no tiene en cuenta resource pools ni clusters y debería apuntarse contra hosts sueltos.
El código está basado en el trabajo de Alan Renouf y su vCheck (http://www.virtu-al.net/vcheck-pluginsheaders/vcheck/)

CODE BASED ON ALAN RENOUF'S VCHECK (http://www.virtu-al.net/vcheck-pluginsheaders/vcheck/)
 
.EXAMPLE
./overprovisioning.ps1 1.2.3.4 root P@ssw0rd!

.NOTES
    Version:        2.0
    Author:         Victor Fondevilla
    Creation date:  29/10/2015
    Change:         Reescritura del código
 
#>

[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True)]
	[String]$target,
    [string]$username,
    [string]$password
)
$ErrorActionPreference = "Stop"


## If creds not provided, a popUp will appear asking for them
if ($username -eq $null -or $password -eq $null) {
    connect-viserver $target    
}
else {
    connect-viserver $target -user $username -password $password
}

# Get VM & Threads
$VM = get-vm
$VMH = VMHost $target
$HTActive = $VMH.HyperthreadingActive
$cpu = $VMH.NumCpu

if ($HTActive -eq "True") {
    $Threads = $cpu * 2
}
else {
    $Threads = $cpu
}


$Info = New-Object -TypeName PSObject -Property @{
    "Active VMs" = $VM.count
    "vCPU Ratio" = $vCPUpCPUratio = [math]::round(($VM|Measure-Object -Sum -Property NumCpu).sum / $Threads,0)
}

Write-Output $Info

disconnect-viserver -confirm:$false


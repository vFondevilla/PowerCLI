Param(
	[Parameter(Mandatoty=$true)]
	[string]$target,
	[Parameter(Mandatoty=$true)]
	[string]$busca)

$ErrorActionPreference = "Stop"

connect-viserver $target

$allvms = get-vm $busca 
foreach ($vm in $allvms) {
	$vmtest = Get-vm $vm| get-view
	$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

	#disable ctk
	$vmConfigSpec.changeTrackingEnabled = $false
	$vmtest.reconfigVM($vmConfigSpec)
	$snap=New-Snapshot $vm -Name "Disable CBT"
	$snap | Remove-Snapshot -confirm:$false

	# enable ctk
	$vmConfigSpec.changeTrackingEnabled = $true
	$vmtest.reconfigVM($vmConfigSpec)
	$snap=New-Snapshot $vm -Name "Enable CBT"
	$snap | Remove-Snapshot -confirm:$false
}
 

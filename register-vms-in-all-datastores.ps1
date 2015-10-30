Param(
  [Parameter(Mandatory=$true)]
  [string]$host
)

foreach($Datastore in Get-Datastore *) {
   # Set up Search for .VMX Files in Datastore
   $ds = Get-Datastore -Name $Datastore | %{Get-View $_.Id}
   $SearchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
   $SearchSpec.matchpattern = "*.vmx"
   $dsBrowser = Get-View $ds.browser
   $DatastorePath = "[" + $ds.Summary.Name + "]"

   # Find all .VMX file paths in Datastore, filtering out ones with .snapshot (Useful for NetApp NFS)
   $SearchResult = $dsBrowser.SearchDatastoreSubFolders($DatastorePath, $SearchSpec) | where {$_.FolderPath -notmatch ".snapshot"} | %{$_.FolderPath + ($_.File | select Path).Path}

   #Register all .vmx Files as VMs on the datastore
   foreach($VMXFile in $SearchResult) {
      New-VM -VMFilePath $VMXFile -VMHost $host -RunAsync
   }
}

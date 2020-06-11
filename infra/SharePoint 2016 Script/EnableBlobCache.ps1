Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Get the Web Application
$WebApp = Get-SPWebApplication "https://sp"
 
#Create a web.config modification
$WebconfigMod = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
$WebconfigMod.Path = "configuration/SharePoint/BlobCache"
$WebconfigMod.Name = "enabled"
$WebconfigMod.Sequence = 0
$WebconfigMod.Owner = "BlobCacheModification"
$WebconfigMod.Type = 1
$WebconfigMod.Value = "true"
    
#Apply the web.config change
$WebApp.WebConfigModifications.Add($WebconfigMod)
$WebApp.Update()
$WebApp.Parent.ApplyWebConfigModifications()
iisreset
# Add Snap-in Microsoft.SharePoint.PowerShell if not already loaded, continue if it already has been loaded
Add-PsSnapin "Microsoft.SharePoint.PowerShell" -EA 0
 
#Variables
$AppPoolAccount = "hk\SP_PortalAppPool" #The Application Pool domain account, must already be created as a SharePoint managed account
$AppPoolPassword = ConvertTo-SecureString '211276Hsn' -AsPlainText -Force
$ApplicationPoolName = "SharePoint 80 AppPool" #This will create a new Application Pool
$ContentDatabase = "SP_ContentDB" #Content DB
$DatabaseServer = "spsql01" #Alias of your DB Server
$WebApp = "http://sp" #The name of your new Web Application
$HostHeader = "sp" #The IIS host header
$Url = $WebApp
$Description = "SharePoint 2016 Site"
$IISPath = "C:\inetpub\wwwroot\wss\VirtualDirectories\80" #The path to IIS directory
$SiteCollectionTemplate = "STS#0"
$SiteCollAdmin = "domain\user"


#SUPER USER ACCOUNT - Use your own Account (NB: NOT A SHAREPOINT ADMIN)
$sOrigUser= "hk\SP_SuperUser"
$sUserName = "SP_SuperUser"

#SUPER READER ACCOUNT - Use your own Account (NB: NOT A SHAREPOINT ADMIN)
$sOrigRead = "hk\SP_SuperReader"
$sReadName = "SP_SuperReader"

#Get App Pool account
$AppPoolAccount = Get-SPManagedAccount -Identity $AppPoolUserName -ErrorAction Continue
if($null -eq $AppPoolAccount)
{
   $AppPoolAccount = New-Object system.management.automation.pscredential $AppPoolAccount, $AppPoolPassword
   New-SPManagedAccount $AppPoolAccount
}

$AppPoolAccount = Get-SPManagedAccount -Identity $AppPoolUserName -EA 0

New-SPWebApplication -ApplicationPool $ApplicationPoolName `
                     -ApplicationPoolAccount $AppPoolAccount `
                     -Name $Description `
                     -AuthenticationProvider (New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication) `
                     -DatabaseName $ContentDatabase `
                     -DatabaseServer $DatabaseServer `
                     -HostHeader $HostHeader `
                     -Path $IISPath `
                     -Port 80 `
                     -URL $Url

#Create Site Collection
New-SPSite -Url $Url `
           -OwnerAlias "i:0#.w|$SiteCollAdmin" `
           -OwnerEmail "user@contoso.com" `
           -ContentDatabase $ContentDatabase `
           -Description $Description `
           -Name $Description `
           -Template $SiteCollectionTemplate

####SET ACCOUNT NAMES (Replace Domain and UserName)




$apps = get-spwebapplication
foreach ($app in $apps) {
   #DISPLAY THE URL IT IS BUSY WITH
   $app.Url
   if ($app.UseClaimsAuthentication -eq $true)
   {
    # IF CLAIMS THEN SET THE IDENTIFIER
    $sUser = "i:0#.w|" + $sOrigUser
    $sRead = "i:0#.w|" + $sOrigRead
   }
   else
   {
   # CLASSIC AUTH USED
     $sUser = $sOrigUser
     $sRead = $sOrigRead
   }
  
   # ADD THE SUPER USER ACC - FULL CONTROL (Required for writing the Cache)
   $policy = $app.Policies.Add($sUser, $sUserName)
   $policyRole = $app.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)
   $policy.PolicyRoleBindings.Add($policyRole)

   $app.Properties["portalsuperuseraccount"] = $sUser
   $app.Update()

   # ADD THE SUPER READER ACC - READ ONLY
   $policy = $app.Policies.Add($sRead, $sReadName)
   $policyRole = $app.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead)
   $policy.PolicyRoleBindings.Add($policyRole)

   $app.Properties["portalsuperreaderaccount"] = $sRead
   $app.Update()

 }

 iisreset
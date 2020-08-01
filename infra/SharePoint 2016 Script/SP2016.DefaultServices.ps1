if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
{
    #Add SharePoint PowerShell Commands
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

#Variables
$DatabaseServerName = (Get-SPDatabase | Where-Object { $_.Type -eq "Configuration Database" }).NormalizedDataSource
$AppPoolName = "Default SharePoint Service App Pool"
$AppPoolUserName = "domain\SP_Services"
$AppPoolPassword = ConvertTo-SecureString 'Parola!!!' -AsPlainText -Force
$ULSLogsFolder = "C:\SPLogs\ULS\"


$MetaDataName = "Manage Metadata Service"
$MetaDataDBName = "SP_MetadataDB"

$WordASName = "Word Automation Service Application"
$WordAutomationDatabaseName = "SP_WordAutoDB"

$BDCServiceName = "Business Data Connection Service Application"
$BDCDB = "SP_BusinessDataConnectionDB"

$SecureStoreName = "Secure Store Service Application"
$SecureStoreProxyName ="Secure Store Service Application Proxy"
$SecureStoreDB = "SP_SecureStoreDB"

$usageName = "Usage and Health Data Collection Service"
$usageServiceDB = "SP_Usage_HealthDB"
$usageLogLocationOnDisk = $ULSLogsFolder
$stateName = "State Service"
$stateServiceDB = "SP_StateServiceDB"

$MTSInst = "Machine Translation Service"
$MTSName = "Translation Service"
$MTSDB = "SP_MachineTranslationDB"

$AppDomain = "domainapps.com"

$SubSettingsName = "Subscription Settings Service"
$SubSettingsDB = "SP_SubscriptionSettingsDB"
$AppManagementName = "App Management Service"
$AppManagementNameProxy = "App Management Service Proxy"
$AppManagementDB = "SP_AppManagementDB"

#Script

#Check if Service account exist and Create.
Write-Host "Getting Service Account / Creating Service Account"
$SAAppPool = Get-SPServiceApplicationPool -Identity $AppPoolName -EA 0

if($SAAppPool -eq $null)
{
 #Get App Pool account
 $AppPoolAccount = Get-SPManagedAccount -Identity $AppPoolUserName -ErrorAction Continue
 if($AppPoolAccount -eq $null)
 {
    $AppPoolAccount = New-Object system.management.automation.pscredential $AppPoolUserName, $AppPoolPassword
    New-SPManagedAccount $AppPoolAccount
 }
 $AppPoolAccount = Get-SPManagedAccount -Identity $AppPoolUserName -EA 0

 if($AppPoolAccount -eq $null)
 {
   Write-Host "Cannot create or find the managed account $appPoolUserName, please ensure the account exists."
   Exit -1
 }

 New-SPServiceApplicationPool -Name $AppPoolName -Account $AppPoolAccount -ErrorAction Continue > $null
}

#Create Manage Metadata Service
Write-host "Creating Manage Metadata Service"
New-SPMetadataServiceApplication -Name $MetaDataName –ApplicationPool $AppPoolName -DatabaseServer $DatabaseServerName -DatabaseName $MetaDataDBName > $null
New-SPMetadataServiceApplicationProxy -Name "$MetaDataName Proxy" -DefaultProxyGroup -ServiceApplication $MetaDataName > $null
#Start MMS
Get-SPServiceInstance | where-object {$_.TypeName -eq "Managed Metadata Web Service"} | Start-SPServiceInstance > $null

#Word Automation Service
Write-Host "Create Word Automation Service"
Get-SPServiceApplicationPool –Identity $AppPoolName | New-SPWordConversionServiceApplication -Name $WordASName -DatabaseName $WordAutomationDatabaseName

#BDC
write-Host "Create BDC" 
New-SPBusinessDataCatalogServiceApplication –ApplicationPool $AppPoolName –DatabaseName $BDCDB –DatabaseServer $DatabaseServerName –Name $BDCServiceName

#Secure Store and Proxy
write-Host "Create Store and Proxy"
$SecureStoreServiceApp = New-SPSecureStoreServiceApplication –ApplicationPool $AppPoolName –AuditingEnabled:$false –DatabaseServer $DatabaseServerName –DatabaseName $SecureStoreDB –Name $SecureStoreName
New-SPSecureStoreServiceApplicationProxy –Name $SecureStoreProxyName –ServiceApplication $SecureStoreServiceApp -DefaultProxyGroup

#Usage and HEalth Data Collection service
## Begin Variables for usage and health data collection and state service, make sure the C:\Logs\ULS location exists first ##
write-host "Create Usage and Health"
#Change location
Set-SPUsageService -LoggingEnabled 1 -UsageLogLocation $usageLogLocationOnDisk -UsageLogMaxSpaceGB 2
$serviceInstance = Get-SPUsageService
New-SPUsageApplication -Name $usageName -DatabaseServer $DatabaseServerName -DatabaseName $usageServiceDB -UsageService $serviceInstance > $null
$stateServiceDatabase = New-SPStateServiceDatabase -Name $stateServiceDB
$stateSA = New-SPStateServiceApplication -Name $stateName -Database $stateServiceDatabase
New-SPStateServiceApplicationProxy -ServiceApplication $stateSA -Name "$stateName Proxy" -DefaultProxyGroup
$sap = Get-SPServiceApplicationProxy | where-object {$_.TypeName -eq "Usage and Health Data Collection Proxy"}
$sap.Provision()
#ChangeLocation and create new files.
Set-SPDiagnosticConfig -LogLocation $usageLogLocationOnDisk
New-SPLogFile
New-SPUsageLogFile

#Machine Translation Service + Proxy
write-host "Create Machine Translation Service and Proxy"
$AppPool = Get-SPServiceApplicationPool $AppPoolName
Get-SPServiceInstance | Where-Object {$_.GetType().Name -eq $MTSInst} | Start-SPServiceInstance
$MTS = New-SPTranslationServiceApplication -Name $MTSName -ApplicationPool $AppPool -DatabaseName $MTSDB
New-SPTranslationServiceApplicationProxy –Name "$MTSName Proxy" –ServiceApplication $MTS –DefaultProxyGroup

$SubSvc = New-SPSubscriptionSettingsServiceApplication –ApplicationPool $AppPoolName –Name $SubSettingsName –DatabaseName $SubSettingsDB
New-SPSubscriptionSettingsServiceApplicationProxy –ServiceApplication $SubSvc

Get-SPServiceInstance | Where-object {$_.TypeName -eq $SubSettingsName} | Start-SPServiceInstance > $null

$AppManagement = New-SPAppManagementServiceApplication -Name $AppManagementName -DatabaseServer $DatabaseServerName -DatabaseName $AppManagementDB –ApplicationPool $AppPoolName
New-SPAppManagementServiceApplicationProxy -ServiceApplication $AppManagement -Name $AppManagementNameProxy

Get-SPServiceInstance | where-object {$_.TypeName -eq $AppManagementName} | Start-SPServiceInstance > $null
Set-SPAppDomain $AppDomain
Set-SPAppSiteSubscriptionName -Name "apps" -Confirm:$false 

###################################################

$farm = Get-SPFarm
$cacheService = $farm.Services | Where {$_.Name -eq "AppFabricCachingService"}
$cacheService.ProcessIdentity.CurrentIdentityType = “SpecificUser”
$cacheService.ProcessIdentity.ManagedAccount = $AppPoolAccount
$cacheService.ProcessIdentity.Update()
$cacheService.ProcessIdentity.Deploy()

###################################################

write-host "DONE" 

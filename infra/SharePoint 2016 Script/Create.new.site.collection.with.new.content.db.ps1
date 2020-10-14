#Create new site collection with new content database

Add-PsSnapin "Microsoft.SharePoint.PowerShell" -EA 0
$WebApp = "http://sp"
$SiteName = "PortalAdi"
$SiteDescription = "Portal Açıklama"
$SiteUrl = "$WebApp`/sites/$SiteName"
$SiteCollectionTemplate = "STS#0" #Classic Teams Site
$SiteCollAdmin = "domain\user"
$OwnerEmail = "user@domain"
$ContentDatabaseName = "SP_$SiteName`_ContentDB"
$ContentDatabase = New-SPContentDatabase -Name $ContentDatabaseName -WebApplication $WebApp
Set-SPContentDatabase -Identity $ContentDataBaseName -MaxSiteCount 1 -WarningSiteCount 0
#Create Site Collection
New-SPSite -Url $SiteUrl `
           -OwnerAlias "i:0#.w|$SiteCollAdmin" `
           -OwnerEmail $OwnerEmail `
           -ContentDatabase $ContentDatabase `
           -Description $SiteDescription `
           -Name $SiteName `
           -Template $SiteCollectionTemplate
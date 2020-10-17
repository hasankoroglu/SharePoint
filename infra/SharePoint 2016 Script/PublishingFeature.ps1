Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Variables
$SiteURL="http://intranet.crescent.com"
$FeatureName = "PublishingSite"
 
#Check if publishing feature is already activated in the site collection
$Feature = Get-SPFeature -site $siteURL | Where-object {$_.DisplayName -eq $FeatureName}
if($Feature -eq $null)
{    
    #Enable the Publishing feature 
    Enable-SPFeature -Identity $FeatureName -url $SiteURL -Confirm:$False
    
    Write-host "Publishing Feature Activated on $($SiteURL)" -ForegroundColor Green    
}
else
{
    Write-host "Publishing Feature is already Active on $($SiteURL)" -ForegroundColor Red
}

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Variables
$WebURL = $SiteURL
$FeatureName = "PublishingWeb"
 
#Check if publishing feature is already activated in the site 
$Feature = Get-SPFeature -Web $WebURL | Where-object {$_.DisplayName -eq $FeatureName}
if($Feature -eq $null)
{    
    #Enable the Publishing feature 
    Enable-SPFeature -Identity $FeatureName -url $WebURL -Confirm:$False
    
    Write-host "Publishing Feature Activated on $($WebURL)" -ForegroundColor Green    
}
else
{
    Write-host "Publishing Feature is already Active on $($WebURL)" -ForegroundColor Red
}
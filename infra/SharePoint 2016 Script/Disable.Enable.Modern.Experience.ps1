#Site Collection Level
Add-PSSnapin microsoft.sharepoint.powershell -ea 0
$site = Get-SPSite http://spwfe

#Disable modern Lists and libraies at the Site Collection Level
$featureguid = new-object System.Guid “E3540C7D-6BEA-403C-A224-1A12EAFEE4C4”
$site.Features.Add($featureguid, $true)

#Re-enable the moden expirence at the site collection Level.
$featureguid = new-object System.Guid “E3540C7D-6BEA-403C-A224-1A12EAFEE4C4”
$site.Features.Remove($featureguid, $true)
To change disable / re-enable the modern user experience at the web level

#Web Level
Add-PSSnapin microsoft.sharepoint.powershell -ea 0
$site = Get-SPWeb http://spwfe

#Disable modern Lists and libraies at the Web Level.
$featureguid = new-object System.Guid “52E14B6F-B1BB-4969-B89B-C4FAA56745EF”
$site.Features.Add($featureguid, $true)

#Re-enable the moden expirence at the Web Level
$featureguid = new-object System.Guid “52E14B6F-B1BB-4969-B89B-C4FAA56745EF”
$site.Features.Remove($featureguid, $true)
To change disable / re-enable the modern user experience at the library level

Add-PSSnapin microsoft.sharepoint.powershell -ea 0
$web = Get-SPWeb http://spwfe
$list = $web.Lists[“Documents”]

#Classic setting
$list.ListExperienceOptions = “ClassicExperience”
$list.Update()

#Modern setting
$list.ListExperienceOptions = “NewExperience”
$list.Update()

#User Default
$list.ListExperienceOptions = “Auto”
$list.Update()
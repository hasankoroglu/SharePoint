$ServiceApplicationName = "Search Service Application"
$ServerName = (Get-ChildItem env:computername).value
$IndexLocation = "C:\Index"
$DatabaseName = "Search_Service_DB"
$spAppPoolName = "Search Service Application Pool"
$spAppPoolAcc = "domain\SP_SearchService"
$spAppPoolAccPwd = ""
$spContentAccessAcc = "domain\SP_SearchContent"
$spContentAccessPwd = ""
 
Write-Host "SharePoint 2016 - '$ServiceApplicationName'..."
 
Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue | Out-Null
Start-SPAssignment -Global | Out-Null
  
$DatabaseServer = (Get-SPDatabase | Where-Object { $_.Type -eq "Configuration Database" }).NormalizedDataSource
 
try
{
     $ExistingServiceApp = Get-SPServiceApplication | where-object {$_.Name -eq $ServiceApplicationName}

 if ($ExistingServiceApp -eq $null)
    {
       mkdir -Path $IndexLocation -Force | Out-Null

       Write-Host " - Creating '$ServiceApplicationName'"

        write-host " - Starting service instances"
        Start-SPEnterpriseSearchServiceInstance $ServerName
        Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance $ServerName

        $spManagedAccount = Get-SPManagedAccount -Identity $spAppPoolAcc
        $ApplicationPool = Get-SPServiceApplicationPool -Identity $spAppPoolName -ErrorAction SilentlyContinue
        
        if ($spManagedAccount -eq $null)
        {
           $securePassword = ConvertTo-SecureString -String $spAppPoolAccPwd -AsPlainText -Force
           $cred = New-Object System.Management.Automation.PSCredential -ArgumentList $spAppPoolAcc, $securePassword
           New-SPManagedAccount -Credential $cred
        }
        
        $spManagedAccount = Get-SPManagedAccount -Identity $spAppPoolAcc

        if ($ApplicationPool -eq $null)
        {
            New-SPServiceApplicationPool -Name $spAppPoolName -Account $spManagedAccount | Out-Null
        }
        else
        {
            Set-SPServiceApplicationPool $ApplicationPool -Account $spManagedAccount | Out-Null 
        } 
               
        #Search Application 
        Write-Host " - Creating Search Service Application"
        $ServiceApplication = New-SPEnterpriseSearchServiceApplication -Name $ServiceApplicationName -ApplicationPool $spAppPoolName -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName

        #Create proxy
        Write-Host " - Creating '$ServiceApplicationName' proxy"
        New-SPEnterpriseSearchServiceApplicationProxy -Name "$ServiceApplicationName Proxy" -SearchApplication $ServiceApplicationName | Out-Null

        #Get the search instance
        $searchInstance = Get-SPEnterpriseSearchServiceInstance $ServerName
                 
        #Topology
        Write-Host " - Creating new search topology"
        $InitialSearchTopology = $ServiceApplication | Get-SPEnterpriseSearchTopology -Active
        $SearchTopology = $ServiceApplication | New-SPEnterpriseSearchTopology

        #Administration + Processing Components
        Write-Host " - Creating Administration Component"
        New-SPEnterpriseSearchAdminComponent -SearchTopology $SearchTopology -SearchServiceInstance $searchInstance | Out-Null
        Write-Host " - Creating Analytics Processing Component"
        New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchTopology $SearchTopology -SearchServiceInstance $searchInstance | Out-Null
        Write-Host " - Creating Content Processing Component"
        New-SPEnterpriseSearchContentProcessingComponent -SearchTopology $SearchTopology -SearchServiceInstance $searchInstance | Out-Null
        Write-Host " - Creating Query Processing Component"
        New-SPEnterpriseSearchQueryProcessingComponent -SearchTopology $SearchTopology -SearchServiceInstance $searchInstance | Out-Null

        #Crawl

        Write-Host " - Creating Crawl Component"
        New-SPEnterpriseSearchCrawlComponent -SearchTopology $SearchTopology -SearchServiceInstance $searchInstance | Out-Null
                 
        #Index (Query)
        Write-Host " - Creating Query Component"
        #$IndexPartition= 1 #(Get-SPEnterpriseSearchIndexPartition -QueryTopology $SearchTopology)
        New-SPEnterpriseSearchIndexComponent -SearchTopology $SearchTopology -SearchServiceInstance $searchInstance -RootDirectory $IndexLocation | Out-Null #-IndexPartition $IndexPartition 

        #Activates a Search Topology and requires all components attached to a topology
        Write-Host " - Activating new Search Topology"
        $SearchTopology | Set-SPEnterpriseSearchTopology

        try
        {
            $InitialSearchTopology.Synchronize()
        }
        catch { }

        Write-Host " - Waiting for the old crawl topology to become inactive.." -NoNewline

        do { Write-Host -NoNewline .;Start-Sleep 6;} while ($InitialSearchTopology.State -ne "Inactive")
        $InitialSearchTopology | Remove-SPEnterpriseSearchTopology -Confirm:$false
        Write-Host

        #Set Content Access account
        Write-Host " - Setting Content Access Account"
        $c = New-Object Microsoft.Office.Server.Search.Administration.Content($ServiceApplication)
        $c.SetDefaultGatheringAccount($spContentAccessAcc, (ConvertTo-SecureString $spContentAccessPwd -AsPlainText -force))
           
  Write-Host " - Done creating '$ServiceApplicationName'.`n"
 }
 else 
    {
        Write-Host " - Removing '$ServiceApplicationName'..."
        Remove-SPServiceApplication $ExistingServiceApp -removedata -Confirm:$false

        $ExistingServiceAppProxy = Get-SPServiceApplicationProxy | where-object {$_.Name -eq "$ServiceApplicationName Proxy"}
        if ($ExistingServiceAppProxy -ne $null)
        {
            Write-Host " - Removing '$ServiceApplicationName proxy'..."
            Remove-SPServiceApplicationProxy $ExistingServiceAppProxy -Confirm:$false
        }
        Write-Host " - Stopping service instance..."
        Stop-SPEnterpriseSearchServiceInstance $ServerName
        Stop-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance $ServerName

        Remove-Item -Recurse -Force -LiteralPath $IndexLocation -ErrorAction SilentlyContinue
    }
}
catch { write-Output $_ }

Stop-SPAssignment -Global | Out-Null
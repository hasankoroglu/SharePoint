##########################################################################
# Author: Mohamed El-Qassas
# Blog  : blog.devoworx.net
# Date  : 04/22/2017
# Description: PowerShell Script to Configure Project Server 2016
# Detail Steps: 
#  - https://blog.devoworx.net/2015/10/16/install-and-configure-project-server-2016/
#  - https://social.technet.microsoft.com/wiki/contents/articles/37674.project-server-2016-configuration.aspx
#######################################################
#Add Add-PSSnapin Microsoft.SharePoint.PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop
#######################################################
#Variabes Defination
#######################################################
#Project Server Key
$ProjectServerKey           = "" #Project Server Key - trail "Y2WC2-K7NFX-KWCVC-T4Q8P-4RG9W"
#######################################################
#Service Accounts variables
$PSSrvAppPoolAccount        = "domain\SP_PWAAppPool" #A domain user that used to run the associated application pool with Project server service application.
$PSSrvAppPoolPassWord       = "Parola012!" # provide PSSrvAppPool password
#######################################################
#Project Server Application Service variables
$PWAAppServiceAppPool       = "PWA_AppPool" # Project Server Application Service application pool name.
$PWAAppServiceApp           = "Project Server Application Service" # Project Server Application Service
#######################################################
#Web Application variables
$WebAppURL		      	    = "https://intranet.local"
#######################################################
#PWA Instance
$PWAURL                     = $WebAppUrl + "/PWA"
$PWAOwnerAccount            = "domain\SP_Admin" # the owner of PWA site
$PWAContentDataBaseName     = "SP_ContentDB_PWA" 
#######################################################
#Database server
$DBServer                   = "SPSQL" #SQL Server Insance.
#######################################################
#Functions Defination
#######################################################
#Add service account to managed account
function Add-ManagedAccount()
	{
	param ([string]$ServiceAccount,[string]$AccountPassword)
		Try 
		{
			Write-Host "Adding the service Account" $ServiceAccount "to Managed Account" -ForegroundColor Green
			$srvacount = Get-SPManagedAccount | ?  {$_.UserName -eq $ServiceAccount}
			if ($srvacount -eq $null) 
			{ 
				$pass = convertto-securestring $AccountPassword -asplaintext -force
				$cred = new-object management.automation.pscredential $ServiceAccount ,$pass
				$res  = New-SPManagedAccount -Credential $cred
				if ($res -ne $null)
				{
					Write-Host "The" $ServiceAccount "has been added successfully to Managed Account" -ForegroundColor Cyan
				}
			}
			else 
			{
				Write-Host "The" $ServiceAccount "is already added to Managed Account" -ForegroundColor Yellow
			}	  
		}
		Catch
		{
			Write-Host $_.Exception.Message -ForegroundColor Red
		}
	}

#Enable ProjectServer License.
function Activate-PSLicense()
	{
	param ([string]$PSKey)
		Try 
		{
			Write-Host "Enable ProjectServer License" -ForegroundColor Green
			$res =	Enable-ProjectServerLicense -Key $PSKey
			if ($res -ne $null)
			{
				Write-Host "The Project Server License has been enabled successfully" -ForegroundColor Cyan
			}
		}
		Catch
		{
			Write-Host $_.Exception.Message -ForegroundColor Red
		}
	}

#Create Project Server Application Service Application Pool.
function Create-PWASvcAppPool()
	{
	param ([string]$PWASvcAppPool,[string]$PWASvcAppPoolAccount)
		Try 
		{
			Write-Host "Create Project Server Application Service Application Pool" -ForegroundColor Green
			$res = New-SPServiceApplicationPool  -Name $PWASvcAppPool -Account $PWASvcAppPoolAccount
			if ($res -ne $null)
			{
				Write-Host "Project Server Application Service Application Pool " $PWASvcAppPool " has been created successfully" -ForegroundColor Cyan
			}
		}
		Catch
		{
			Write-Host $_.Exception.Message -ForegroundColor Red
		}
	}

#Create Project Server Application Service.
function Create-PWASvc()
	{
	param ([string]$PWASvcName,[string]$PWASvcAppPool)
		Try
		{
			Write-Host "Create Project Server Application Service" -ForegroundColor Green
			$res = New-SPProjectServiceApplication –Name $PWASvcName –ApplicationPool $PWASvcAppPool –Proxy
			if ($res -ne $null)
			{
				Write-Host "Project Server Application Service " $PWASvcName " has been created successfully" -ForegroundColor Cyan
			}
		}
		Catch
		{
			Write-Host $_.Exception.Message -ForegroundColor Red
		}
	}


#Lock Down web application Content Database.
function LockDown-ContentDatabase()
	{
	param ([string]$ContentDataBaseName,[int]$MaxSiteCount,[int]$WarningSiteCount)
		Try
		{
			#Get-SPContentDatabase | ? {$_.Name -eq $ContentDataBaseName}
			Write-Host "Lock Down web application Content Database" -ForegroundColor Green
			$res = Set-SPContentDatabase -Identity $ContentDataBaseName -MaxSiteCount $MaxSiteCount -WarningSiteCount $WarningSiteCount
			if ($res -ne $null)
			{
				Write-Host "The Content Database " $ContentDataBaseName " has been locked successfully" -ForegroundColor Yellow
			}
		}
		Catch
		{
			Write-Host $_.Exception.Message -ForegroundColor Red
		}
	}

#Create A new PWA Content Database.
function Create-ContentDatabase()
	{
	param ([string]$PWAContentDataBaseName,[string]$DBServer,[string]$WebAppUrl)
		Try
		{
			Write-Host "Create A new PWA Content Database" -ForegroundColor Green
			$res = New-SPContentDatabase $PWAContentDataBaseName -DatabaseServer $DBServer -WebApplication $WebAppUrl
			if ($res -ne $null)
			{
				Write-Host "The PWA Content Database " $PWAContentDataBaseName " has been created successfully" -ForegroundColor Yellow
			}
		}
		Catch
		{
			Write-Host $_.Exception.Message -ForegroundColor Red
		}
	}

#Provision PWA Instance.
function Provision-PWAInstance()
	{
	param ([string]$PWAContentDataBaseName,[string]$siteOwner,[string]$PWAURL)
		Try
		{
			Write-Host "Provision PWA Instance" -ForegroundColor Green
			$res = New-SPSite -ContentDatabase $PWAContentDataBaseName -URL $PWAURL -Template pwa#0 -OwnerAlias $siteOwner
			if ($res -ne $null)
			{
				Write-Host "The PWA Instance " $PWAURL " has been created successfully" -ForegroundColor Yellow
			}
		}
		Catch
		{
			Write-Host $_.Exception.Message -ForegroundColor Red
		}
	}

#Enable PWA Feature.
function Enable-PWAFeature()
	{
    param ([string]$PWAURL)
		Try
		{
            Write-Host "Enable PWA Feature" -ForegroundColor Green
            $res = Enable-SPFeature pwasite -URL $PWAURL
            if ($res -ne $null)
			{
				Write-Host "The PWA feature " $PWAContentDataBaseName " has been enabled successfully" -ForegroundColor Yellow
			}
		}
		Catch
		{
			Write-Host $_.Exception.Message -ForegroundColor Red
		}
	}

#Browse PWA Instance.
function Browse-PWA()
	{
	param ([string]$PWAURL)
		Try
		{
			Write-Host "Start" $PWAURL -ForegroundColor Green
			START $PWAURL
		}
		Catch
		{
			Write-Host $_.Exception.Message -ForegroundColor Red
		}
	}

Write-Host *#######################################################
Write-Host *#Start Project Server 2016 Configuration
Write-Host *#######################################################
#Register Managed Account.
#Add PSSrvAppPool Account
Add-ManagedAccount -ServiceAccount $PSSrvAppPoolAccount -AccountPassword $PSSrvAppPoolPassWord

#######################################################
#Enable ProjectServer License.

Activate-PSLicense -PSKey $ProjectServerKey

#######################################################
#Create Project Server Application Service Application Pool.

Create-PWASvcAppPool -PWASvcAppPool $PWAAppServiceAppPool -PWASvcAppPoolAccount $PSSrvAppPoolAccount

#######################################################
#Create Project Server Application Service.

Create-PWASvc -PWASvcName $PWAAppServiceApp -PWASvcAppPool $PWAAppServiceAppPool

#######################################################

#Create A new PWA Content Database.

Create-ContentDatabase -PWAContentDataBaseName $PWAContentDataBaseName  -DBServer $DBServer -WebAppUrl $WebAppURL

#Lock Down PWA Content Database.
LockDown-ContentDatabase -ContentDataBaseName $PWAContentDataBaseName -MaxSiteCount 1 -WarningSiteCount 0

#######################################################
#Provision PWA Instance.

Provision-PWAInstance -PWAContentDataBaseName $PWAContentDataBaseName -PWAURL $PWAURL -siteOwner $PWAOwnerAccount

#######################################################
#Enable PWA Feature.

Enable-PWAFeature -PWAURL $PWAURL

#######################################################
#Browse PWA Instance.

Browse-PWA $PWAURL
#######################################################
#End
#######################################################
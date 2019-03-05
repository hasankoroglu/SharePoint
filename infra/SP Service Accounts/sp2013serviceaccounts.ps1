# .\sp2013serviceaccounts.ps1 -Level custom

param
(
    ##[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
    ##[String]$Product,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
    [String]$Level,
	[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
    [String]$SPOU,
	[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
    [String]$SQLOU,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
    [String]$SQLLevel,
	[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
    [Bool]$OptionalAccounts = $false
)


# create ou  Credits to IT Factory for this function!
function create_ou($domain_dn, $ou_name)
{
   # get domain
   $domain_obj = [ADSI]"LDAP://$domain_dn"

   # check for duplicates
   foreach ($ou in $domain_obj.psbase.children)
   {
     if ($ou.Name -eq $ou_name)
     {
        Write-Host -ForegroundColor Yellow  "-" $ou.Name "already exists in" $domain_obj.DistinguishedName
        Return
     }
   }

   # create ou
   $ou_obj = $domain_obj.Create("OrganizationalUnit", "ou=$ou_name")
   $ou_obj.SetInfo()
   Write-Host -ForegroundColor Green  "- OU $ou_name has been created."
}

# create user  Credits to IT Factory for some parts of the function. 
function create_user($domain_name, $ou_dn,$first, $last, $user_name, $user_account, $user_description, $password, $ptype)
{
   # get ou
   $ou_obj = [ADSI]"LDAP://$ou_dn"

   # check for duplicates
   foreach ($user in $ou_obj.psbase.children)
   {
     if ($user.Name -eq $user_name)
     {
        Write-Host -ForegroundColor Yellow  "-" $user.Name "already exists in" $ou_obj.DistinguishedName
        Return
     }
   }

   # create user  
   $user_obj = $ou_obj.Create("user", "cn=$user_name")
   $user_obj.Put("sAMAccountName", "$user_account")
   $user_obj.Put("userprincipalname", "$user_account@$domain_name")
   $user_obj.Put("description", $user_description)
   $user_obj.put("pwdLastset",-1) 
   $user_obj.SetInfo()
   $user_obj.SetPassword("$password")
   $user_obj.SetInfo()
   $user_obj.psbase.InvokeSet('FirstName',$first)
   $user_obj.SetInfo()
   $user_obj.psbase.InvokeSet('LastName',$last)
   $user_obj.SetInfo()
   $user_obj.psbase.invokeset("AccountDisabled", "False")
   $user_obj.SetInfo()

$currentUAC = [int]($user_obj.userAccountCOntrol.ToString())
$newUAC =  $currentUAC -bor 65536
$user_obj.put("userAccountControl",$newUAC)
$user_obj.SetInfo()

   Write-Host -foregroundcolor green "- User $user_name has been created with $ptype password "
}


function check_password_complexity($nonsecurepassword)
{

	If (!($nonsecurepassword) -or ($nonsecurepassword -eq ""))
	{		
		Return
	}
	$groups=0
	If ($nonsecurepassword -cmatch "[a-z]") { $groups = $groups + 1 }
	If ($nonsecurepassword -cmatch "[A-Z]") { $groups = $groups + 1 }
	If ($nonsecurepassword -match "[0-9]") { $groups = $groups + 1 }
	If ($nonsecurepassword -match "[^a-zA-Z0-9]") { $groups = $groups + 1 }
	
	If (($groups -lt 3) -or ($nonsecurepassword.length -lt 8))
	{
		Write-Host -ForegroundColor Yellow " - Service Accounts Password does not meet complexity requirements."
        Write-Host -ForegroundColor Yellow " - It must be at least 8 characters long and contain three of these types:"
		Write-Host -ForegroundColor Yellow "  - Upper case letters"
		Write-Host -ForegroundColor Yellow "  - Lower case letters"
		Write-Host -ForegroundColor Yellow "  - Digits"
		Write-Host -ForegroundColor Yellow "  - Other characters"
		Throw " - Service Accounts Password does not meet complexity requirements."
	}
}

Clear-Host

# get domain name
$domain_name = $env:userdnsdomain
$domain = [ADSI]"LDAP://$domain_name" 
$domain_dn = $domain.DistinguishedName

# get default password. If user put new password in XML, the XML will have priority
$defaultpassword = Read-Host "Ented password to use for all the accounts. It will get overritten if you set a password for the accounts in the XML file"

# starting creation

# create ou
Write-Host -foregroundcolor DarkGreen "Creating Service Accounts OU"

if ($SPOU)
{
$OuName = $SPOU
}
else
{
$OuName = "SharePoint Service Accounts"
}

if ($SQLOU)
{
$Sqlouname = $SQLOU
create_ou $domain_dn "$Sqlouname"
}
else
{
$Sqlouname = $OuName
}

create_ou $domain_dn "$OuName"


$ou_dn = "OU=$OuName,$domain_dn"
$sqlou_dn = "OU=$Sqlouname,$domain_dn"


#Check what level of SharePoint Service accounts
if($Level -eq "custom")
{
[xml]$userfile = Get-Content .\ServiceAccountsCustom.xml
}
else
{
Throw "You did not select what set of service accounts you want to use!"
}


Write-Host -foregroundcolor DarkGreen "Creating SharePoint Service Accounts for level $Level"

foreach( $user2 in $userfile.ServiceAccounts.User) 
{
#Check if take default or from XML
if ($user2.Password -eq "")
{
$password = $defaultpassword
$ptype = "default"
}
else
{
$password = $user2.Password
$ptype = "xml"
}
#check complexity
check_password_complexity($password)

#create user
   create_user $domain_name $ou_dn $user2.FirstName $user2.LastName $user2.UserName $user2.UserName $user2.Description $password $ptype
}


#Check if create SQL account and what level
if ($SQLLevel)
    {
 if ($SQLLevel -eq "low")
 {
[xml]$sqlfile = Get-Content .\XML\sqllow.xml
}
elseif($SQLLevel -eq "medium")
{
[xml]$sqlfile = Get-Content .\XML\sqlmed.xml
}
elseif($SQLLevel -eq "high")
{
[xml]$sqlfile = Get-Content .\XML\sqlhigh.xml
}
elseif($SQLLevel -eq "custom")
{
[xml]$sqlfile = Get-Content .\XML\sqlcustom.xml
}
else
{
Throw "You did not select what set of service accounts you want to use!"
}



Write-Host -foregroundcolor DarkGreen "Creating SQL Service Accounts "

#check what password to use
    foreach( $user3 in $sqlfile.ServiceAccounts.User) 
        {

        if ($user3.Password -eq "")
            {
            $password = $defaultpassword
			$ptype = "default"
        }
        else
        {
            $password = $user3.Password
			$ptype = "xml"
        }

        check_password_complexity($password)

   create_user $domain_name $sqlou_dn $user3.FirstName $user3.LastName $user3.UserName $user3.UserName $user3.Description $password $ptype
        }


}
else
{
Write-Host -foregroundcolor DarkGreen "No SQL Accounts to Create"
}



if ($OptionalAccounts)
{

if($Level -eq "AutoSPInstaller")
{
	Write-Host -foregroundcolor Yellow "AutoSPInstaller Level Created, Optional Accounts included. OptionalAccount Switch will be ignored."
}
else
{
Write-Host -foregroundcolor DarkGreen "Creating Optional Service Accounts "
[xml]$optionalfile = Get-Content .\XML\optionalaccounts.xml

 foreach( $user4 in $optionalfile.ServiceAccounts.User) 
        {

        if ($user4.Password -eq "")
            {
            $password = $defaultpassword
			$ptype = "default"
        }
        else
        {
            $password = $user4.Password
			$ptype = "xml"
        }

        check_password_complexity($password)

   create_user $domain_name $ou_dn $user4.FirstName $user4.LastName $user4.UserName $user4.UserName $user4.Description $password $ptype
        }

}
}

else
{
Write-Host -foregroundcolor DarkGreen "No Optional Accounts to Create"
}



# end
Write-Host -foregroundcolor Green " All Done"
Write-Host -foregroundcolor Green "Don't forget to check my blog at www.absolute-sharepoint.com"
Write-Host -foregroundcolor Green "Are you a member of www.SharePoint-Community.net? If not, you're missing amazing SP Stuff!"
Write-Host -foregroundcolor Green "If you have any comments, send me an email or tweet @vladcatrinescu"
# Script to create Active Directory accounts
# v2 9/12/2012
# Todd Klindt
# http://www.toddklindt.com

# Add the Active Directory bits and not complain if they're already there
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

# set default password
# change pass@word1 to whatever you want the account passwords to be
$defpassword = (ConvertTo-SecureString "Parola_19" -AsPlainText -force)

# Get domain DNS suffix
$dnsroot = '@' + (Get-ADDomain).dnsroot

# Import the file with the users. You can change the filename to reflect your file
$users = Import-Csv .\users.csv

$OuName = "SP Users"

# get domain name
$domain_name = $env:userdnsdomain
$domain = [ADSI]"LDAP://$domain_name" 
$domain_dn = $domain.DistinguishedName

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


create_ou $domain_dn $OuName

#The OU where the users will be created
$userspath = (Get-ADOrganizationalUnit -Filter 'Name -like $OuName').DistinguishedName

foreach ($user in $users) {
        if ($user.manager -eq "") # In case it's a service account or a boss
        {
            try {
                New-ADUser -SamAccountName $user.SamAccountName -Name ($user.FirstName + " " + $user.LastName) `
                -DisplayName ($user.FirstName + " " + $user.LastName) -GivenName $user.FirstName -Surname $user.LastName `
                -EmailAddress ($user.SamAccountName + $dnsroot) -UserPrincipalName ($user.SamAccountName + $dnsroot) `
                -Title $user.title -Department $user.Department -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires  $true `
                -AccountPassword $defpassword -PassThru `
                -OfficePhone $user.PhoneNumber `
                -Path $userspath
                $userPhoto = ".\vesikalik\" + $user.SamAccountName + ".jpg"
                Set-ADUser -Identity $user.SamAccountName -Replace @{thumbnailPhoto=([byte[]](Get-Content $userPhoto -Encoding byte))}
                }
            catch [System.Object]
                {
                    Write-Output "Could not create user $($user.SamAccountName), $_"
                }
        }
        else
        {
            try {
                New-ADUser -SamAccountName $user.SamAccountName -Name ($user.FirstName + " " + $user.LastName) `
                -DisplayName ($user.FirstName + " " + $user.LastName) -GivenName $user.FirstName -Surname $user.LastName `
                -EmailAddress ($user.SamAccountName + $dnsroot) -UserPrincipalName ($user.SamAccountName + $dnsroot) `
                -Title $user.title -manager $user.manager `
                -Department $user.Department `
                -Path $userspath `
                -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires  $true `
                -OfficePhone $user.PhoneNumber `
                -AccountPassword $defpassword -PassThru
                $userPhoto = ".\vesikalik\" + $user.SamAccountName + ".jpg"
                Set-ADUser -Identity $user.SamAccountName -Replace @{thumbnailPhoto=([byte[]](Get-Content $userPhoto -Encoding byte))}
                }
            catch [System.Object]
                {
                    Write-Output "Could not create user $($user.SamAccountName), $_"
                }
        }
   }
Add-PsSnapin "Microsoft.SharePoint.PowerShell" -EA 0

$portalAddress = "portal.colabtr.com"
$certPath = "C:\root.cer"

$rootCert = (Get-SPCertificateAuthority).RootCertificate
$rootCert.Export(“Cer”) | Set-Content $certPath –Encoding Byte

Import-Certificate -FilePath $certPath -CertStoreLocation 'Cert:\LocalMachine\Root' -Verbose 

gpupdate /force

Get-Item -path “HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0” | new-Itemproperty -Name “BackConnectionHostNames” -Value (“$portalAddress”) -PropertyType “MultiString”

Invoke-Command -ScriptBlock {iisreset}
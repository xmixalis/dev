param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage="Please provide the domain for the SSL Cert")] 
    [string]$certdomain = "mydomain.pch.com",
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage="Is it a wildcard Cert?")] 
    [int]$starcert = 0
)

$dir = Get-Location
$pfxExt = ".pfx"
$crtExt = ".crt"
$certnamePfx = "$certdomain$pfxExt"
$certnameCrt = "$certdomain$crtExt"
$certPath =  "$dir\$certnamePfx"
$certPass = "password"  
$starcertprefix = "" 
if ($starcert -eq 1)
{
    $starcertprefix  = "*."
}

$rootCert = New-SelfSignedCertificate -CertStoreLocation Cert:\CurrentUser\My -DnsName $starcertprefix$certdomain -TextExtension @("2.5.29.19={text}CA=true") -KeyUsage CertSign,CrlSign,DigitalSignature
[System.Security.SecureString]$rootCertPassword = ConvertTo-SecureString -String $certPass -Force -AsPlainText
[String]$rootCertPath = Join-Path -Path 'cert:\CurrentUser\My\' -ChildPath "$($rootCert.Thumbprint)"
Export-PfxCertificate -Cert $rootCertPath -FilePath $certnamePfx -Password $rootCertPassword
Export-Certificate -Cert $rootCertPath -FilePath $certnameCrt

Import-Certificate -FilePath $certnameCrt  -CertStoreLocation 'Cert:\CurrentUser\Root' -Verbose 
Import-PfxCertificate -FilePath $certnamePfx  -CertStoreLocation 'Cert:\CurrentUser\Root' -Verbose -Password $rootCertPassword 


# Setup certificate
$Flags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet `
    -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet `
    -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
$Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath,$certPass, $Flags)

# Install certificate into machine store
$Store = New-Object System.Security.Cryptography.X509Certificates.X509Store(
    [System.Security.Cryptography.X509Certificates.StoreName]::My, 
    [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
$Store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
$Store.Add($Certificate)
$Store.Close()
$certThumbprint = $Certificate.Thumbprint 


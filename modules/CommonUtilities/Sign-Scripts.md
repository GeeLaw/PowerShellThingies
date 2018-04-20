# Sign-Scripts

Use `Sign-Scripts [-Scripts] <string[]> [[-Certificate] <X509Certificate2>]` to sign your scripts. It is recommended that you set the execution policy to `AllSigned` to prevent (potentially) malicious scripts from running while provide yourself with convenience. To do so, you have to first create a root certificate using <a href="https://msdn.microsoft.com/en-us/library/bfsktky3(VS.80).aspx" target="_blank">makecert utility</a> in **elevated** PowerShell:

```PowerShell
makecert -n "CN=PowerShell Local Certificate Root" -a sha1 -eku 1.3.6.1.5.5.7.3.3 -r -sv root.pvk root.cer -ss Root -sr localMachine -b 4/1/2016 -e 1/1/2020
```

After creating the root certificate, create a code signing certificate from it:

```PowerShell
makecert -pe -n "CN=PowerShell Code Signing" -ss MY -a sha1 -eku 1.3.6.1.5.5.7.3.3 -iv root.pvk -ic root.cer
```

You have to enter a password to protect the key. After creation, verify the installation by the following command:

```PowerShell
Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
```

If there is at least one certificate, you're done.

If you have not supplied a certificate, `Sign-Scripts` cmdlet signs the scripts with the certificate you specify interactively. Furthermore, if you have only one code-signing certificate, the cmdlet silently signs all the specified scripts with that certificate.

You might get prompted to trust a certificate when you run a signed script for the first time, answering `A` (Always run) will add the certificate to trsuted publishers so that you do not have to confirm every time.

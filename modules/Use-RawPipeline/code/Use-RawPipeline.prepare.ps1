Push-Location $PSScriptRoot;
Add-Type -TypeDefinition (Get-Content '.\Helper.Windows.cs' -Encoding 'UTF8' -Raw);
Pop-Location;

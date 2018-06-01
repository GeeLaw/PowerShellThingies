Push-Location $PSScriptRoot;
Try
{
    If ($PSEdition -eq 'Desktop')
    {
        Add-Type -Path '.\Helper.Windows.cs' -ReferencedAssemblies @('PresentationFramework', 'PresentationCore', 'WindowsBase', 'System.Xaml', 'System.Dynamic');
    }
}
Catch { }
Finally
{
    Pop-Location;
}

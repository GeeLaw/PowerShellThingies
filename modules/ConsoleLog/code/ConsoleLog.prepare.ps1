& {
Try
{
    $local:StylesPath = [System.IO.Path]::Combine($PSScriptRoot, 'styles.css');
    $local:StylesContent = [System.IO.File]::ReadAllText($local:StylesPath);
    $local:Style2 = [System.IO.Path]::Combine($PSScriptRoot, 'interactive.css');
    $local:Helper = [System.IO.File]::ReadAllText(
        [System.IO.Path]::Combine($PSScriptRoot, 'Helper.conhost.cs'));
    Add-Type -TypeDefinition $local:Helper -Language CSharp;
    [GeeLaw.ConsoleCapture.Helper]::StylesPath = $local:StylesPath;
    <# This special minification works for the stylesheet. #>
    [GeeLaw.ConsoleCapture.Helper]::StylesContent = [System.Text.RegularExpressions.Regex]::new('\s+([,>:;+~{}])\s*|([,>:;+~{}])\s+').Replace($local:StylesContent, '$1$2').Replace(';}', '}');
    [GeeLaw.ConsoleCapture.Helper]::InteractiveStylesPath = $local:Style2;
}
Catch
{
    Throw;
}
}

Function Prompt
{
    Write-Host ((Get-Location).Path) -NoNewline;
    $cx = $Host.UI.RawUI.CursorPosition.X;
    $ww = $Host.UI.RawUI.WindowSize.Width;
    If ($NestedPromptLevel -gt 0)
    {
        $wannaPrint = "[nest $NestedPromptLevel]";
        If ($cx -le $ww - $wannaPrint.Length - 2)
        {
            Write-Host ' ' -NoNewline;
            Write-Host $wannaPrint -ForegroundColor 'Cyan' -BackgroundColor 'Black' -NoNewline;
            Write-Host ' ' -NoNewline;
        }
        ElseIf ($cx -le $ww - $wannaPrint.Length - 1)
        {
            Write-Host ' ' -NoNewline;
            Write-Host $wannaPrint -ForegroundColor 'Cyan' -BackgroundColor 'Black' -NoNewline;
        }
        Else
        {
            Write-Host "`n" -NoNewline;
            Write-Host $wannaPrint -ForegroundColor 'Cyan' -BackgroundColor 'Black' -NoNewline;
            Write-Host ' ' -NoNewline;
        }
        $cx = $Host.UI.RawUI.CursorPosition.X;
    }
    If ($cx -ge $ww - 1)
    {
        "`n>> "
    }
    ElseIf ($cx + 3.0 -le $ww * 0.45)
    {
        '> '
    }
    Else
    {
        ">`n>> "
    }
}

Function Clear-HistoryFull
{
    & (Get-Command -Type 'Cmdlet' -Name 'Clear-History');
    & ([System.IO.Path]::Combine([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile), 'Clear-PSReadlineHistory.vbs'));
}

& {

$charESC = ([char]0x1b).ToString();

$options = Get-PSReadlineOption;
@{
    "EditMode" = "Windows";
    "PromptText" = "> ";
    "ContinuationPromptForegroundColor" = "Gray";
    "ContinuationPromptColor" = $charESC + "[37m";
    "StringForegroundColor" = "Cyan";
    "StringColor" = $charESC + "[96m";
    "EmphasisForegroundColor" = "White";
    "EmphasisBackgroundColor" = "DarkCyan";
    "EmphasisColor" = $charESC + "[97;46m";
    "SelectionColor" = $charESC + "[30;47m"
}.GetEnumerator() | ForEach-Object {
    If (($options | Get-Member -MemberType 'Property' -Name ($_.Key) -ErrorAction Ignore) -ne $null)
    {
        $options.($_.Key) = $_.Value;
    }
}
$options = $Host.PrivateData;
@{
    "ErrorForegroundColor" = "White";
    "ErrorBackgroundColor" = "Red";
    "ErrorColor" = $charESC + "[97;101m";
    "WarningForegroundColor" = "Black";
    "WarningBackgroundColor" = "Yellow";
    "WarningColor" = $charESC + "[30;103m";
    "DebugForegroundColor" = "Cyan";
    "DebugBackgroundColor" = "Black";
    "DebugColor" = $charESC + "[96;40m";
    "VerboseForegroundColor" = "DarkYellow";
    "VerboseBackgroundColor" = "Black";
    "VerboseColor" = $charESC + "[33;40m";
    "ProgressForegroundColor" = "Yellow";
    "ProgressBackgroundColor" = "DarkCyan"
    "ProgressColor" = $charESC + "[93;46m";
}.GetEnumerator() | ForEach-Object {
    If (($options | Get-Member -MemberType 'Property' -Name ($_.Key) -ErrorAction Ignore) -ne $null)
    {
        $options.($_.Key) = $_.Value;
    }
}

Use-CommonAliases;

New-Alias -Name 'Clear-History' -Value "Clear-HistoryFull" -Description 'Fully clears the command history.' -Force -Option 'Constant','AllScope' -Scope 'Global';

New-Alias -Name 'Open-EnvironmentVariableEditor' -Value ([System.IO.Path]::Combine([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile), 'Open-EnvironmentVariableEditor.ps1')) -Description 'Opens the environment variable editor.' -Force -Option 'Constant','AllScope' -Scope 'Global';

$oskPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::System), 'osk.exe');
Start-Process -FilePath $oskPath;

} | Out-Null;

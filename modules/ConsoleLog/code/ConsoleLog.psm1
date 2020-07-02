<#
.SYNOPSIS
Transcribes the console log into HTML, plain text, JSON, or object.

.DESCRIPTION
Get-ConsoleLog captures the buffer of the console PowerShell is currently
running and converts it into HTML, plain text, JSON, or object.

.PARAMETER IncludeThisLine
This switch determines whether or not to capture the line the cursor is at
when the command is invoked.  By default, this line is not captured since it
is almost always empty when invoked interactively.  If we run
    PS C:\> Write-Host 1; Get-ConsoleLog -IncludeThisLine
interactively, the result is
```
PS C:\> Write-Host 1; Get-ConsoleLog
1

```
Note the extra blank line after "1".

.PARAMETER TrailingSpace
Determines how trailing space characters are handled, can be one of
    KeepAll | IgnoreAll | IgnoreDefaultColors
and `IgnoreDefaultColors` is the default.

`KeepAll` simply keeps all space characters, so each line is exactly 80
characters wide if all characters are basic Latin and the console is also
80 characters wide.

`IgnoreAll` simply removes all trailing space characters.  Note that some
trailing space characters may have a different background than the other
parts of the line.  They are removed regardless of such.  Consequently,
the outcome might not accurately reflect the actual on-screen rendering.

`IgnoreDefaultColors` is the default, and it removes all trailing space
characters of the same color as the background of the line.  This is what
people usually expect.  However, this might come as a surprise when the
format is `Text`, where the default behavior is still `IgnoreDefaultColors`.
This means it is possible that a line contains trailing space.

.PARAMETER Format
Determines the format of the output, can be one of
    Html | Text | Json | Object
and `Html` is the default.

`Html` format also considers CSS incorporation.  See also `Css` parameter.
The result is always one single string.

`Text` is the plain text format.  See `TrailingSpace` for possible surprise.
By default, each line is sent down the pipeline.  See also `Concat` parameter.

`Json` is the JSON serialization of the object result.  See also `Compress`.
The result directly comes from `ConvertTo-Json`.

`Object` gives one single `ConsoleLog` object.

.PARAMETER Css
Determines whether and how CSS is incorporated, can be one of
    Embed | Link | None
and `None` is the default.  It is ignored if `Format` is not `Html`.

.PARAMETER Concat
This switch determines whether the plain text capture is returned as one
single string.  It is ignored if `Format` is not `Text`.

.PARAMETER Compress
This switch determines whether the JSON output is minified.  It is ignored
if `Format` is not `Json`.

.LINK
https://github.com/GeeLaw/PowerShellThingies/blob/master/modules/ConsoleLog/README.md#get-consolelog

#>
Function Get-ConsoleLog
{
    [CmdletBinding(HelpURI='https://github.com/GeeLaw/PowerShellThingies/blob/master/modules/ConsoleLog/README.md#get-consolelog', PositionalBinding=$False)]
    Param
    (
        [switch]$IncludeThisLine,
        [ValidateSet('KeepAll', 'IgnoreAll', 'IgnoreDefaultColors')]
        [string]$TrailingSpace = 'IgnoreDefaultColors',
        [ValidateSet('Html', 'Text', 'Json', 'Object')]
        [string]$Format = 'Html',
        [ValidateSet('Embed', 'Link', 'None')]
        [string]$Css = 'None',
        [switch]$Concat,
        [switch]$Compress
    )
    Process
    {
        If ($Format -eq 'Html')
        {
            $local:html = '';
            If ($Css -eq 'Embed')
            {
                $html = '<style type="text/css">' + [GeeLaw.ConsoleCapture.Helper]::StylesContent + "</style>`n";
            }
            ElseIf ($Css -eq 'Link')
            {
                $html = '<link href="file:///' + [GeeLaw.ConsoleCapture.Helper]::StylesPath.Replace('\', '/').Replace('&', '&amp;').Replace("'", '&#39;') + "`" rel=`"stylesheet`" />`n";
            }
            $html += [GeeLaw.ConsoleCapture.HtmlCapturer]::Capture($Host, $IncludeThisLine, $TrailingSpace);
            Return $html;
        }
        If ($Format -eq 'Text')
        {
            $local:text = [GeeLaw.ConsoleCapture.TextCapturer]::Capture($Host,
                $IncludeThisLine, $TrailingSpace);
            If ($Concat) { $text -join "`n" }
            Else { $text | Write-Output }
        }
        Else
        {
            $local:obj = [GeeLaw.ConsoleCapture.Capturer]::Capture($Host, $IncludeThisLine, $TrailingSpace);
            If ($Format -eq 'Object')
            {
                Return $obj;
            }
            ConvertTo-Json -InputObject $obj -Depth 9 -Compress:$Compress;
        }
    }
}

<#
.SYNOPSIS
Transcribes the console log into HTML and displays it.

.DESCRIPTION
Show-ConsoleLog captures the buffer of the console PowerShell is currently
running, converts it into HTML, and displays it in the default browser.

.PARAMETER IncludeThisLine
This switch determines whether or not to capture the line the cursor is at
when the command is invoked.  By default, this line is not captured since it
is almost always empty when invoked interactively.  If we run
    PS C:\> Write-Host 1; Get-ConsoleLog -IncludeThisLine
interactively, the result is
```
PS C:\> Write-Host 1; Get-ConsoleLog
1

```
Note the extra blank line after "1".

.PARAMETER TrailingSpace
Determines how trailing space characters are handled, can be one of
    KeepAll | IgnoreAll | IgnoreDefaultColors
and `IgnoreDefaultColors` is the default.

`KeepAll` simply keeps all space characters, so each line is exactly 80
characters wide if all characters are basic Latin and the console is also
80 characters wide.

`IgnoreAll` simply removes all trailing space characters.  Note that some
trailing space characters may have a different background than the other
parts of the line.  They are removed regardless of such.  Consequently,
the outcome might not accurately reflect the actual on-screen rendering.

`IgnoreDefaultColors` is the default, and it removes all trailing space
characters of the same color as the background of the line.  This is what
people usually expect.  However, this might come as a surprise when the
format is `Text`, where the default behavior is still `IgnoreDefaultColors`.
This means it is possible that a line contains trailing space.

.PARAMETER Interactive
This switch determines whether the result should be interactive.  By default,
the output tries to recover the exact rendering of the console history, which
is like a vector-graphical screenshot and is non-interactive.  If this switch
is on, an alternative view arranging the captured `ConsoleLog` object as a
tree is used.

.LINK
https://github.com/GeeLaw/PowerShellThingies/blob/master/modules/ConsoleLog/README.md#show-consolelog

#>
Function Show-ConsoleLog
{
    [CmdletBinding(HelpURI='https://github.com/GeeLaw/PowerShellThingies/blob/master/modules/ConsoleLog/README.md#show-consolelog')]
    Param
    (
        [switch]$IncludeThisLine,
        [ValidateSet('KeepAll', 'IgnoreAll', 'IgnoreDefaultColors')]
        [string]$TrailingSpace = 'IgnoreDefaultColors',
        [switch]$Interactive
    )
    Process
    {
        $local:tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString('n') + '.html');
        $local:html = '';
        If (-not $Interactive)
        {
            $html = "<!doctype html>`n<html><meta charset=`"utf-8`" />`n<meta name=`"viewport`" content=`"width=device-width, initial-scale=1`" />`n<title>Console Log (Show-ConsoleLog)</title>`n" + (Get-ConsoleLog -IncludeThisLine:$IncludeThisLine -TrailingSpace $TrailingSpace -Format 'Html' -Css 'Link') + "</html>`n";
        }
        Else
        {
            $html = [GeeLaw.ConsoleCapture.Helper]::GetInteractiveHtml(
                $Host, $IncludeThisLine, $TrailingSpace);
        }
        [System.IO.File]::WriteAllText($tempFile, $html);
        Invoke-Item $tempFile;
    }
}

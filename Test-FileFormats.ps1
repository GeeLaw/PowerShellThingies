#Requires -Version 3.0

# PSScriptRoot requires PowerShell 3.0.

<#
.SYNOPSIS
    Tests files in the directory of the script and
    determines whether each file conforms to its standard.

.DESCRIPTION
    The script recursively grabs files in the directory
    and checks whether each file is conforming. This is
    usually done to ensure correct encoding and line-ending
    style are used. For example, .md and .gitignore are
    required to be encoded as UTF-8 without BOM and to
    have LF line-ending style.

    This file is licensed under the MIT license.

    Copyright (c) 2018 by Gee Law.

.PARAMETER WriteError
    Stops the script from writing the summary. Instead,
    call Write-Error for all entries in the summary.

.INPUTS
    The script accepts no inputs.

.OUTPUTS
    The script outputs a summary of problems found
    in the directory (unless -WriteError is set).

.EXAMPLE
    .\Test-FileFormat.ps1 | Out-GridView

    Opens up a GridView window if a problem is found,
    and displays all the problems.

.LINK
    https://github.com/GeeLaw/PowerShellThingies/blob/master/Test-FileFormats.ps1

#>
[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $false)]
    [switch]$WriteError
)
Process
{
    $local:binExt = @('.png');
    $local:utf8woBomLfExt = @('.gitignore', '.md', '.ps1', '.psd1', '.psm1', '.cs', '.html');
    $local:checker = {
        Push-Location -LiteralPath $PSScriptRoot;
        Try
        {
            Get-ChildItem -File -Recurse | ForEach-Object {
                $local:ext = $_.Extension.ToLowerInvariant();
                $local:msg = $null;
                $local:relativePath = $null;
                $local:recognition = $null;
                $local:target = $null;
                $local:problem = $null;
                If ($utf8woBomLfExt.Contains($ext))
                {
                    $recognition = 'text file (UTF-8 w/o BOM; LF)';
                    $local:bom = Get-Content -LiteralPath $_.PSPath -Encoding Byte -First 3;
                    $local:hasBom = ($bom.Length -eq 3 -and $bom[0] -eq 0xEF -and $bom[1] -eq 0xBB -and $bom[2] -eq 0xBF);
                    $local:hasCr = Get-Content -LiteralPath $_.PSPath -Encoding Byte |
                        Where-Object { $_ -eq 0x0D } |
                        Measure-Object |
                        ForEach-Object { $_.Count -gt 0 };
                    If ($hasBom -or $hasCr)
                    {
                        $target = $_;
                        If ($hasBom -and $hasCr)
                        {
                            $problem = 'has BOM and CR';
                        }
                        ElseIf ($hasBom)
                        {
                            $problem = 'has BOM';
                        }
                        Else
                        {
                            $problem = 'has CR';
                        }
                    }
                }
                ElseIf (-not $binExt.Contains($ext))
                {
                    $recognition = 'unknown';
                    $msg = 'is unrecognised by extension.';
                    $problem = 'unrecognised';
                    $target = $_;
                }
                If ($target -ne $null)
                {
                    $relativePath = Resolve-Path -LiteralPath $_.PSPath -Relative;
                    If ($msg -eq $null -and $problem -eq $null)
                    {
                        $msg = "is recognised as $recognition, but does not conform to its standard.";
                        $problem = 'non-conforming';
                    }
                    ElseIf ($problem -eq $null)
                    {
                        $problem = $msg;
                    }
                    ElseIf ($msg -eq $null)
                    {
                        $msg = "has the following problem: $problem.";
                    }
                    New-Object -Type PSObject -Property @{
                        'Message' = "$relativePath $msg";
                        'RelativePath' = $relativePath;
                        'Target' = $target;
                        'RecognisedType' = $recognition;
                        'Problem' = $problem };
                }
            };
        }
        Catch
        {
            Throw;
        }
        Finally
        {
            Pop-Location;
        }
    };
    If (-not $WriteError)
    {
        & $checker | Select-Object RecognisedType, RelativePath, Problem;
    }
    Else
    {
        & $checker | ForEach-Object {
            Write-Error -Message $_.Message -Category InvalidData `
                -TargetObject $_.Target `
                -RecommendedAction 'Check this file before pushing.';
        };
    }
}

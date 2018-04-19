Function Resolve-PathAsFileSystemPath
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    Process
    {
        Try
        {
            $local:resolved = @(Resolve-Path -Path $Path);
            If ($local:resolved.Count -gt 1)
            {
                Throw "Resolves to multiple paths: $Path";
                Return;
            }
            If ($local:resolved.Count -lt 1)
            {
                Throw "Resolves to no path: $Path";
                Return;
            }
            $local:resolved = $local:resolved[0];
            If ($local:resolved.Provider.Name -ne 'FileSystem')
            {
                Throw "Does not resolve to a file system path: $Path";
                Return;
            }
            $local:resolved.ProviderPath | Write-Output;
        }
        Catch
        {
            Throw;
        }
    }
}

Function Get-RawPipelineFromFile
{
    [CmdletBinding(HelpUri = 'https://github.com/GeeLaw/PowerShellThingies/tree/master/modules/Use-RawPipeline')]
    Param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('i')]
        [Alias('if')]
        [Alias('in')]
        [Alias('stdin')]
        [ValidateNotNullOrEmpty()]
        [string]$InputFile
    )
    Process
    {
        $local:result = $null;
        Try
        {
            $local:input = Resolve-PathAsFileSystemPath -Path $InputFile -ErrorAction 'Stop';
            $local:result = [GeeLaw.PSUseRawPipeline.ConcatenateFileStartInfo]::new($local:input);
        }
        Catch
        {
            $local:result = $null;
            Throw;
        }
        $local:result | Write-Output;
    }
}

Function Invoke-NativeCommand
{
    [CmdletBinding(HelpUri = 'https://github.com/GeeLaw/PowerShellThingies/tree/master/modules/Use-RawPipeline', DefaultParameterSetName = 'CreateProcess')]
    Param
    (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'CreateProcess')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'CreateProcessWithStandardErrorRedirection')]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,
        [Parameter(Mandatory = $false, Position = 1,
            ValueFromRemainingArguments = $true, ParameterSetName = 'CreateProcess')]
        [Parameter(Mandatory = $false, Position = 1,
            ValueFromRemainingArguments = $true, ParameterSetName = 'CreateProcessWithStandardErrorRedirection')]
        [string[]]$ArgumentList,
        [Parameter(Mandatory = $false, ParameterSetName = 'CreateProcess')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CreateProcessWithStandardErrorRedirection')]
        [ValidateNotNullOrEmpty()]
        [string]$WorkingDirectory = '.',
        [Parameter(Mandatory = $false, ValueFromPipeline = $true,
            ParameterSetName = 'CreateProcess')]
        [Parameter(Mandatory = $false, ValueFromPipeline = $true,
            ParameterSetName = 'CreateProcessWithStandardErrorRedirection')]
        [GeeLaw.PSUseRawPipeline.ITeedProcessStartInfo]$StandardInput,
        [Parameter(Mandatory = $true, ParameterSetName = 'CreateProcessWithStandardErrorRedirection')]
        [string]$ErrorFile,
        [Parameter(Mandatory = $false, ParameterSetName = 'CreateProcessWithStandardErrorRedirection')]
        [switch]$AppendError
    )
    Process
    {
        $local:result = $null;
        Try
        {
            $local:baseDirectory = Resolve-PathAsFileSystemPath -Path '.' -ErrorAction 'Stop';
            $WorkingDirectory = Resolve-PathAsFileSystemPath -Path $WorkingDirectory -ErrorAction 'Stop';
            <# If you pass $null to a [string] argument, you get [string]::Empty instead. #>
            If ($PSCmdlet.ParameterSetName -eq 'CreateProcessWithStandardErrorRedirection')
            {
                $local:result = [GeeLaw.PSUseRawPipeline.PipedProcessStartInfo]::new(`
                    $FilePath, $local:baseDirectory, $WorkingDirectory, `
                    $ArgumentList, $StandardInput, $ErrorFile, $AppendError);
            }
            Else
            {
                $local:result = [GeeLaw.PSUseRawPipeline.PipedProcessStartInfo]::new(`
                    $FilePath, $local:baseDirectory, $WorkingDirectory, `
                    $ArgumentList, $StandardInput);
            }
        }
        Catch
        {
            $local:result = $null;
            Throw;
        }
        $local:result | Write-Output;
    }
}

Function Receive-RawPipeline
{
    [CmdletBinding(HelpUri = 'https://github.com/GeeLaw/PowerShellThingies/tree/master/modules/Use-RawPipeline', DefaultParameterSetName = 'CommonEncoding')]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'CommonEncoding')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'CustomEncoding')]
        [ValidateNotNull()]
        [GeeLaw.PSUseRawPipeline.ITeedProcessStartInfo]$StandardInput,
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'CommonEncoding')]
        [ValidateSet('Auto', 'Byte', 'UTF8', 'UTF16LE', 'UTF16BE', 'UTF32')]
        [string]$CommonEncoding = 'Auto',
        [Parameter(Mandatory = $true, ParameterSetName = 'CustomEncoding')]
        [string]$Encoding,
        [Parameter(Mandatory = $false, ParameterSetName = 'CommonEncoding')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CustomEncoding')]
        [switch]$Raw
    )
    Process
    {
        Try
        {
            If ($PSCmdlet.ParameterSetName -eq 'CommonEncoding' -and $CommonEncoding -eq 'Byte')
            {
                $local:startedProcess = $StandardInput.Invoke();
                [GeeLaw.PSUseRawPipeline.Helper]::EnumerateBytesInStandardOutput($local:startedProcess);
                Return;
            }
            $local:chosenEncoding = $null;
            If ($PSCmdlet.ParameterSetName -eq 'CommonEncoding')
            {
                If ($CommonEncoding -eq 'UTF8')
                {
                    $local:chosenEncoding = [System.Text.Encoding]::UTF8;
                }
                ElseIf ($CommonEncoding -eq 'UTF16LE')
                {
                    $local:chosenEncoding = [System.Text.Encoding]::Unicode;
                }
                ElseIf ($CommonEncoding -eq 'UTF16BE')
                {
                    $local:chosenEncoding = [System.Text.Encoding]::BigEndianUnicode;
                }
                ElseIf ($CommonEncoding -eq 'UTF32')
                {
                    $local:chosenEncoding = [System.Text.Encoding]::UTF32;
                }
            }
            Else
            {
                $local:chosenEncoding = [System.Text.Encoding]::GetEncoding($Encoding);
            }
            $local:startedProcess = $StandardInput.Invoke();
            If ($Raw)
            {
                [GeeLaw.PSUseRawPipeline.Helper]::StringFromStandardOutput($local:startedProcess, $local:chosenEncoding);
                Return;
            }
            [GeeLaw.PSUseRawPipeline.Helper]::EnumerateLinesInStandardOutput($local:startedProcess, $local:chosenEncoding);
            Return;
        }
        Catch
        {
            Throw;
        }
    }
}

Function Set-RawPipelineToFile
{
    [CmdletBinding(HelpUri = 'https://github.com/GeeLaw/PowerShellThingies/tree/master/modules/Use-RawPipeline')]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [GeeLaw.PSUseRawPipeline.ITeedProcessStartInfo]$StandardInput,
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputFile
    )
    Process
    {
        $local:fs = $null;
        Try
        {
            $local:baseDirectory = Resolve-PathAsFileSystemPath -Path '.' -ErrorAction 'Stop';
            $local:currentDirectory = [System.IO.Directory]::GetCurrentDirectory();
            Try
            {
                [System.IO.Directory]::SetCurrentDirectory($local:baseDirectory);
                $local:fs = [System.IO.FileStream]::new($OutputFile, [System.IO.FileMode]::Create, `
                    [System.IO.FileAccess]::Write);
            }
            Finally
            {
                [System.IO.Directory]::SetCurrentDirectory($local:currentDirectory);
            }
            $local:startedProcess = $StandardInput.Invoke();
            [GeeLaw.PSUseRawPipeline.Helper]::CopyStandardOutput($local:startedProcess, $local:fs);
            Return;
        }
        Catch
        {
            Throw;
        }
        Finally
        {
            If ($local:fs -ne $null)
            {
                $local:fs.Close();
            }
        }
    }
}

Function Add-RawPipelineToFile
{
    [CmdletBinding(HelpUri = 'https://github.com/GeeLaw/PowerShellThingies/tree/master/modules/Use-RawPipeline')]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [GeeLaw.PSUseRawPipeline.ITeedProcessStartInfo]$StandardInput,
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputFile
    )
    Process
    {
        $local:fs = $null;
        Try
        {
            $local:baseDirectory = Resolve-PathAsFileSystemPath -Path '.' -ErrorAction 'Stop';
            $local:currentDirectory = [System.IO.Directory]::GetCurrentDirectory();
            Try
            {
                [System.IO.Directory]::SetCurrentDirectory($local:baseDirectory);
                $local:fs = [System.IO.FileStream]::new($OutputFile, [System.IO.FileMode]::Append);
            }
            Finally
            {
                [System.IO.Directory]::SetCurrentDirectory($local:currentDirectory);
            }
            $local:startedProcess = $StandardInput.Invoke();
            [GeeLaw.PSUseRawPipeline.Helper]::CopyStandardOutput($local:startedProcess, $local:fs);
            Return;
        }
        Catch
        {
            Throw;
        }
        Finally
        {
            If ($local:fs -ne $null)
            {
                $local:fs.Close();
            }
        }
    }
}

Set-Alias -Name 'run' -Value 'Invoke-NativeCommand';
Set-Alias -Name '2ps' -Value 'Receive-RawPipeline';
Set-Alias -Name 'stdin' -Value 'Get-RawPipelineFromFile';
Set-Alias -Name 'out2' -Value 'Set-RawPipelineToFile';
Set-Alias -Name 'add2' -Value 'Add-RawPipelineToFile';

Export-ModuleMember -Function @('Invoke-NativeCommand', `
    'Receive-RawPipeline', 'Get-RawPipelineFromFile', `
    'Set-RawPipelineToFile', 'Add-RawPipelineToFile') `
    -Alias @('run', '2ps', 'stdin', 'out2', 'add2');

# Use-RawPipeline

This module provides better raw pipeline than PowerShell 5.

> 中文使用者请参阅 [我的博客](https://geelaw.blog/entries/powershell-use-rawpipeline/)。

## License

This module is published under [MIT License](LICENSE.md).

## Get

To install this module for all users, use the following script:

```PowerShell
#Requires -RunAsAdministrator
# PowerShell
Install-Module -Name Use-RawPipeline -Scope AllUsers;
```

To install this module for the current user, use the following script:

```PowerShell
# PowerShell
Install-Module -Name Use-RawPipeline -Scope CurrentUser;
```

## Motive

PowerShell, up to version 5, does not work well with native utilities. This is in the OO nature of PowerShell. When invoking a native utility, for example:

```PowerShell
# PowerShell
git format-patch HEAD~3
```

PowerShell converts the output of `git` command into a string (encoding guessed by PowerShell), then splits it by line and finally returns it as an `object[]`. This causes many problems, one of which is that the native utility pipe chain breaks because PowerShell uses UTF16LE as the default encoding and CRLF as the default line-ending character sequence. Since the output has been parsed as an object, PowerShell is unable to recover the encoding and the line-ending sequence, resulting in misformed content piped to the next command.

For example, the following command will create a text file with UTF16LE encoding and CRLF line-ending sequence, making the `patch.patch` unusable by `git apply`:

```PowerShell
# PowerShell
git format-patch HEAD~3 > patch.patch
```

However, a bash user expects the binary form of `stdout` of `git` to be written to `patch.patch`, as it is in the following scenario:

```bash
# bash
git format-patch HEAD~3 > patch.patch
```

This module resolves this issue.

## Usage

### `ITeedProcessStartInfo` interface

Represents the user’s wish to execute some command.

### `ITeedProcess` interface

Represents a command that has started.

### Examples of those interfaces

```PowerShell
# PowerShell
Open-FileAsRawPipeline -InputFile 'my-urls' | `
    Invoke-NativeCommand -FilePath 'sort'   | `
    Invoke-NativeCommand -FilePath 'unique' | `
    Receive-RawPipeline;
```

The command before the first pipe creates a `ConcatenateFileStartInfo(a)`, saving the information of the file *to be opened*. The command before the second pipe creates a `PipedProcessStartInfo(b)` and chains it to `ConcatenateFileStartInfo(a)` so that when `b` has its process started, it gets its standard input from `a`. The command before the third pipe creates antoher `PipedProcessStartInfo(c)` and chains it to `PipedProcessStartInfo(b)`. The last command *consumes* the `ITeedProcessStartInfo` piped from the previous command by:

1. Calling `c.Invoke()`;
  - `c.Invoke()` will in turn call `b.Invoke()`, take the read handle for the standard output of  `b` and creates the process for `c`; were `c` to fail creating the process, it would terminate the process of `b`;
  - `b.Invoke()` will in turn call `a.Invoke()`, take the read handle for the standard output of `a` and creates the process for `b`; were `b` to fail creating the process, it would terminate the process of `a`;
  - `a.Invoke()` will open the specified file in read mode and use that handle as the read handle for its standard output (to be consumed by `b`);
2. Taking the read handle for the standard output of `c`, reading it and sending each line to the pipeline as soon as it is available.

### `Invoke-NativeCommand`
#### Parameter set: `CreateProcess`
Parameters: `-FilePath <string>` is positioned at 0, `-ArgumentList <string[]>` takes its value from remaining arguments, `-WorkingDirectory <string>` sets the initial working directory of the child process (defaults to `.`) and `-StandardInput <ITeedProcessStartInfo>` can be optionally piped from the pipeline, to redirect the standard input of the child process.

This cmdlet creates a `PipedProcess` for further consumption.

#### Parameter set: `CreateProcessWithStandardErrorRedirection`
Two more parameters than the `CreateProcess` version: `-ErrorFile <string>` and `-AppendError`, used for redirecting standard error to a file.

### `Get-RawPipelineFromFile`
Only one parameter: `-InputFile <string>`, positioned at 0, has aliases `i`, `if`, `in` and `stdin`. This cmdlet creates a `ConcatenateFileStartInfo` for further consumption.

### `Receive-RawPipeline`
#### Parameter set: `CommonEncoding`
Parameters: `-StandardInput <ITeedProcessStartInfo>` can be piped from the pipeline, `-CommonEncoding { Auto | Byte | UTF8 | UTF16LE | UTF16BE | UTF32 }`, defaulting to `Auto`, takes the position at 0 and `-Raw` is a switch.

This cmdlet consumes the `ITeedProcessStartInfo` piped into it. It reads its standard output according to the specified `-CommonEncoding`. If `-Raw` is on, this cmdlet blocks until the termination of the child process and writes a string to the pipeline; if `-Raw` is off, the cmdlet sends lines of string from the standard output of the child process as soon as they are available.

If `-CommonEncoding` is `Byte`, the cmdlet always writes the bytes as soon as they are available and `-Raw` is ignored.

#### Parameter set: `CustomEncoding`
Parameters: `-StandardInput <ITeedProcessStartInfo>` can be piped from the pipeline, `-Encoding <string>` defines the encoding to use and still, the switch `-Raw`.

### `Set-RawPipelineToFile`
Two parameters: `-StandardInput <ITeedProcessStartInfo>` can be piped from the pipeline and `-OutputFile <string>` takes the position at 0. This cmdlet copies the standard output of `ITeedProcessStartInfo` to the specified file. If the file already exists, it is overwritten.

### `Add-RawPipelineToFile`
Two parameters: `-StandardInput <ITeedProcessStartInfo>` can be piped from the pipeline and `-OutputFile <string>` takes the position at 0. This cmdlet copies the standard output of `ITeedProcessStartInfo` to *the end of* the specified file. If the file does not exist, it will be created.

## Examples

To make the example in the motive work correctly, use the following commands:

```PowerShell
# PowerShell
run git format-patch HEAD~3 | out2 patch.patch
```

To redirect:

```PowerShell
# PowerShell
stdin my-input | run my_native-utility | add2 my-output
# Appending
```

To parse lines:

```PowerShell
# PowerShell
stdin my-input | run my_native-utility | 2ps
```

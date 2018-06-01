# Out-TextEditor

Perhaps the motivation itself is important enough. I started this advanced function because I would like to read PowerShell help in a text editor. I could have used `Out-GridView`, but it is not good enough as I couldn’t search text without filtering the others, and that the window doesn’t use a monospace font, which makes indented help content with code between the lines very hard to read. The alias `ocsv` means `Out-VisualStudioCode`.

Example:

```PowerShell
Get-Help about_Common_Parameters | Out-TextEditor
```

Basically what the advanced function does is to accumulate the input objects and send them to `Out-File` at the end, and then fires up the text editor.

Two possible improvements:

1. Let the user specify text editor with ease.
2. Process the pipeline more efficiently.

For 1, currently the user must specify a script block similar to the following to use his own text editor:

```PowerShell
{
    <# Checks whether quoting is necessary. #>
    If ([System.Linq.Enumerable]::Any($_, [char].GetMethod('IsWhiteSpace', [type[]]@([char])).CreateDelegate([System.Func[char, bool]])))
    {
        $_ = '"' + $_ + '"';
    }
    <# "code" is a batch file that starts the real Code process.
     # Use -NoNewWindow to avoid a new command prompt window.
     #>
    Start-Process -FilePath 'code' -ArgumentList @($_) -NoNewWindow;
}
```

Presumably the user can simply set the file association for `.txt` and supply:

```PowerShell
{
    Start-Process -FilePath $_;
}
```

Or the user can, actually, do whatever he/she wants to, e.g.:

```PowerShell
# Starts a protocol.
{
    Start-Process "text-editor-uri-protocol:$_";
}
# Renames the file and opens it.
{
    Move-Item -LiteralPath $_ -Destination "$_.sublime-file-ext";
    Start-Process "$_.sublime-file-ext";
}
```

Any output produced by this script block is discarded.

As for 2, currently we have to wait until all objects are received before we start writing. We could have used `Start-Job` and send the objects as they arrive. However, currently advanced functions do not support overriding `StopProcessing`, which means we cannot clean up the job object and the synchronization objects if the pipeline is stopped (Ctrl+C or programmatically).

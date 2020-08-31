# SurrogateUser

These scripts, along with `Install-Apps`, `WinConsole` and `-FastCredential` series (in `CommonUtilities`), form the workflow of creating a surrogate user to use some software or perform some tests, while minimizing the disk and time cost.

Chinese speakers are encouraged to read [this blog entry](https://geelaw.blog/entries/windows-fileassoc-walkthru/) 《“打开方式”的“打开方式”》 to understand the workflow and the techniques involved in the two file association scripts.

## `Install-WindowsPhotoViewer.ps1`

This script registers Windows Photo Viewer as a handler of images. Photos app for Windows is good, but can be hard to control from command line (e.g., you don’t know when a user has closed the window of the photo). Also, using Photos app requires:

1. Logging on with the account’s own session for at least once, which brings all the overhead of those appx packages. You can see it from the profile size.
2. Currently in the account’s own session. If you are `user1` and running PowerShell as `user2`, then you cannot `Start-Process image.png` from that prompt, because WinRT app activation requires session - desktop - process identity consistency.

Besides those reasons, some people just like Windows Photo Viewer, so why not bring it back? I followed [the documentation](https://docs.microsoft.com/en-us/windows/desktop/shell/default-programs#full-registration-example) on registering a new file association, and this is the fruit.

## `Uninstall-WindowsPhotoViewer.ps1`

Unregisters the file association, strictly following [the documentation](https://docs.microsoft.com/en-us/windows/desktop/shell/how-to-register-a-file-type-for-a-new-application).

## `Use-MediaPreviewHandler.ps1`

Registers Windows Media Player as the preview handler for all supported extensions. This is different from registering it as the preview handler for the corresponding ProgIDs, because Windows shell will always find them even if they are associated with Photos app.

**Anecdote** iTunes actually supply Windows Media Player Preview Handler CLSID to its ProgIDs so that using iTunes as the default doesn’t break the ability to preview files in File Explorer.

## `Use-PdfThumbnailHandler.ps1`

Registers Adobe Reader DC as the thumbnail handler for `.pdf`. This is different from registering it as the thumbnail handler for the corresponding ProgIDs, because Windows shell will always find it even if `.pdf` is associated with another app (e.g., Microsoft Edge or MiKTeX). Therefore, this will allow you to see thumbnails for `.pdf` files (provided by Adobe Reader DC) and use Edge as its default program.

## `Set-ExplorerOptions.ps1`

Since some version of Windows (8/8.1/10?), it is very hard to run Explorer as another user while keeping basic usability. This is due to the fact that the *real* shell program is now `sihost.exe`. Since File Explorer Options controls how `IShellBrowser`/`IShellView` behaves. Specifically, you want to see hidden and system files and file extensions. It is possible to 

## `Open-EnvironmentVariableEditor.ps1`

Opens the environment variable editor. If no switch is supplied, the editor opens with the current user and privilege. Specify `-Machine` to launch the editor elevated, and `-User` to launch the editor as another user.

## `Open-ExplorerOptionsDialog`

Opens the File Explorer Options dialog. The usage is very limited as it only opens the dialog in the identity of the currently running File Explorer process, **not** who launched the dialog.

## `Install-LaunchPDF.ps1`

Installs a small utility that decides which program PDF files should open (TeXworks if the PDF has a corresponding TEX file; Adobe Reader DC otherwise). This works only if Adobe Reader DC is installed **for the machine** and MiKTeX is installed (for the user or the machine).

If Adobe Reader DC is installed on a per-user basis (not saying that it can at this moment), using this script might corrupt the file associations of Adobe Reader DC (use the installer to fix it if it so happens).

[CmdletBinding()]
Param()

Begin
{
    $outlook = New-Object -ComObject 'Outlook.Application'
    $mapi = $outlook.GetNamespace('MAPI')
}

Process
{
    $mapi.PickFolder()
}

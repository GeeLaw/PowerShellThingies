[CmdletBinding(DefaultParameterSetName='User')]
Param
(
    [Parameter(ParameterSetName='Machine', Mandatory=$True)]
    [switch]$Machine,
    [Parameter(ParameterSetName='User')]
    [switch]$User
)

Process
{
    If ($Machine)
    {
        Start-Process -FilePath 'rundll32.exe' -ArgumentList 'sysdm.cpl,EditEnvironmentVariables' -Verb 'runas';
    }
    ElseIf ($User)
    {
        Start-Process -FilePath 'rundll32.exe' -ArgumentList 'sysdm.cpl,EditEnvironmentVariables' -Verb 'runasuser';
    }
    Else
    {
        Start-Process -FilePath 'rundll32.exe' -ArgumentList 'sysdm.cpl,EditEnvironmentVariables';
    }
}

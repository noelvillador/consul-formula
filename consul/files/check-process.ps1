
Param
(
    [Parameter(Mandatory=$True, HelpMessage="Specify the location of the process to monitor")]
    [string]$Path,
    [Parameter(Mandatory=$True, HelpMessage="Specify the filename of the process to monitor")]
    [string]$App,
    [Parameter(Mandatory=$False, HelpMessage="Specify the filename of the sub-process to monitor")]
    [string]$SubApp="GenericScanner",
    [Parameter(Mandatory=$False, HelpMessage="Specify if module needs restart when terminated")]
    [bool]$ReStart = $False,
    [Parameter(Mandatory=$False, HelpMessage="Specify if force restart")]
    [bool]$Force = $False,
    [Parameter(Mandatory=$False, HelpMessage="Specify the threshold in minutes before restarting an application")]
    [int]$Threshold = 5,
    [Parameter(Mandatory=$False, HelpMessage="Specify the location of the script module")]
    [string]$ScriptModulePath="C:\consul.io\conf",
    [Parameter(Mandatory=$False, HelpMessage="Specify the SMTP server")]
    [string]$Server,
    [Parameter(Mandatory=$False, HelpMessage="Specify the email recipients")]
    [string]$EmailTo,
    [Parameter(Mandatory=$False, HelpMessage="Specify the email sender")]
    [string]$EmailFrom,
    [Parameter(Mandatory=$False, HelpMessage="Specify the mail user")]
    [string]$Username,
    [Parameter(Mandatory=$False, HelpMessage="Specify the mail password")]
    [string]$Password,
    [Parameter(Mandatory=$False, HelpMessage="Specify ssl option")]
    [string]$SSL,
    [Parameter(Mandatory=$False, HelpMessage="Specify data option")]
    [string]$data
    
)

$emailCheckFile =  "$($env:TEMP)\$($App).email"

Import-Module C:\consul.io\conf\PSCommon.psm1 -PassThru -Force
Write-Host 'Monitoring started'
$result = Get-GridProcessRunningOkay -Path $Path -App $App -SubApp $SubApp -ReStart $ReStart -Force $Force -Threshold $Threshold
if($result)
{
    Write-Host "Result is okay."
    if([System.IO.File]::Exists($emailCheckFile))
    {
        Remove-Item $emailCheckFile
    }
    exit 0;
}
else
{
    Write-Host "Result is not okay."        
    if(-not([string]::IsNullOrEmpty($Server)) -and -not([string]::IsNullOrEmpty($EmailTo)) -and -not([string]::IsNullOrEmpty($EmailFrom)))
    {
        if (![System.IO.File]::Exists($emailCheckFile))
        {
            Write-Host "Sending email."
            if(-not([string]::IsNullOrEmpty($Password)) -and -not([string]::IsNullOrEmpty($Username)))
            {
              $UserPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
              $EmailCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$UserPassword
            }
            Start-SendEmail -Credentials $EmailCredential -SSL $SSL -Server $Server -EmailTo $EmailTo -EmailFrom $EmailFrom -Subject "$($App) at $($env:computername) $($data) is down!!!"
            echo $null >> $emailCheckFile
        }else
        {
            Write-Host "sent email once, will not send again."
        }
    }
    exit 1;
}
Write-Host 'Monitoring ended'


<#
Param
(
    [Parameter(Mandatory=$True, HelpMessage="Specify the location of the process to monitor")]
    [string]$Path        
)

Import-Module $ScriptModulePath\PSCommon.psm1
Get-GridStringHash $Path
#>

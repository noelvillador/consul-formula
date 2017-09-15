
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
        [Parameter(Mandatory=$False, HelpMessage="Specify if you want to be notify when something is down.")]
		[bool]$NotifyByEmail = $False,	
		[Parameter(Mandatory=$False, HelpMessage="Specify the threshold in minutes before restarting an application")]
		[int]$Threshold = 5
	)


    Import-Module .\PSCommon.psm1
    Write-Host 'Monitoring started'
	$result = Get-GridProcessRunningOkay -Path $Path -App $App -SubApp $SubApp -ReStart $ReStart -Force $Force -Threshold $Threshold
    if($result)
    {
        Write-Host "Result is okay."
        exit 0;
    }
    else
    {
        Write-Host "Sending email."
        if($NotifyByEmail)
        {
            Start-SendEmail -EmailTo "romano_cabral@trendmicro.com"
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

	Import-Module .\PSCommon.psm1
	Get-GridStringHash $Path
#>
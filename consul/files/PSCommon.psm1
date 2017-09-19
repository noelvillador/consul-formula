<#
    
    Notes:

    No need to store here if import command is absolute path.
    Store this file here: C:\WINDOWS\System32\WindowsPowerShell\v1.0\Modules

    Installation:
    Remove-Module PSCommon
    Import-Module PSCommon.psm1 -PassThru -Force

    Testing:
    Invoke-Pester PCommon.tests.ps1 - To test
    Invoke-Pester -TestName "put describe here"
#>


<# 
    .SYNOPSIS 
        This function creates or appends a line to a log file. 
 
    .PARAMETER  Message 
        The message parameter is the log message you'd like to record to the log file. 
 
    .EXAMPLE 
        PS C:\> Write-Log -Message 'Value1' 
        This example shows how to call the Write-Log function with named parameters. 
    #>



# Global Variable
$PSLogTrace=""

function Write-Log 
{ 
     
    [CmdletBinding()] 
    param ( 
        [Parameter(Mandatory)] 
        [string]$Message,
        [Parameter(Mandatory)] 
        [string]$FileName 
    ) 
     
    try 
    { 
        Write-Host "FileName is $($FileName)"
        $DateTime = Get-Date -Format ‘MM-dd-yy HH:mm:ss’ 
        #$Invocation = "$($MyInvocation.MyCommand.Source | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)" 
        Add-Content -Path $FileName -Value "$DateTime - $Message"
    } 
    catch 
    { 
        Write-Error $_.Exception.Message 
    } 
}



<#
.DESCRIPTION
Converts the given string to hash equivalent.

.Return
hash

.Source
#http://jongurgul.com/blog/get-stringhash-get-filehash/ 

.Tested
Yes
#>
function Get-GridStringHash
{
    Param
    (
        [Parameter(Mandatory=$True, HelpMessage="String to calculate")]
        [string]$String,
        [Parameter(Mandatory=$False, HelpMessage="Specify the filename of the process")]
        [string]$HashName = "MD5"
    ) 
     
    #Write-Log "GridStringHash IN: $($String)" $Global:PSLogTrace

    $StringBuilder = New-Object System.Text.StringBuilder 
    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{ 
    [Void]$StringBuilder.Append($_.ToString("x2")) 
    }
     
    $result = $StringBuilder.ToString()

    #Write-Log "GridStringHash OUT: $($result)" $Global:PSLogTrace
        
    # return
    $result 
}


<#
.DESCRIPTION
Returns the filename of format md5.log for a given path.

.Return
env:\temp\md5.log

.Note
Do not put logging here as value of PSLog is not yet set.
 
.Tested
Yes

#>
function Get-GridComputeFileNameFromString
{
    Param
    (
        [Parameter(Mandatory=$True, HelpMessage="Path to calculate")]
        [string]$Path,
        [Parameter(Mandatory=$False, HelpMessage="String to append to filename")]
        [string]$Marker='marker'
    ) 

    $Md5 = Get-GridStringHash $Path
    "$($env:TEMP)\$($Md5)-$($Marker).log"
}




<#
.DESCRIPTION
Check the difference between current date and a given date.

.Return
True if within threshold
 
.Tested
Yes
#>
function Get-GridIsWithinThreshold
{

    Param
    (
        [Parameter(Mandatory=$True, HelpMessage="The given date")]
        [DateTime]$Date,
        [Parameter(Mandatory=$True, HelpMessage="Threshold in minute")]
        [int]$Threshold
    )

    Write-Log "GridIsWithinThreshold IN: $($Date) $($Threshold)" $Global:PSLogTrace

    $Current = Get-Date
    $TimeDiff = $Current.Subtract($Date)

    # days
    $hour = [int]($TimeDiff.TotalHours)
    $min = [int]($TimeDiff.TotalMinutes)

    # note: echo,return  and write-output sends output to stream, write-host sends to screen.
    #echo "Threshold=$($Threshold) vs. Min=$($min)"

    # prepare return
    $result = ( ($hr -gt 1) -or ($Threshold -gt $min) -or ($Threshold -eq $min) )

    Write-Log "GridIsWithinThreshold OUT: $($result)" $Global:PSLogTrace

}

<#
.DESCRIPTION
Start the given process w/o checking if already running

.Tested
Yes
#>
function Start-GridModule
{
    Param
    (
        [Parameter(Mandatory=$True, HelpMessage="Specify the folder where process is located")]
        [string]$Path,
        [Parameter(Mandatory=$True, HelpMessage="Specify the filename of the process")]
        [string]$App
    )     

    Write-Log "Start-GridModule OUT: $($Path) $($App)" $Global:PSLogTrace

    # Confirm path is valid
    if (!(Test-Path $Path))
    {
        Write-Error "Invalid path: $Path"
    }
    else 
    {
        if (((Get-ChildItem $path ).count) -gt 1)
        {

            # if exe exists
            $procName = "$path\$app"
            if (Test-Path $procName)
            { 
                Write-Log "$MyInvocation.MyCommand Starting $($procName)" $Global:PSLogTrace
                #echo "Starting module: " $procName
                Start-Process $procName
                Start-Sleep -Seconds 2
            }
        }
        else
        {
            Write-Log "$MyInvocation.MyCommand No files found in $($Path)" $Global:PSLogTrace
            Write-Error 'No files found in $($Path).'
        }    
    }

    Write-Log "Start-GridModule OUT:" $Global:PSLogTrace    
}



<#
.DESCRIPTION
Restart the given process.If !force, check the last restart if time diff is within threshold of 1 minutes.

.Return -1 if error/0 for success

.Tested
Yes
#>
function ReStart-GridModule
{
    Param
    (
        [Parameter(Mandatory=$True, HelpMessage="Specify the folder where process is located")]
        [string]$Path,
        [Parameter(Mandatory=$True, HelpMessage="Specify the filename of the process")]
        [string]$App,
        [Parameter(Mandatory=$False, HelpMessage="Specify child process")]
        [string]$SubApp = "",
        [Parameter(Mandatory=$False, HelpMessage="Specify the filename of the process")]
        [bool]$Force = $False,
        [Parameter(Mandatory=$False, HelpMessage="Specify the threshold in minutes before restarting an application")]
        [int]$Threshold = 5
    )

    Write-Log 'Get-GridProcessRunningOkay IN:' $Global:PSLogTrace
    
    $restart = $False

    $temp = Test-Path $Path
    if($temp)
    {
        if(((Get-ChildItem $Path).count) -gt 1)
        {
            $procName = "$Path\$App"
            if(Test-Path $procName)
            {
                # if sub-process exists
                if( -not ([string]::IsNullOrEmpty($SubApp)))
                {
                    Write-Debug 'Sub process stop.'

                    # kill the sub-process first
                    Stop-GridProcessByName $SubApp
                }

                # kill the actual process
                Stop-GridProcessByName $App

                # force restart?
                if($Force)
                {
                    Write-Log 'Get-GridProcessRunningOkay: Force-ReStart.' $PSLogTrace
                    Start-GridModule $Path $App
                    $restart = $True
                }
                else
                {                    
                    # consider timestamp
                    $logFile = Get-GridComputeFileNameFromString $Path
                    Write-Log "Get-GridProcessRunningOkay: Checking previous timestamp from file $($logFile)" $Global:PSLogTrace

                    if( !(Test-Path $logFile))
                    {
                        Write-Log "No previous file, restart the app" $Global:PSLogTrace
                        # restart
                        $restart = $True
                    }
                    else
                    {
                        $prevTime = Get-GridTimeStampFromFile $logFile
                        if( -Not (Get-GridIsWithinThreshold $prevTime $Threshold))
                        {
                            # restart
                            $restart = $True
                        }
                    }

                    if($restart)
                    {

                        Write-Log "Restarting app $($App)" $Global:PSLogTrace
                        Start-GridModule $Path $App

                        # update time
                        Save-GridTimeStampToATempFile $logFile 
                    }
                    else
                    {
                        Write-Log "GridProcessRunningOkay: Rejected, recently restarted." $Global:PSLogTrace
                    }         
                }
            }
        }
    }

    $temp = $null
    
    # return
    $restart             
}

<#
.DESCRIPTION
Stop the given process by name.Removes file extension if present.

.Return

#>
function Stop-GridProcessByName
{
    Param
    (
        [Parameter(Mandatory=$True, HelpMessage="Specify the filename of the process")]
        [string]$App
    )

    Write-Log "Stop-GridProcessByName IN: $($App)" $Global:PSLogTrace

    # remove extension
    $processName = [IO.Path]::GetFileNameWithoutExtension($App)

    # remove extension if present
    $proc = Get-Process $processName -ErrorAction SilentlyContinue
    if($proc) 
    {
        # try graceful exit
        $proc.CloseMainWindow()

        # pause
        Sleep 2

        #kill
        if(!$proc.HasExited)
        {
            $proc | Stop-Process -Force
        }
    }

    Write-Log "Stop-GridProcessByName OUT:" $Global:PSLogTrace

    Start-Sleep -Seconds 2
}


<#
.DESCRIPTION
Stop the given process by file.

.Return

#>
function Stop-GridProcessByPath
{
    Param
    (
        [Parameter(Mandatory=$True, HelpMessage="Specify the path of the process")]
        [string]$Path        
    )
    
    Write-Log "Stop-GridProcessByPath IN: $($Path)" $Global:PSLogTrace

    Get-Process | Where-Object {$_.Path -like $Path} | Stop-Process

    Write-Log "GridProcessByPath OUT:" $Global:PSLogTrace
}


<#
.DESCRIPTION
Save the timestamp to a file

.Return

.Tested

#>
function Save-GridTimeStampToATempFile
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True, HelpMessage="Specify the file to log")]
        [string]$Path                
    )

    Write-Log "Save-GridTimeStampToATempFile IN: $($Path)" $Global:PSLogTrace
    Get-Date -Format 'M.d.yyyy HH:mm:ss' | Out-File $Path -Force -NoNewline
    Write-Log "Save-GridTimeStampToATempFile OUT:" $Global:PSLogTrace
}


<#
.DESCRIPTION
Save the data to a file. Overwrites if file exists. No newline.

.Return

.Tested

#>
function Save-GridDataToATempFile
{
    Param
    (
        [Parameter(Mandatory=$True, HelpMessage="Specify the file to log")]
        [string]$Path,
        [Parameter(Mandatory=$True, HelpMessage="Specify data to write")]
        [string]$Data                
    )

    Write-Log "Save-GridDataToATempFile IN: $($Path) $($Data)" $Global:PSLogTrace

    $Data | Out-File $Path -Force -NoNewline

    Write-Log "Save-GridDataToATempFile OUT:" $Global:PSLogTrace
}


<#
.DESCRIPTION
Get the timestamp(dateTime) from a given file.

.Return
DateTime with specific format else $null

#>
function Get-GridTimeStampFromFile
{
    Param
    (
        [Parameter(Mandatory=$True, HelpMessage="Specify the file that contains dateTime format")]
        [string]$FileName                
    )


    $result = Get-Date -Format 'M.d.yyyy HH:mm:ss'
    if(Test-Path $FileName)
    {
        $content = Get-Content $FileName
        if( -Not (([string]::IsNullOrEmpty($Content))) )
        {
            $result = Convert-GridDateString -Date $Content -Format 'M.d.yyyy HH:mm:ss'
        }
    }

    # return
    $result
}


<#
.DESCRIPTION
Converts date in String to DateTime

.Return
DateTime with specific format else $null
 
.Souce
http://www.powershellmagazine.com/2013/07/08/pstip-converting-a-string-to-a-system-datetime-object/

#>

function Convert-GridDateString
{
    [CmdLetBinding()]
    Param
    (
        [Parameter(Mandatory=$True, HelpMessage="Specify date in string")]
        [string]$Date,
        [Parameter(Mandatory=$True, HelpMessage="Specify the date format")]
        [string]$Format                
    )

   $result = New-Object DateTime
 
   $convertible = [DateTime]::TryParseExact(
      $Date,
      $Format,
      [System.Globalization.CultureInfo]::InvariantCulture,
      [System.Globalization.DateTimeStyles]::None,
      [ref]$result)
 
   if ($convertible)
    {
         $result
    }
    else
    {
        $null
    }    
}


<#
.DESCRIPTION
Check if a process in hang state.

.Return
True or False.

.Tested.

#>
function Get-GridIsModuleHangUp
{

    Param
    (
        [Parameter(Mandatory=$True, HelpMessage="Specify the process to test")]
        [string]$ProcessName,
        [Parameter(Mandatory=$False, HelpMessage="Specify the threshold")]
        [int]$Threshold=5,
        [Parameter(Mandatory=$False, HelpMessage="Specify metrics to use")]
        [string]$Metric='M'
                        
    )

    Write-Log "GridIsModuleHangUp IN: $($ProcessName)" $Global:PSLogTrace

    # iterate for all process instance

    $result = $false
    $items = Get-Process -Name $ProcessName
    ForEach($item in $items)
    {
        # compute running time
        if(! ($item.HasExited) ) {
            $runningTime = New-TimeSpan -Start $item.StartTime

            $total = $runningTime.TotalMinutes
            if($Metric -eq 'S')
            {
                $total = $runningTime.TotalSeconds
            }

            if([int]$total -gt $Threshold)
            {
                Write-Debug 'above the limit'
                $result = $True
                break
            } else {
                Write-Debug 'below limit'
            }
        }
    }

    Write-Log "GridIsModuleHangUp OUT:" $Global:PSLogTrace

    # return
    $result
}




<#
.DESCRIPTION
Check if a process is in hangup state.

.Return
True or False.

#>
function Get-GridIsUpdating
 {
     [CmdLetBinding()]
     Param
    (
        [Parameter(Mandatory=$True, HelpMessage="Specify the path of process running.")]
        [string]$Path,
        [Parameter(Mandatory=$True, HelpMessage="Specify the process name.")]
        [string]$App                
    )

    Write-Log "GridIsUpdating IN: $($Path) $($App)" $Global:PSLogTrace
    
     # initialize return value
     $state = $false

     # get the write byte
     $new_value = Get-WmiObject Win32_Process -ComputerName "127.0.0.1" | ` 
            where {$_.Name -eq $App } | ` 
            foreach {"$($_.WriteTransferCount)"} 

     # check the previous value
     $logName = Get-GridComputeFileNameFromString $Path 'Update'
    
     # remove the return from the stream
     $exists = Test-Path $logName | Out-Null
     if(!($exists))
     {
         $exists = $null
         # if no prev value, let's assume it is updating...
         $state = $True
     }
     else
     {
         $exists = $null
         $previous_value = Get-Content $logName
         Write-Host "new value $($new_value) vs old value $($previous_value)"

         # compare the value
         $state = ($new_value -ne $previous_value)
     }

     # update the value to the file
     Save-GridDataToATempFile $logName $new_value
    
    Write-Log "GridIsUpdating OUT: $($state)" $Global:PSLogTrace

     # return
     $state
}



function Get-GridIsModuleRunning
{
    Param
    (
        [Parameter(Mandatory=$True, HelpMessage="Specify the filename of the process")]
        [string]$App
    )

    Write-Log "GridIsModuleRunning IN: $($App)" $Global:PSLogTrace

    # remove extension
    $processName = [IO.Path]::GetFileNameWithoutExtension($App)

    $result = $false
    # remove extension if present
    $proc = Get-Process $processName -ErrorAction SilentlyContinue
    if($proc) 
    {
        $result = $True
    }

    Write-Log "GridIsModuleRunning OUT: $($result)" $Global:PSLogTrace

    $result
}


<#

Return boolean
#>
function Get-GridProcessRunningOkay
{
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
        [int]$Threshold = 5
    )    

    # set global variable
    $Global:PSLogTrace = Get-GridComputeFileNameFromString $Path -Marker 'trace'

    Write-Log "Get-GridProcessRunningOkay IN:" $Global:PSLogTrace 

    # check if module is running, run otherwise
    $result = Get-GridIsModuleRunning $App
    if($result)
    {
        if(($App.Contains("MessageManager")) -or ($App.Contains("PafiWrapper")))
        {
            Write-Log "App $($App) is running." $Global:PSLogTrace            
            return $True
        }
        elseif($App.Contains("PAFI") -and (-not(Get-GridIsModuleHangUp $SubApp $Threshold)))
        {
            Write-Log "App $($App) is running." $Global:PSLogTrace
            return $True
        }
        elseif( Get-GridIsUpdating $Path $App )
        {
            Write-Log "App $($App) is updating." $Global:PSLogTrace
            return $True
        }
        else
        {
            Write-Log 'unknown' $Global:PSLogTrace
        }
    }

    # try to restart
    if($ReStart)
    {
        Write-Log "Restarting the application $($App)" $Global:PSLogTrace
        return ReStart-GridModule $Path $App $SubApp $Force $Threshold
    }

    Write-Log "Get-GridProcessRunningOkay OUT" $Global:PSLogTrace

}

<#
Send email.
#>
function Start-SendEmail
{
    Param
    (
        [Parameter(Mandatory=$False, HelpMessage="Specify the SMTP server")]
        [string]$Server= "192.168.18.186" ,
        [Parameter(Mandatory=$False, HelpMessage="Specify the email subject")]
        [string]$Subject="Server/App is down",
        [Parameter(Mandatory=$False, HelpMessage="Specify the email recipients")]
        [string]$EmailTo="romano_cabral@trendmicro.com, noel_villador@trendmicro.com, joanne_antido@trendmicro.com"
    )

    Write-Log "SendEmail IN: " $Global:PSLogTrace

    Write-Host "Sending email..." 
    $emailFrom = "grid@trendmicro.com"  
    Send-MailMessage -From $emailFrom -To $EmailTo -Body $Subject -Subject $Subject -SmtpServer $Server

    Write-Log "SendEmail OUT: " $Global:PSLogTrace
}

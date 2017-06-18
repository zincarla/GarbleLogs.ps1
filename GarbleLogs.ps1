<#
.SYNOPSIS
    Grabs Windows event logs from all providers and compiles them in one file
 
.DESCRIPTION
    Grabs Windows event logs from all providers and compiles them into a CMTrace compliant file for review. The events are sorted by time and the range is specified by parameters.
 
.PARAMETER LengthMinutes
    The length, in minutes, between the StartDateTime, and the last event to retrieve. (Default 20 minutes)
 
.PARAMETER StartDateTime
    A DateTime object of the date/time to start retrieving logs from. (Default, -LengthMinutes ago so the full span of logs is everything generated in the last LengthMinutes)
 
.PARAMETER SaveLocation
    Full path to where the CMTrace log should be saved. (Default, the executors desktop in "Events.log")
 
.OUTPUTS
    A CMTrace compliant log file with all events
 
.NOTES
    Version:        1.0
    Author:         <Name>
    Creation Date:  <Date>
    Purpose/Change: Initial script development
 
.EXAMPLE
    &"GarbleLogs.ps1"
 
.EXAMPLE
    &"GarbleLogs.ps1" -LengthMinutes 10 -StartDateTime ([DateTime]::Now.AddDays(-1)) -SaveLocation "C:\TempLogs\Events.log"
 
#>
#Requires -version 3
Param
(
    $LengthMinutes = 20,
    [DateTime]$StartDateTime = [DateTime]::Now.AddMinutes(-$LengthMinutes),
    $SaveLocation = (Join-Path $env:USERPROFILE "Desktop\Events.log")
)
 
#Convert the paramters into an XML Filter
$STime = $StartDateTime.ToUniversalTime().ToString("s")
$ETime = $StartDateTime.AddMinutes($LengthMinutes).ToUniversalTime().ToString("s")
$Time="*[System[TimeCreated[@SystemTime&gt;='"+$STime+"' and @SystemTime&lt;='"+$ETime+"']]]";
 
#Dynamically grab all available Log Providers
$LogPaths=@()
$LogProviders = Get-WinEvent -ListLog *
foreach($LogProvider in $LogProviders)
{
    $LogPaths+="<Select Path=`""+$LogProvider.LogName+"`">$Time</Select>"
}
 
#The amount of logs loaded so far. Used purely to supply progress
$I=1;
 
$EventLog=@()
foreach ($LogPath in $LogPaths)
{
    #Write status
    Write-Host "Reading logs for $LogPath"
    Write-Host ($I.ToString()+"/"+$LogPaths.Length.ToString())
    #Create Query
    $Query = "<QueryList><Query Id=`"0`" Path=`"Application`">"+$LogPath+"</Query></QueryList>"
    $XMLFilter = [XML]$Query
    #Grab all events based on the Query
    $NewLogs = get-winevent -FilterXML $XMLFilter -ErrorAction SilentlyContinue
    if ($NewLogs)
    {
        #If there are any, add it to the EventLog array
        $EventLog += $NewLogs
    }
    $I++;
    Write-Host ("Total Logs: "+$EventLog.Length.ToString())
}
#Sort the logs by time created.
Write-Host "Sorting Logs"
$EventLog = $EventLog | Sort-Object -Property TimeCreated
 
Write-Host "Saving Logs"
Remove-Item -Path $SaveLocation -Force -Confirm
#Save the log file
$I=0
foreach ($Log in $EventLog)
{
    #Write the event in CMTrace's format
    $ToWrite = "<![LOG["+$Log.Message.ToString().Replace("`r`n"," ").Replace("`r"," ").Replace("`n"," ")+"]LOG]!><time=`""+$Log.TimeCreated.ToString("HH:mm:ss.fffz")+"`" date=`""+$Log.TimeCreated.ToString("MM-dd-yyyy")+"`" component=`""+$Log.LogName+"`" context=`"`" type=`"1`" thread=`""+$Log.Id.ToString()+"`" file=`""+$Log.ProviderName+":1`">";
    $ToWrite | Out-File $SaveLocation -Append ascii
    $I++;
    Write-Host ($I.ToString()+"/"+$EventLog.Length.ToString())
}

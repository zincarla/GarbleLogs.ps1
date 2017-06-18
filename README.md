# GarbleLogs.ps1
GarbleLogs grabs Windows event logs from all providers and compiles them into a single CMTrace compliant file for review. The events are sorted by time and the range is specified by the user.

## Parameters
No parameters are mandatory due to defaults.
### LengthMinutes
The length, in minutes, between the StartDateTime, and the last event to retrieve. (Default 20 minutes)
### StartDateTime
A DateTime object of the date/time to start retrieving logs from. (Default, -LengthMinutes ago so the full span of logs is everything generated in the last LengthMinutes)
### SaveLocation
Full path to where the CMTrace log should be saved. (Default, the executors desktop in "Events.log")
## Usage
## To create a log
Can be used without paramters to save a file called "Events.log" to your desktop containing all events from the last 20 minutes.
```
&"<PathToScript>"
```
Or can be used to specify save location as well as the time and range of events to retrieve.
```
&"<PathToScript>" -LengthMinutes 10 -StartDateTime ([DateTime]::Now.AddDays(-1)) -SaveLocation "C:\TempLogs\Events.log"
```

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Persistent
#NoTrayIcon

NEW_RECORD_INTERVAL := 1 * 60 * 1000 ; first number is the number of minutes between checks
END_HOUR_PASSED_INTERVAL := 1 * 60 * 60 * 1000 ; first number is the number of hours between checks
START_HOUR := 22
END_HOUR := 0

; function to change content of the file done_today.txt
setDone(value)
{
    FileDelete, done_today.txt
    FileAppend, %value%, done_today.txt
}

; checks if the specified hour is between start and end hours(inclusive only to start hour)
inHourRange(hour, start_hour, end_hour)
{
    return (end_hour >= start_hour AND (hour >= start_hour AND hour < end_hour)) OR (end_hour < start_hour AND (hour >= start_hour OR hour < end_hour))
}

handleError(error_code)
{
    if(error_code != 0)
    {
        if(error_code == 1)
        {
            MsgBox, 20, Internet Consumption Manager, An error occurred while retrieving values online using the webdriver.`n`n`nDo you want to retry?
        }
        else if(error_code == 2)
        {
            MsgBox, 20, Internet Consumption Manager, An error occurred while adding the new record to the database file.`n`n`nDo you want to retry?
        }

        IfMsgBox, Yes
            runICM()
    }
}

; run the check
runICM()
{
    RunWait, icm.py, , Hide
    handleError(ErrorLevel)
}

; program starts execution here
; a check that runs at program startup if the end hour passed
Gosub, endHourCheck

; timers
SetTimer, newRecordCheck, %NEW_RECORD_INTERVAL%
SetTimer, endHourCheck, %END_HOUR_PASSED_INTERVAL%
Return

newRecordCheck:
; variable to check if the program already ran today
FileRead, done_today, done_today.txt

; check and run the program if between start hour and the end of the day (00 AM)
if(inHourRange(A_Hour, START_HOUR, END_HOUR) AND done_today == "0")
{
    SetTimer, , Off ; timer is disabled during file running to avoid double running
    setDone(1) ; sets the program to already run today regardless of errors(errors are retried using msg boxes)
    runICM()
    ; Run, report.txt, , Min ; open the report minimized for the user to read
    SetTimer, , On
}
Return

endHourCheck:
; variable to check if the program already ran today
FileRead, done_today, done_today.txt

; reset the done_today for the next day
if(!inHourRange(A_Hour, START_HOUR, END_HOUR) AND done_today == 1)
{
    setDone(0)
}
Return
#Get-WmiObject -List | Out-File -FilePath c:\wmi.txt
#Get-WmiObject win32_computersystem 
#Get-WmiObject Win32_Computersystem |  Format-List *
Get-WmiObject Win32_Processor | Format-List *ClockSpeed, CurrentVoltage, *Logical*, LoadPercentage
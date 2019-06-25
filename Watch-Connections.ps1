<#
.Notes
#=================================#
# Script: Watch-Connections.ps1   # 
# Author: Jordan Bradford         #
# GitHub: jrdnbradford            #
# Tested: PowerShell 5.1, Core 6  #
# License: MIT                    #
#=================================#

.Synopsis
Pings hostnames in file to alert if computers are connected.

.Description
This script requires an accompanying .txt or .csv file that contains
hostnames and/or IP addresses. The $FilePath variable should contain
the path to this file.

After getting the content from the file, the script pings each computer
and writes text to the prompt indicating the ping status. If running 
this script as a scheduled task and no computer is successfully pinged, 
the prompt closes. If at least one computer is pinged, it remains open 
until user interaction. 

There are differences between PowerShell 5 and Core 6's implementation of the
Test-Connection cmdlet. This script separates these two implementations to allow for
customized use of each version. See Microsoft's documentation for details.
#>

# Replace with the full path to a file containing hostnames/IP addresses
$FilePath = ""

if (!(Test-Path -Path $FilePath))
{
    Write-Host "No file found at $FilePath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    Exit
}

$Computers = Get-Content -Path $FilePath
if ($Computers.Length -eq 0) 
{
    Exit
}
    
$Success = $False
ForEach ($Computer in $Computers) 
{
    if ($PSVersionTable.PSVersion.Major -eq 6)
    {   # PowerShell Core 6
        $Online = Test-Connection -TargetName $Computer -Count 1 -Ping -TimeoutSeconds 1 -ErrorAction SilentlyContinue 
    }
    else 
    {   # PowerShell <= 5.1
        $Online = Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue
    }

    if ($Online)
    { 
        Write-Host "$Computer is online" -ForegroundColor Green
        $Success = $True
    }
    else 
    {
        Write-Host "$Computer isn't online/resolving" -ForegroundColor Red
    }
}

if ($Success)
{   # If running as scheduled task, keeps shell open if at least one computer is pingable
    Read-Host "At least one computer is online. Press Enter to exit"
}
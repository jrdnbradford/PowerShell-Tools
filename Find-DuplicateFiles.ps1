<#
.Notes
#==================================#
# Script: Find-DuplicateFiles.ps1  # 
# Author: Jordan Bradford          #
# GitHub: jrdnbradford             #
# Tested: PowerShell Core 6        #
# License: MIT                     #
#==================================#

.Synopsis
Checks for duplicate files and creates a txt 
file that shows duplicate file locations.
#>

# Include subdirectories in user folder to check for duplicates
$SearchDirectories = @("Desktop", "Documents", "Downloads")

# Set home folder
if ($IsMacOS) {
    $UserFolder = $env:HOME
}
if ($IsWindows) {
    $UserFolder = $env:USERPROFILE
}   

# Set results file name
$ResultsFile = "$UserFolder/Desktop/results.txt"
if (Test-Path -Path $ResultsFile) {
    $I = 0
    do {
        $I++
        $ResultsFile = "$UserFolder/Desktop/results($I).txt"
    } while (Test-Path -Path $ResultsFile)
}

# Create hashtable with full filenames as keys and file hashes as values
$HashTable = @{}
foreach ($Directory in $SearchDirectories) {
    $Folder = "$UserFolder/$Directory"
    Write-Progress -Activity "Getting files..."
    $Files = Get-ChildItem -Path $Folder -Recurse -File 
    
    # For progress bar within hashtable loop
    $TotalFiles = $Files.Length
    $I = 0

    # Create hashtable
    $Files | ForEach-Object {
        $FullFileName = $_.FullName
        $Hash = (Get-FileHash $FullFileName -Algorithm SHA256).Hash
        $HashTable[$FullFileName] = $Hash
     
        # Progress bar
        $I++
        $Pct = [Math]::Round($I / $TotalFiles * 100)
        Write-Progress -Activity "Processing files in $Folder..." -Status "Progress-> $Pct%" -PercentComplete $Pct
    }
}

Remove-Variable -Name Files

# For progress bar within while loop
$TotalFiles = $HashTable.Count

# Check for files with identical hashes in hashtable
$DataClone = $HashTable.Clone()
while ($HashTable.Count -gt 1){
    $FirstPair = $HashTable.GetEnumerator() | Select-Object -First 1
    $FirstPairKey = $FirstPair.Key
    $FirstPairValue = $FirstPair.Value
    
    $Duplicates = @()
    foreach ($Key in $HashTable.Keys) {
        # If values (hashes) are identical and keys (full filenames) are not
        if (($HashTable[$Key] -eq $FirstPairValue) -and ($Key -ne $FirstPairKey)) {
            # After finding duplicate file, add location 
            # to array and remove it from cloned data
            $Duplicates +=, $Key
            $DataClone.Remove($Key)
        }   
    }
    # After checking hashtable pair, remove it from cloned data
    $DataClone.Remove($FirstPairKey)
    
    # Satisfied if at least 1 duplicate
    if ($Duplicates) {
        @($FirstPairValue, $FirstPairKey, $Duplicates, "`r`n" ) | Out-File -FilePath $ResultsFile -Append
    }
    
    # Progress bar
    $Pct = [Math]::Round(100 - (($DataClone.Count / $TotalFiles) * 100)) 
    Write-Progress -Activity "Checking for duplicates..." -Status "Progress-> $Pct%" -PercentComplete $Pct

    $HashTable = $DataClone.Clone()
} # End while

# Open created results file if it exists
if (Test-Path -Path $ResultsFile){
    Write-Host "Complete! See $ResultsFile for details." -ForegroundColor Green
    if ($IsMacOS) {
        Open $ResultsFile -a TextEdit
    }
    if ($IsWindows) {
        Notepad $ResultsFile
    }   
} else {
    Write-Host "Complete! No duplicates." -ForegroundColor Green
} 
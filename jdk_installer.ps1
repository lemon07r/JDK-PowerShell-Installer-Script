Write-Host "`nJDK PowerShell Installer Script 2023-1-18"
Write-host "Author - Lamim / lemon07r"
Write-Host "-----------------------------------------`n"
Write-Host "Checking for Adminstrator permissions and self-elevating if required.."

# Pause function with any key to continue
function anyKeyPause {
    Write-Host -NoNewLine 'Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

# Self-elevate the script if required, and keep working directory
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        Write-Host "Insufficient permissions. `nAttempting to elevate priveledges, please accept the following prompt or run this script as admin."
        anyKeyPause
        $CommandLine = "-NoExit -c `"cd '$pwd'; & '" + $MyInvocation.MyCommand.Path + "'`""
        Start-Process powershell -Verb runas -ArgumentList $CommandLine
        Exit
    }
}
Write-Host "Success! Permissions check passed.`n"

# Make sure working directory is not system32 from running script as admin
$sys32dir = [Environment]::SystemDirectory
if ((Get-Item .).FullName -eq $sys32dir) {
    Set-Location -Path $PSScriptRoot
}

# Open file select dialog to select JDK zip
Write-Host "Please select the *.zip file containing your desired JDK version to install.`n"
while ($true) {
    anyKeyPause
    Add-Type -AssemblyName System.Windows.Forms
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
        Filter = 'ZIP Archive (*.zip)|*.zip'
    }
    $null = $FileBrowser.ShowDialog()
    Write-Host "`nSelected .zip File: `n $($FileBrowser.FileName)"

    # Check selected .zip file for JDK java binary
    Write-Host "`nChecking selected ZIP archive for JDK.."
    [Reflection.Assembly]::LoadWithPartialName( "System.IO.Compression.FileSystem" ) | Out-Null;
    $zipContents = [System.IO.Compression.ZipFile]::OpenRead($FileBrowser.FileName);  
    $zipContents.Entries | ForEach-Object {
        if ($_.Name -match "java.exe") {
            # Leave loop if java binary is found
            break
        }
    }
    # Loop back if no java binary found in selected .zip file
    Write-Host "`nNo JDK found in selected ZIP archive."
    Write-Host "Please select a valid JDK ZIP archive.`n"
}

# Get JDK Name/Version from parent folder in .zip archive
$JDKName = (($zipContents.Entries | Where-Object FullName -match '/' | Select-Object -First 1).Fullname -Split '/')[0]
Write-Host "`nSuccess! JDK Found."
Write-Host $JDKName

# Select directory to install the JDK
while ($true) {
    Write-Host "`nPlease enter a relative or absolute path to install JDK. Directory will be created if non-existant."
    $defaultDir = "$Env:Programfiles\Java\$($JDKName)"
    $selectedDir = Read-Host "Leave blank to use `"$($defaultDir)`""
    $selectedDir = ($defaultDir, $selectedDir)[[bool]$selectedDir]

    Write-Host "`nSelected install Directory: `n`"$($selectedDir)`""

    # Check directory
    if (Test-Path -Path $selectedDir\*) {
        Write-Host "This directory is not empty."
        Get-ChildItem -recurse -filter "java.exe" -file -Path $selectedDir -ErrorAction SilentlyContinue | foreach-object {
            Write-Host "There is a JDK already installed here."
        }
        Write-Host "Please select a different install directory."
    } 
    elseif (Test-Path -Path $selectedDir) {
        Write-Host "Path is valid."
        break
    }
    else {
        # Create directory if it doesn't exist
        Write-Host "Path doesn't exist. Creating directory."
        $createDir = New-Item -ItemType Directory -Force -Path $selectedDir
        Write-Host $createDir.FullName
        $selectedDir = $createDir.FullName
        if (Test-Path -Path $selectedDir) {
            Write-Host "Success! Target directory created."
            break
        }
        else {
            Write-Host "Unable to create directory, please try a different path."
        }
    }
}

anyKeyPause
# Extract JDK from archive
Write-Host "`n Extracting JDK from ZIP archive to target directory.."
Expand-Archive $FileBrowser.FileName $selectedDir
Move-Item "$($selectedDir)\$($JDKName)\*" $selectedDir
Write-Host "Extraction complete."

# Add PATH environment variable helper function, since SETX causes issues.
# https://stackoverflow.com/a/69239861
function Add-Path {

    param(
      [Parameter(Mandatory, Position=0)]
      [string] $LiteralPath,
      [ValidateSet('User', 'CurrentUser', 'Machine', 'LocalMachine')]
      [string] $Scope 
    )
  
    Set-StrictMode -Version 1; $ErrorActionPreference = 'Stop'
  
    $isMachineLevel = $Scope -in 'Machine', 'LocalMachine'
    if ($isMachineLevel -and -not $($ErrorActionPreference = 'Continue'; net session 2>$null)) { throw "You must run AS ADMIN to update the machine-level Path environment variable." }  
  
    $regPath = 'registry::' + ('HKEY_CURRENT_USER\Environment', 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment')[$isMachineLevel]
  
    # Note the use of the .GetValue() method to ensure that the *unexpanded* value is returned.
    $currDirs = (Get-Item -LiteralPath $regPath).GetValue('Path', '', 'DoNotExpandEnvironmentNames') -split ';' -ne ''
  
    if ($LiteralPath -in $currDirs) {
      Write-Verbose "Already present in the persistent $(('user', 'machine')[$isMachineLevel])-level Path: $LiteralPath"
      return
    }
  
    $newValue = ($currDirs + $LiteralPath) -join ';'
  
    # Update the registry.
    Set-ItemProperty -Type ExpandString -LiteralPath $regPath Path $newValue
  
    # Broadcast WM_SETTINGCHANGE to get the Windows shell to reload the
    # updated environment, via a dummy [Environment]::SetEnvironmentVariable() operation.
    $dummyName = [guid]::NewGuid().ToString()
    [Environment]::SetEnvironmentVariable($dummyName, 'foo', 'User')
    [Environment]::SetEnvironmentVariable($dummyName, [NullString]::value, 'User')
  
    # Finally, also update the current session's `$env:Path` definition.
    # Note: For simplicity, we always append to the in-process *composite* value,
    #        even though for a -Scope Machine update this isn't strictly the same.
    $env:Path = ($env:Path -replace ';$') + ';' + $LiteralPath
  
    Write-Verbose "`"$LiteralPath`" successfully appended to the persistent $(('user', 'machine')[$isMachineLevel])-level Path and also the current-process value."
  
  }

# Set environment variables
Write-Host "`nSetting PATH and JAVA_HOME environment variables"
setx /M JAVA_HOME "$($selectedDir)"
Add-Path $selectedDir\bin

Write-Host "`nJDK Installation complete."

anyKeyPause
Exit

# JDK PowerShell Installer Script
A robust PowerShell script for easily installing any JDK from ZIP archive

## Todo
Nothing. This is feature complete. Feel free to use this to make your own version how you want. 

## Features
- Easy to use, predictable behaviour and easy to understand.
- Lots of checks in place to prevent broken installs. 
- Self elevates for required admin rights, and keeps working directory.
- Easy ZIP archive selection with file dialogue.
- Validates ZIP archive for JDK. Won't accept non-JDK zip archives. 
- Accepts both relative and absolute paths. 
- Changes working directory to execution directory from system32 to prevent accidental installs to the system directory if script is started as admin from context menu.
- No file deleting code whatsoever. Only installs to empty directory. Creates directory if non-existant.
- Defaults to Program Files\Java\{detected JDK name/version}\ on blank entry for quick installs.
- Sets both PATH and JAVA_HOME environment variables after extraction. 
- Uses [helper function](https://stackoverflow.com/a/69239861) instead of setx /M, which is known to have issue causinglimitations (e.a. deleting entire PATH values).

## Usage
1. Go to https://github.com/lemon07r/JDK-PowerShell-Installer-Script/blob/main/jdk_installer.ps1
Download the script file by right clicking Raw, then "Save link as".
Or copy and paste the code into your editor of choice then save it as a .ps1 file.
2. Run the saved .ps1 script as Administrator. You can do this by opening PowerShell as admin, and executing the script directly from there, or if you [Set-ExecutionPolicy](https://superuser.com/questions/106360/how-to-enable-execution-of-powershell-scripts) to allow scripts to run from other sources, this script will automatically prompt for admin rights to elevate it self.
3. Now just follow the on-screen instructions, they're straightforward and simple enough. Make sure you have the JDK .zip you want to install from downloaded. This script works with most JDK versions, including various OpenJDK, and GraalVM EE distributions.

## Screenshots
<img width="725" alt="image" src="https://user-images.githubusercontent.com/12001338/213161263-b26bb396-e9e7-4fd0-89ce-ea3884f82fb7.png">
<img width="855" alt="image" src="https://user-images.githubusercontent.com/12001338/213161550-270515f6-e524-460b-9ba6-7d1fd2d632c3.png">

## License
[MIT License](https://github.com/lemon07r/JDK-PowerShell-Installer-Script/blob/main/LICENSE)

Copyright (c) 2023 Lamim

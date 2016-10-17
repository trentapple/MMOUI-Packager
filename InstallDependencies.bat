REM Install Chocolatey:
echo ## Step 1: ##
@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

REM Install Curl and 7-Zip:
echo ## Step 2: ##
choco install -y curl 7zip

echo ## Note: ##
echo ( Please note this script must be run as local administrator -- 
echo there is a non-administrator setup, but is generally recommended as a last resort. 
echo Read more: https://chocolatey.org/install#non-administrative-install )

echo ## Complete! ##

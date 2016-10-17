# MMOUI-Packager
Simple PowerShell Script used for automatically parsing/incrementing AddOn version, packaging, and uploading AddOn. Currently the AddOn is configured for the first version of AddOn API at ESOUI.com.

## Dependencies:
* 7-Zip
* curl (for multipart form uploading)

## Instructions:
This addon assumes you will retain the default directory structure of the "Elder Scrolls Online" folder and that it will be located directly within the %USERPROFILE%\Documents\ directory. Please refer to the script's parameters.

## Example Usage:
	powershell PackageAndRelease -projectDirName AddOnFolderName -incrementVersionNumber -uploadToEsoui -openExplorer

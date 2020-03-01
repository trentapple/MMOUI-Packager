<#
 # Simple ESOUI API Package & Upload PowerShell Script
 # 	Author: Trent Apple
 # 
 # 	Dependencies:
 # 		* 7-Zip
 # 		* curl (for multipart form uploading)
 # 
 # 	Instructions: This addon assumes you will retain the default directory structure 
 # 		of the "Elder Scrolls Online" folder and that it will be located directly within 
 # 		the %USERPROFILE%\Documents\ directory. Please refer to the script's parameters.
 #>
 param (
	[string]$projectDirName,
	[switch]$incrementVersionNumber,
	[switch]$noCopyIncrementedVersionNumberToClipboard,
	[switch]$openExplorer,
	[switch]$uploadToEsoui,
	[string]$compatibility = "5.3.4", # Harrowstorm (100030)
	[string]$defaultSevenZipPath = "C:\PROGRA~1\7-Zip\7z.exe",
	[string]$esouiApiToken # *or* Environment Variable: ESOUI_API_TOKEN
)

if ([string]::IsNullOrEmpty($esouiApiToken))
{
	# Attempt to get value from environment variable
	if (![string]::IsNullOrEmpty($env:ESOUI_API_TOKEN))
	{
		$esouiApiToken = $env:ESOUI_API_TOKEN;
	}
	else
	{
		Write-Debug -Message "No included -esouiApiToken command line argument or ESOUI_API_TOKEN environment variable found."
	}
}

New-Alias Out-Clipboard $env:SystemRoot\system32\clip.exe

filter Select-MatchingGroupValue($groupNum)
{
    if (! $groupNum)
	{
        $groupNum = 0
    }
   Select-Object -InputObject $_ -ExpandProperty Matches |
        Select-Object -ExpandProperty Groups |
        Select-Object -Index $groupNum |
        Select-Object -ExpandProperty Value
}

$elderScrollsOnlineAddOnPath = Join-Path $env:USERPROFILE -ChildPath "Documents" | Join-Path -ChildPath "Elder Scrolls Online" | Join-Path -ChildPath "live" | Join-Path -ChildPath "AddOns" 

$projectArchiveName = ("{0}.zip" -f $projectDirName)

$projectArchiveFilePath = Join-Path $elderScrollsOnlineAddOnPath -ChildPath $projectArchiveName

$projectPath = Join-Path $elderScrollsOnlineAddOnPath -ChildPath $projectDirName

$projectTxtName = ("{0}.txt" -f $projectDirName)

$projectTxtFilePath = Join-Path $projectPath -ChildPath $projectTxtName

$currentVersion = Get-Content $projectTxtFilePath -ErrorAction SilentlyContinue |
	Select-String '^## Version: (.*)' |
	Select-Object -First 1 |
	Select-MatchingGroupValue 1

Write-Host "Current Version: $currentVersion"

$versionTokens = $currentVersion.Split(".")

$major = [int]( $versionTokens[0])
$minor = [int]( $versionTokens[1])
$patch = [int]( $versionTokens[2])

$newVersion = $currentVersion

if ($incrementVersionNumber)
{
	if ( $minor -cge 9 -and $patch -cge 9 )
	{
		$major = $major + 1
		$minor = 0
		$patch = 0
	}
	elseif ( $patch -cge 9 )
	{
		$minor = $minor + 1
		$patch = 0
	}
	else
	{
		$patch = $patch + 1
	}

	$newVersion = ([string] $major) + "." + ([string] $minor ) + "." + ([string] $patch)

	Write-Host "New Version (Incremented): $newVersion"

	if (!$noCopyIncrementedVersionNumberToClipboard)
	{
		$newVersion | Out-Clipboard
	}

	# Create Version String
	$newVersionWriteString = '## Version: ' + $newVersion

	(get-content -ErrorAction SilentlyContinue $projectTxtFilePath) | foreach-object -ErrorAction SilentlyContinue {$_ -replace '^## Version: (.*)', $newVersionWriteString} | set-content -ErrorAction SilentlyContinue $projectTxtFilePath
}

if (Test-Path $projectArchiveFilePath)
{
	Remove-Item $projectArchiveFilePath
}

if (Test-Path $defaultSevenZipPath)
{
	# Perform packaging using 7z (create .zip archive)
	Invoke-Expression "$defaultSevenZipPath a -tzip '$projectArchiveFilePath' '$projectPath' '-x!$projectDirName\.idea' '-x!$projectDirName\.git*'"
	
	if ($openExplorer)
	{
		Invoke-Expression "explorer '/select,""$projectArchiveFilePath""'"
	}

	if ($uploadToEsoui -and ![string]::IsNullOrEmpty($esouiApiToken))
	{
		# Get List of Addons
		$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
		$headers.Add("x-api-token", $esouiApiToken)

		# Curl Command: curl -k -H "x-api-token: <apiToken>" https://api.esoui.com/addons/list.json
		$listResponse = Invoke-RestMethod 'https://api.esoui.com/addons/list.json' -Headers $headers
		
		# Fetch the Addon's Details -- match addon id based upon name of last packaged zip file uploaded.
		$matchedAddOn = $listResponse | ForEach-Object { 
			Invoke-RestMethod ($_.details) -Headers $headers | 
			ForEach-Object { 
				if ($_.filename -match $projectArchiveName) { $_ } 
			} | Select-Object -First 1 
		}

		Write-Output $matchedAddOn
		
		$matchedAddonId = $matchedAddOn.id

		Write-Output "New Version: $newVersion"

		# Upload Addon to ESOUI API -- Current solution requires the installation of curl for Windows. You may use Chocolately (recommended) or manually download to install.
		$exec = ('cmd /C curl -k -H "x-api-token:' + $esouiApiToken + '" -F "id=' + $matchedAddonId + '" -F "version=' + $newVersion + '" -F "compatible=' + $compatibility + '" -F "updatefile=@' + $projectArchiveFilePath + '" https://api.esoui.com/addons/update')

		Invoke-Expression $exec

		<#
		# Upload Addon to ESOUI API -- Would not properly function the same way that the following behaves: `curl -H ... -F ... -F ... -F "updatefile=@C:..." uri`
		$FileContent = [IO.File]::ReadAllBytes($projectArchiveFilePath);

		$updatePostParams = @{
			'id' = $matchedAddOn.id;
			'version' = $newVersion;
			'updatefile' = $FileContent;
		}

		# https://api.esoui.com/addons/updatetest
		Invoke-RestMethod -Uri 'https://api.esoui.com/addons/updatetest' -Method Post -Headers $headers -Body $updatePostParams
		#>
	}
}
else
{
	Write-Error -Message "7-Zip path in script appears to be missing or invalid. Is it installed?"
}

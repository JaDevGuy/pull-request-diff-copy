[CmdletBinding()]
param()

$workingDir = $env:SYSTEM_DEFAULTWORKINGDIRECTORY 
$destination = Get-VstsInput -Name destination -Require
#$changeTypeInput = Get-VstsInput -Name changeType -Require  ## TODO
$shouldFlattenInput = Get-VstsInput -Name flatten  
$shouldContentGenerationInput = Get-VstsInput -Name contentGeneration  
$utf8withBOM = Get-VstsInput -Name utf8withBOM

[boolean]$shouldFlatten = [System.Convert]::ToBoolean($shouldFlattenInput) 
[boolean]$shouldContentGeneration = [System.Convert]::ToBoolean($shouldContentGenerationInput) 

$changeType = "A,C,M,R,T"

$buildReason = $env:BUILD_REASON # PullRequest
if ($buildReason -ne "PullRequest")
{
	"Pull Request Diff Copy will only process when triggered by Pull Request Build."
	return;
}

$branchName = ($env:SYSTEM_PULLREQUEST_SOURCEBRANCH).Replace("refs/heads/","")
$targetBranch = ($env:SYSTEM_PULLREQUEST_TARGETBRANCH).Replace("refs/heads/","")

"SYSTEM_PULLREQUEST_SOURCEBRANCH:" + ($env:SYSTEM_PULLREQUEST_SOURCEBRANCH) 
"SYSTEM_PULLREQUEST_TARGETBRANCH："+($env:SYSTEM_PULLREQUEST_TARGETBRANCH)
"buildReason is $buildReason"
"branchName is $branchName"
"targetBranch is $targetBranch"
"UTF-8 with BOM is $utf8withBOM"

try {
   
	"Setting working directory to: $workingDir" 
	Set-Location $workingDir

	"Get $branchName merge-base to $targetBranch"

	$expressCmd = "git merge-base 'refs/remotes/origin/$targetBranch' 'refs/remotes/origin/$branchName'"

	"Invoke-Expression " + $expressCmd

	$cmdResult = Invoke-Expression $expressCmd

	foreach ($result in $cmdResult)
	{
		$sha = $result
		
		"Command [$expressCmd] return commit id: " + $sha
	}

	$expressCmd = "git diff '$sha' 'refs/remotes/origin/$branchName' --name-status"

	"Invoke-Expression " + $expressCmd

	$diffResult = Invoke-Expression $expressCmd
	
	foreach ($r in $diffResult)
	{
		if($r -eq "") 
		{
			return;
		}

		"get changed file: " + $r

		$item = $r.Split([char]0x0009);

		$item[0] = $item[0].substring(0,1)
		
		if($changeType.Contains($item[0]))
		{
				if($item[0].Contains("R")){
					$changes += ,$item[2]
				} else {
					$changes += ,$item[1]
				}
		}
	}

	# if we should generate the content folder with all the diffed files?

	"Clean up the diff folder first ... "
	if(Test-Path -Path $destination){
		Remove-Item -Recurse -Force $destination
		mkdir $destination
	}

	$destinationContentFolder = join-path $destination "Content"

	if(Test-Path -Path $destinationContentFolder ){
		Remove-Item -Recurse -Force $destinationContentFolder
		mkdir $destinationContentFolder
	}

	if ($shouldContentGeneration)
	{

		"Copy changes to folder " + $destination
		if($shouldFlatten)
		{
			 $changes | foreach {			
				 $destinationPath = join-path $destinationContentFolder $_.Split("/")[$_.Split("/").Length-1];
				 "destinationPath is: " + $destinationPath 
				Copy-Item $_ -Destination "$destinationPath"
			 } 
		}
		else
		{
			$changes | foreach {
			#"ready copy change file: " + $_ 
			$destinationPath = join-path $destinationContentFolder $_;
			"destinationPath is: " + $destinationPath
			New-Item -ItemType File -Path "$destinationPath" -Force | out-null
			Copy-Item $_ -Destination "$destinationPath" -recurse -container;
			}
		}
	}

	# Determine if we need BOM with UTF-8 
	$utf8Bom = New-Object System.Text.UTF8Encoding $False
	if ($utf8withBOM)
	{
		$utf8Bom = New-Object System.Text.UTF8Encoding $True
	}

	$destinationPath = join-path $destination "diff.txt"
	"Generate diff.txt in " + $destinationPath + " with " + $utf8Bom.EncodingName 
	if ( -not (Test-Path -Path $destinationPath)){
		New-Item -ItemType File -Path "$destinationPath" -Force | out-null
	}
	[System.IO.File]::WriteAllLines($destinationPath, $diffResult, $utf8Bom)

 } finally {
   
	if ($LastExitCode -ne 0) { 
		Write-Error "Something went wrong. Please check the logs."
	}
 }

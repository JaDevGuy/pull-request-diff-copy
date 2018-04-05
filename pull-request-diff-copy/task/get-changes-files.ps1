[CmdletBinding()]
param()

$workingDir = $env:SYSTEM_DEFAULTWORKINGDIRECTORY 
$destination = Get-VstsInput -Name destination -Require
#$changeTypeInput = Get-VstsInput -Name changeType -Require  ## TODO
$shouldFlattenInput = Get-VstsInput -Name flatten  
$isCurrent = Get-VstsInput -Name currentCommit  

#$changeType = $changeTypeInput.split(",")
[boolean]$shouldFlatten = [System.Convert]::ToBoolean($shouldFlattenInput) 
#[boolean]$isCurrentCommit = [System.Convert]::ToBoolean($isCurrent) 

# $workingDir = $env:SYSTEM_DEFAULTWORKINGDIRECTORY 
# $destination = "diff"
$changeType = "A,C,M,R,T"
# $shouldFlatten = $False
# $isCurrentCommit = $False

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

if (!($env:SYSTEM_ACCESSTOKEN ))
{
   throw ("OAuth token not found. Make sure to have 'Allow Scripts to Access OAuth Token' enabled in the build definition.")
}

try {
   
	"Setting working directory to: $workingDir" 
	Set-Location $workingDir
	
	#git config core.quotepath off
	
	#git config --global gui.encoding utf-8            
	#git config --global i18n.commit.encoding utf-8    
	#git config --global i18n.logoutputencoding utf-8  
	#git config  i18n.logoutputencoding gbk
	
	#git checkout $targetBranch	
	#git checkout $branchName
	
	"Get $branchName merge-base to $targetBranch"

	$expressCmd = "git merge-base $env:SYSTEM_PULLREQUEST_TARGETBRANCH $env:SYSTEM_PULLREQUEST_SOURCEBRANCH"

	$expressCmd

	& $expressCmd | foreach
	{
		$sha = $_
		
		"Command [$expressCmd] return commit id: " + $sha
	}

	$expressCmd = "git diff $sha $env:SYSTEM_PULLREQUEST_SOURCEBRANCH --name-status"

	$expressCmd

	& $expressCmd > diff.txt
	
	& $expressCmd | foreach
	{
		if($_ -eq "") 
		{
			return;
		}

		"get changed file: " + $_

		$item = $_.Split([char]0x0009);

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

	"Copy changes to folder " + $destination
	$destinationContentFolder = join-path $destination "Content"
	IF($shouldFlatten)
	{
		 $changes | foreach {			
			 $destinationPath = join-path $destinationContentFolder $_.Split("/")[$_.Split("/").Length-1];
			 "destinationPath is: " + $destinationPath 
		   if(-not (Test-Path -Path $destination )){
				 mkdir $destination
			}
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

	$destinationPath = join-path $destination "diff.txt"
	"Copy diff.txt into " + $destinationPath
	Copy-Item diff.txt -Destination "$destinationPath"
	
 } finally {
   
	if ($LastExitCode -ne 0) { 
		Write-Error "Something went wrong. Please check the logs."
	}
 }

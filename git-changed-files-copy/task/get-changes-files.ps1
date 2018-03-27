[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

#[CmdletBinding()]
#param()

 $workingDir = $env:SYSTEM_DEFAULTWORKINGDIRECTORY 
 $currentCommit = $env:BUILD_SOURCEVERSION
# $destination = Get-VstsInput -Name destination -Require
# $changeTypeInput = Get-VstsInput -Name changeType -Require
# $shouldFlattenInput = Get-VstsInput -Name flatten 
# $changeType = $changeTypeInput.split(",")
# [boolean]$shouldFlatten = [System.Convert]::ToBoolean($shouldFlattenInput)

$workingDir = $env:SYSTEM_DEFAULTWORKINGDIRECTORY 
$currentCommit = $env:BUILD_SOURCEVERSION
$destination = "diff"
#$shouldFlattenInput = Get-VstsInput -Name flatten 
$changeType = "A,C,M,R,T"
$shouldFlatten = $False
$buildReason = $env:BUILD_REASON # PullRequest
# $branchName =  $env:BUILD_SOURCEBRANCHNAME
$branchName = $env:SYSTEM_PULLREQUEST_SOURCEBRANCH
$targetBranch = $env:SYSTEM_PULLREQUEST_TARGETBRANCH

"buildReason is $buildReason,branchName is $branchName, targetBranch is $targetBranch"

if (!($env:SYSTEM_ACCESSTOKEN ))
{
    throw ("OAuth token not found. Make sure to have 'Allow Scripts to Access OAuth Token' enabled in the build definition.")
}
	
# For more information on the VSTS Task SDK:
# https://github.com/Microsoft/vsts-task-lib
#Trace-VstsEnteringInvocation $MyInvocation
try {
	Write-Verbose "Setting working directory to '$workingDir'."
    Set-Location $workingDir
	Write-Verbose "Current commit is $currentCommit"	
	
	git checkout $targetBranch

	git config core.quotepath off
	
	git checkout $branchName

	git merge-base master head | foreach{
		$sha = $_
		"head commit:" + $sha
	}  

	##[System.Collections.ArrayList]$changes = @();
	## write-host "##[command]"git log -m -1 --name-status --pretty="format:" $currentCommit
	
	##git log -m -1 --name-status --pretty="format:" $currentCommit | foreach{
	git diff $sha head --name-status > diff.txt
	git diff $sha head --name-status | foreach{
	if($_ -eq "") {
		return;
	}
	"get change file: " + $_    
    $item = $_.Split([char]0x0009);
	$item[0] = $item[0].substring(0,1);
	#Write-Verbose "Current change is: $_";
    if($changeType.Contains($item[0])){
		if($item[0].Contains("R")){
			$changes += ,$item[2];
		} else {
			$changes += ,$item[1];
		}
     }
	}
	
#	Write-VerWrite-VerWrite-Verbose "Changed files are:"
#	$changes | foreach { Write-Verbose $_ }
    "var changes value is:" + $changes
	IF($shouldFlatten)
	{
		$changes | foreach {
			Copy-Item $_ -Destination "$destination"
			}
	}
	else
	{
		$changes | foreach {
	    "ready copy change file: " + $_ 
		$destinationPath = join-path $destination $_;
		"destinationPath is:" + $destinationPath
		New-Item -ItemType File -Path "$destinationPath" -Force | out-null
		Copy-Item $_ -Destination "$destinationPath" -recurse -container;
		}
	}
	
} finally {
   # Trace-VstsLeavingInvocation $MyInvocation
	if ($LastExitCode -ne 0) { 
		Write-Error "Something went wrong. Please check the logs."
    }
}

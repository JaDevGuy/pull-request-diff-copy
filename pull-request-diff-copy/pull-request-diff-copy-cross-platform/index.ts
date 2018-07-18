import tl = require('vsts-task-lib/task');

async function run() {
    try {

        tl._writeLine("starting...");

        tl._writeLine(tl.getVariable("system.defaultworkingdirectory"));
        var defaultworkingdirectory = tl.getVariable("system.defaultworkingdirectory");
        var destination = tl.getInput("destination");
        var shouldFlattenInput = tl.getBoolInput("flatten");
        var shouldContentGenerationInput = tl.getBoolInput("contentGeneration");
        var utf8withBOM = tl.getBoolInput("utf8withBOM");

        var changeType = "A,C,M,R,T";
        var buildReason = tl.getVariable("build.reason");

        if (buildReason != "PullRequest") {
            tl.error("Pull Request Diff Copy will only process when triggered by Pull Request Build.");
            return;
        }
        
        let expressCmd: string = "";
        // SYSTEM_PULLREQUEST_SOURCEBRANCH
        var branchName = tl.getVariable("system.pullRequest.sourceBranch").replace("refs/heads/", "");
        // SYSTEM_PULLREQUEST_TARGETBRANCH
        var targetBranch = tl.getVariable("system.pullRequest.targetBranch").replace("refs/heads/", "");

        var isFork = branchName.indexOf("source") > 0;

        if (isFork) {
            branchName = branchName.replace("source", "merge").replace("refs", "refs/remotes");
            expressCmd = `git merge-base 'refs/remotes/origin/${targetBranch}' '${branchName}'`;
        } else {
            expressCmd = `git merge-base 'refs/remotes/origin/${targetBranch}' 'refs/remotes/origin/${branchName}'`;
        }

        tl._writeLine(`Get ${branchName} merge-base to ${targetBranch}`);
        tl._writeLine(`SYSTEM_PULLREQUEST_ISFORK: ${isFork}`);
        tl._writeLine(`SYSTEM_PULLREQUEST_SOURCEBRANCH: ${tl.getVariable("system.pullRequest.sourceBranch")}`);
        tl._writeLine(`SYSTEM_PULLREQUEST_TARGETBRANCH：${tl.getVariable("system.pullRequest.targetBranch")}`);
        tl._writeLine(`destination is ${destination}`);
        tl._writeLine(`buildReason is ${buildReason}`);
        tl._writeLine(`branchName is ${branchName}`);
        tl._writeLine(`targetBranch is ${targetBranch}`);
        tl._writeLine(`UTF-8 with BOM is ${utf8withBOM}`);


        tl._writeLine(`Invoke-Expression  ${expressCmd}`);
        let gitCmd: string="git config core.quotepath off";
        let git
        if (process.platform === 'win32') {
            git = tl.execSync('powershell', `"${gitCmd}"`).stdout.trim();

        }
        else {
            git = tl.execSync("bash", `--norc --noprofile -c "${gitCmd}"`).stdout.trim();
        }

        tl._writeLine(`sha is ${git}`);


        let stdout
        if (process.platform === 'win32') {
            stdout = tl.execSync('powershell', `"${expressCmd}"`).stdout.trim();

        }
        else {
            stdout = tl.execSync("bash", `--norc --noprofile -c "${expressCmd}"`).stdout.trim();
        }

        tl._writeLine(`sha is ${stdout}`);

        let diffCmd;

        if (isFork) {
            diffCmd = `git diff '${stdout}' '${branchName}' --name-status`;
        } else {
            diffCmd = `git diff '${stdout}' 'refs/remotes/origin/${branchName}' --name-status`;
        }

        tl._writeLine(`Invoke-Expression ${diffCmd}`);

        let diffContents: string = "";
        if (process.platform === 'win32') {
            diffContents = tl.execSync('powershell', `"${diffCmd}"`).stdout.trim();

        }
        else {
            diffContents = tl.execSync("bash", `--norc --noprofile -c "${diffCmd}"`).stdout.trim();
        }

        // tl.mkdirP()
        let changes: string[] = [];
        let lines = diffContents.split('\n');
        if (lines.length > 0) {
            lines.forEach(line => {

                tl._writeLine(`line is ${line}`);
                // 按  \t分割
                let lineItem = line.split('\t');
                let diffStatus = lineItem[0].substr(0, 1);

                tl._writeLine(`File Status is ${diffStatus}`);

                if (changeType.includes(diffStatus)) {

                    diffStatus === "R" ? changes.push(`${lineItem[2]}`) : changes.push(`${lineItem[1]}`);
                }
            })

        }


        // rm -rf
        if (tl.exist(destination)) {

            tl._writeLine("Clean up the diff folder first ... ");

            tl.rmRF(destination);
        }

        // creat folder
        tl._writeLine("WriteFile Starting ... ");

        // 列出文件列表
        if (shouldContentGenerationInput) {

            let contentDir = `${destination}/Content`
            if (tl.exist(contentDir)) {
                tl._writeLine(`rm -rf ${contentDir}`)
                tl.rmRF(`${contentDir}`);
            }

            tl._writeLine(`mkdir ${contentDir}`)
            tl.mkdirP(`${contentDir}`);

            // 保留目录结构
            if (!shouldFlattenInput) {

                changes.forEach(item => {
                    //mkdir

                    let diffFileFolderPath = item.substr(0, item.lastIndexOf('/'));

                    if (diffFileFolderPath) {

                        tl._writeLine(`mkdir ${contentDir}/${diffFileFolderPath}`);

                        tl.mkdirP(`${contentDir}/${diffFileFolderPath}`);

                        tl._writeLine(`cp -rf ${item} , ${contentDir}/${diffFileFolderPath}`);

                        //cp folder
                        tl.cp(item, `${contentDir}/${diffFileFolderPath}`);
                    } else {

                        // cp root files
                        tl.cp(item, contentDir);
                    }



                });

            }
            else {

                changes.forEach(x => {

                    tl._writeLine(`cp ${x} , ${contentDir}`);
                    tl.cp(x, contentDir);
                })



            }
        }

        tl.mkdirP(destination);


        diffContents = process.platform === "win32" ? diffContents.replace(/'\n'/g, '\r\n') : diffContents;

        // tl.

        tl._writeLine(`${typeof (utf8withBOM)},${true === utf8withBOM}`);


        utf8withBOM ? tl.writeFile(`${destination}/diff.txt`, `\ufeff${diffContents}`, "utf-8")
            : tl.writeFile(`${destination}/diff.txt`, diffContents);

        tl._writeLine('Task done ...');


    }
    catch (err) {
        tl.error(err.message);
    }
}

run();
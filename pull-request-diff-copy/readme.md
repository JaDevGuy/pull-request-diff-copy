# Copy the changed files for Pull Reqeust to a folder

When you create a Pull Request, you are actually doing a diff between two branches. It makes sense to get a copy of the diff result for other usage. 

For example, many teams are trying to do incremental deployment based on the changes in a merge. This extension will help you generate such incremental deployment packages.

[![Version Badge][marketplace-version-badge]][extension-marketplace-url]
[![Installs Badge][marketplace-installs-badge]][extension-marketplace-url]
[![Rating Badge][marketplace-rating-badge]][extension-marketplace-url]

## Sponsorship

This extension is sponsored and developed with Bank of Beijing. Thanks for the great contribution from Bank of Beijing Software DevCenter engineering team.

![Logo of Bank of Beijing](https://raw.githubusercontent.com/lean-soft/pull-request-diff-copy/master/pull-request-diff-copy/images/BOB-logo.gif)

## Tasks included

This extension includes the following tasks

* **Pull Request Diff Copy** - you can specify a target folder to contain your diff files and there will be diff.txt created inside the folder which includes a list of file full paths for later usage, e.g. as a filter for [File Copy] tasks.

### Prerequisites

* Repository must be Git.
* This task must be trigged by pull request, [setup branch policy to trigger a build during Pull Request](https://docs.microsoft.com/zh-cn/vsts/git/branch-policies?view=vsts#require-the-pull-request-to-build). If the build is not triggered by a Pull Request, the task will just skip and do nothing.

### Feature

* TFS and VSTS with Windows Build Agents & Linux Build Agents (You need to use task with 'Cross Platform’, the original task is left in the list for backward compatibility) 
* Branch and Fork
* Diffed file list and generate diff.txt for later usage

## Quick Start

It's very easy to use this extension, you just need to add it right after the 'get source' step in your build definition

![Task](https://raw.githubusercontent.com/lean-soft/pull-request-diff-copy/master/pull-request-diff-copy/images/prdc-screenshot-01.png)

Then trigger the build from a Pull Request, check out this link to [setup branch policy to trigger a build during Pull Request](https://docs.microsoft.com/zh-cn/vsts/git/branch-policies?view=vsts#require-the-pull-request-to-build). 

![Task](https://raw.githubusercontent.com/lean-soft/pull-request-diff-copy/master/pull-request-diff-copy/images/prdc-screenshot-02.png)

Finally, if you use publish your artifact, you will be able to grab the diffed files and diff.txt from your bulid summary.

![Task](https://raw.githubusercontent.com/lean-soft/pull-request-diff-copy/master/pull-request-diff-copy/images/prdc-screenshot-03.png)

## Contribute

You can create issues on our [GitHub repo](https://github.com/lean-soft/pull-request-diff-copy) or send a Pull Request. Our Developer will keep watching the events on the repo and get back to your as soon as possible.
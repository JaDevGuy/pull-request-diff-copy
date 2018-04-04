# Copy the changed files for Pull Reqeust to a folder

When you create a Pull Request, you are actually doing a diff between two branches. It makes sense to get a copy of the diff result for other usage. For example, many teams are trying to do incremental deployment based on the changes in a merge. This extension will help you generate such incremental deployment packages.

## Tasks included

This extension includes the following tasks

* Pull Request Diff Copy - you can specify a target folder to contain your diff files and there will be diff.txt created inside the folder which includes a list of file full paths for later usage, e.g. as a filter for [File Copy] tasks.

### Prerequisites

* Repository must be Git.
* Allow scripts to access Oauth must be **Enabled**
* This task must be trigged by pull request,[setup branch policy to trigger a build during Pull Request](https://docs.microsoft.com/zh-cn/vsts/git/branch-policies?
view=vsts#require-the-pull-request-to-build). If the build is not triggered by a Pull Request, the task will just skip and do nothing.

## Contribute

You can create issues on our [GitHub repo](https://github.com/lean-soft/pull-request-diff-copy) or send a Pull Request. Our Developer will keep watching the events on the repo and get back to your as soon as possible.

## Special Thanks

This extension is created by Li Xiaoming based on [Git Copy Diff](https://marketplace.visualstudio.com/items?itemName=visualbean.VisualBean-GitCopyDiff). Thanks for the Author Alexander Carlsen.
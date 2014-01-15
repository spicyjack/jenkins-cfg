# jenkins-cfg #

Configuration files and "library scripts" for building different projects under Jenkins

## Directory Layout ##
- /jobs - Jenkins jobs; use `uname -s` to determine platform directory to use:
  - Linux - Linux jobs
  - Darwin - OS X jobs
- /scripts - Scripts used by jobs in the /jobs directory
  - download.sh - Downloads files using wget; creates destination directory if
    it doesn't exist, and optionally logs wget output so it's available, but
    not logged as part of the Jenkins logs
  - `deps_check.sh` - Determines if package dependencies required for building
    have been installed on the system
- /enviro - Environment setup for the Jenkins user, if you decide to use one

## Restoring config.xml Files ##
Restoring jobs by hand:

1. Create Job in Jenkins
1. Copy `config.xml` file from the appropriate platform directory to the
  Jenkins job directory
  - `cp ~/src/jenkins-cfg.git/jobs/$(uname -s)/JobName/config.xml \
    ~jenkins/.jenkins/jobs/JobName`

Restoring jobs via script:
1. Create the jobs in Jenkins
  1. The jobs need to have the same names as the saved config files, including
  correct case
1. Run the `restore_jenkins_cfgs.sh` script in the `scripts` directory

    /bin/bash scripts/restore_jenkins_cfgs.sh --jobs ~/jobs \
      --source /path/to/configs/dir


vim: filetype=markdown shiftwidth=2 tabstop=2

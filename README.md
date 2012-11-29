## jenkins-cfg ##

Configuration files and "library scripts" for building different projects under Jenkins

Directory layout:
- jobs - Jenkins jobs
- scripts - Scripts used by jobs in the /jobs directory
  - download.sh - Downloads files using wget; creates destination directory if
    it doesn't exist, and optionally logs wget output so it's available, but
    not logged as part of the Jenkins logs

### Todo ###
- Document how to restore the config.xml file on top of a fresh Jenkins
  install

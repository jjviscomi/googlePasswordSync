**INTRODUCTION**

GooglePasswordSync is a tool designed specifically to provide an easy method of integrating Open Directory and Google Apps. It offers an easy and straight forward install mechanism and a simple and secure implimentation approach that requires no third party services to run.

**INSTALL INSTRUCTIONS**

1. Prepare Open Directory, In WGM make sure every user has the full Google Apps e-mail address entered under the info tab, it should be the first and only one listed.

2. Make sure API access in enabled on your Googel Apps Domain.

3. For every Domain / Organization you wish to sync create admin account that have the same username in Google Apps. For an example, if I have two different domains of @myfirstdomain.org and @myseconddomain.org Then I will create two admin accounts say authUpdater@myfirstdomain.org and authUpdater@myseconddomain.org. They must both have the same password, following this convention keeps everything simple.

4. Make sure you can logon to those domain with the newly created admin accounts, accept the agreements, etc ...

5. Download the latest zip file of the master brach git repo (this is the most current and stable version) to your Open Directory Master (ODM), it must be installed on your ODM.

6. Unzip the new version, then open Terminal and cd into the setup folder inside the main package folder, you MUST run the install from that directory currently.

7. The install script needs to be run by root so once inside the setup folder run: sudo ./install.sh

8. Watch the output for any errors, assuming there are no errors you should have s successful install, you might need to restart your passwordService or your ODM for the changes to take effect.


**UNINSTALL INSTRUCTIONS**
1. Inside the stup folder is the uninstall.sh script, this does all the cleanup of files and services that were installed for googlePasswordSync, it is imperative you run this when uninstalling the program.


**OPERATIONS**

When a password change event occures password_update.sh script is executed automatically, this script does the following jobs:
1. Creates an RSA public/private key pair for each user if one does not exist.

2. Creates a user.info file that contains thier e-mail, username, password hash, and checksum.

3. Creates a user.password file which contains the users encrypted password with the users public key

4. Archives users old files, if they exists and a change has occured.

5. Adds the user to the gps.sh sync queues (there are two different ones, one for pushing the changes only and the other pushes all users the system knows about)

6. (If enabled) It will modify the users LDAP record to contain a SHA1 hash of the users password so it can be synced using Google Apps Directory Sync (GADS), this is strictly for GADS compatibility and should NOT be enabled unless you require this functionality.

Then every so often (default is 90 seconds, but this is configured during the install) gps.sh runs to see if there are any NEW changes to tell Google Apps about. It is responsible for the following jobs:
1. Checks Google Apps if the specified mail account exists.

2. Creates new google Apps account (if enabled) if it does not already exist.

3. If the account exists it updates the password to the password it has captured from Open Directory.



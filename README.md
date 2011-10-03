**INTRODUCTION**

GooglePasswordSync is a tool designed specifically to provide an easy method of integrating Open Directory and Google Apps. It offers an easy and straight forward install mechanism and a simple and secure implimentation approach that requires no third party services to run.

**REQUIREMENTS**

1. OS X Server 10.5+

2. User password type must be Open Directory.

**INSTALL INSTRUCTIONS**

1. Prepare Open Directory, In WGM make sure every user has the full Google Apps e-mail address entered under the info tab, it should be the first and only one listed.

2. Make sure API access in enabled on your Google Apps Domain.

3. For every Domain / Organization you wish to sync create admin account that have the same username in Google Apps. For an example, if I have two different domains of @myfirstdomain.org and @myseconddomain.org Then I will create two admin accounts say authUpdater @ myfirstdomain.org and authUpdater @ myseconddomain.org. They must both have the same password, following this convention keeps everything simple.

4. Make sure you can logon to those domain with the newly created admin accounts, accept the agreements, etc ...

5. Download the latest zip file of the master brach git repo (this is the most current and stable version) to your Open Directory Master (ODM), it must be installed on your ODM.

6. Unzip the new version, cd into the newly unzipped folder.

7. The install script needs to be run by root: sudo ./install.sh

8. Watch the output for any errors, assuming there are no errors you should have s successful install, you might need to restart your passwordService or your ODM for the changes to take effect. 

* Special Note: After you create an account you must change the password for this tool to capture the account info, this ONLY happens when a password change occurs NOT on account creation.


**UNINSTALL INSTRUCTIONS**

1. Inside the setup folder is the uninstall.sh script, this does all the cleanup of files and services that were installed for googlePasswordSync, it is imperative you run this when uninstalling the program.

2. You should be in the setup directory when running the uninstall.sh script to avoid any problems.


**OPERATIONS**

When a password change event occurs password_update.sh script is executed automatically, this script does the following jobs:

1. Creates an RSA public/private key pair for each user if one does not exist.

2. Creates a user.info file that contains their e-mail, username, password hash, and checksum.

3. Creates a user.password file which contains the users encrypted password with the users public key

4. Archives users old files, if they exists and a change has occurred.

5. Adds the user to the gps.sh sync queues (there are two different ones, one for pushing the changes only and the other pushes all users the system knows about)

6. (If enabled) It will modify the users LDAP record to contain a SHA1 hash of the users password so it can be synced using Google Apps Directory Sync (GADS), this is strictly for GADS compatibility and should NOT be enabled unless you require this functionality.

Then every so often (default is 90 seconds, but this is configured during the install) gps.sh runs to see if there are any NEW changes to tell Google Apps about. It is responsible for the following jobs:

1. Checks Google Apps if the specified mail account exists.

2. Creates new google Apps account (if enabled) if it does not already exist.

3. If the account exists it updates the password to the password it has captured from Open Directory.

**LOG VIEWS**

*Below is an example of a successful password_capture.sh process as viewd in the /var/log/system.log file:*

Aug 15 13:10:28 brehmodm (/usr/sbin/authserver/tools/password_update.sh) preparing password capture.

Aug 15 13:10:28 brehmodm (/usr/sbin/authserver/tools/password_update.sh) password update detected for LDAP user [a.user].

Aug 15 13:10:28 brehmodm (/usr/sbin/authserver/tools/password_update.sh) database location at [/.secret].

Aug 15 13:10:28 brehmodm (/usr/sbin/authserver/tools/password_update.sh) created database password file [/.secret/vault/a.user.passwd].

Aug 15 13:10:28 brehmodm (/usr/sbin/authserver/tools/password_update.sh) created database info file [/.secret/info/a.user.info].

Aug 15 13:10:28 brehmodm (/usr/sbin/authserver/tools/password_update.sh) missing users public key [/.secret/keys/public/b26812ed4c4ab9f266dba598b80ae4051f32a776.pem].

Aug 15 13:10:28 brehmodm (/usr/sbin/authserver/tools/password_update.sh) missing users private key [/.secret/keys/pprivate/b26812ed4c4ab9f266dba598b80ae4051f32a776.pem].

Aug 15 13:10:28 brehmodm (/usr/sbin/authserver/tools/password_update.sh) encrypted users password.

Aug 15 13:10:37 brehmodm (/usr/sbin/authserver/tools/password_update.sh) finished writing capture files [a.user]

Aug 15 13:10:37 brehmodm (/usr/sbin/authserver/tools/password_update.sh) Queuing password sync process for user: [a.user]

Aug 15 13:10:37 brehmodm (/usr/sbin/authserver/tools/password_update.sh) adding user to routine push: [a.user]

Aug 15 13:10:37 brehmodm (/usr/sbin/authserver/tools/password_update.sh) finished password cap*ure process [a.user]



*Below is an example of a successful gps.sh sync process as viewed in the /var/log/system.log file:*

Aug 15 13:10:37 brehmodm (/private/etc/org.theObfuscated/googlePasswordSync/gps.sh) sync --update process started.

Aug 15 13:11:00 brehmodm (/private/etc/org.theObfuscated/googlePasswordSync/gps.sh) syncing a.user password.

Aug 15 13:11:15 brehmodm (/private/etc/org.theObfuscated/googlePasswordSync/gps.sh) syncing data for Google Apps Account: a.user@theObfuscated.org

Aug 15 13:11:16 brehmodm (/private/etc/org.theObfuscated/googlePasswordSync/gps.sh)  Google Apps account not found for a.user, attempting to create it now.

Aug 15 13:11:22 brehmodm (/private/etc/org.theObfuscated/googlePasswordSync/gps.sh)  successfully Created Google Apps Account [a.user]

Aug 15 13:11:22 brehmodm (/private/etc/org.theObfuscated/googlePasswordSync/gps.sh) Sync --update process finished.


**TROUBLES SHOOTING**

Because we still are not at version 1, the logging is verbose by default. You can find a lof of information by watching the /var/log/system.log that should clue you into any problems. Also in the /var/log/ there exists application specific log files you can browse.

All running configuration settings are kept in /Library/Preferences/org.theObfuscated.googlePasswordSync.plist
(BACKUP THIS FILE BEFORE YOU MAKE ANY CHANGES, THE UNINSTALLER NEEDS IT TO DO A PROPER UNINSTALL)


**ADDITIONAL TOOLS**

Three additional tools are installed to offer additional functionality, they work completely independent of googlePasswordSync:

- /usr/sbin/admin/tools/googlePasswordSync/crypto.sh: Handels key pair generation, encryption/decryption, hashing

- /usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh: Handels ldap information lookup as well as account status

- /usr/sbin/admin/tools/googlePasswordSync/Gapps.php: Command line interface to Google Apps


**ROAD MAP**

Below is a list of things that still need to be completed for what I would consider the Version 1 Release:

- LDAP user groups to be mirrored to Google Apps as groups (distribution lists), keep group members in sync on Google Apps and LDAP.

- Disable an account in Google Apps if it is disabled in LDAP, and Enable a disabled Google Apps Account if its LDAP status is changed to Enabled.

- Seamless upgrade process from version to version

- Preferences / Property editor

- Archive db and restore db
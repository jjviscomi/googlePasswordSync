#!/bin/sh

####################################################################################################
# File Name: password_update.sh                                                                    #
#                                                                                                  #
# Created by Joseph J Viscomi on 7/8/11.                                                           #
# E-Mail: jjviscomi@gmail.com Facebook: (http://www.facebook.com/joe.viscomi)                      #
# Website: http://www.theObfuscated.org                                                            #
# Date Last Modified: 7/27/2011.                                                                   #
# Version 0.7b                                                                                     #
#                                                                                                  #
# Description: This is script that is run on every password change in LDAP.                        #
#                                                                                                  #
# Instructions: It assumes that the password is passed to it from stdin. You should not be running #
#               this file directly, it will also have the SUID bit set from root.                  #
#                                                                                                  #
# Arguments: NONE                                                                                  #
#                                                                                                  #
# This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. #
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send a   #
# letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA. #
####################################################################################################


read password

printf "%s %s (%s) preparing password capture.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" >> /var/log/system.log


#HANDEL THE APPLICATION LOG FILE - CREATE IT AND SET PERMISSION
if [ ! -f /var/log/googlePasswordSync/logs/passwordChange.log ]
then
    touch /var/log/googlePasswordSync/logs/passwordChange.log
    chown root:wheel /var/log/googlePasswordSync/logs/passwordChange.log
    chmod 744 /var/log/googlePasswordSync/logs/passwordChange.log

    if [ ! -f /var/log/googlePasswordSync/logs/passwordChange.log ]
    then
        printf "%s %s (%s) could not create flat file [/var/log/googlePasswordSync/logs/passwordChange.log], Exiting\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" >> /var/log/system.log
        exit 1
    fi

    printf "%s %s (%s) created new info file [/var/log/googlePasswordSync/logs/passwordChange.log]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" >> /var/log/system.log
fi

#HANDEL THE APLICATION LOG FILE - CREATE IT AND SET PERMISSION
if [ ! -f /var/log/googlePasswordSync/logs/passwordSync.log ]
then
    touch /var/log/googlePasswordSync/logs/passwordSync.log
    chown root:wheel /var/log/googlePasswordSync/logs/passwordSync.log
    chmod 744 /var/log/googlePasswordSync/logs/passwordSync.log

    if [ ! -f /var/log/googlePasswordSync/logs/passwordSync.log ]
    then
        printf "%s %s (%s) could not create flat file [/var/log/googlePasswordSync/logs/passwordSync.log], Exiting\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" >> /var/log/system.log
        exit 1
    fi

    printf "%s %s (%s) Created new info file [/var/log/googlePasswordSync/logs/passwordSync.log]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" >> /var/log/system.log
fi


printf "%s %s (%s) password update detected for LDAP user [%s].\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$1" >> /var/log/system.log

dbDirectory=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync DB_DIRECTORY`

printf "%s %s (%s) database location at [%s].\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$dbDirectory" >> /var/log/system.log


if [ ! -d $dbDirectory ]
then
	printf "%s %s (%s) database location folder [%s] not found or accessable, exiting.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$dbDirectory" >> /var/log/system.log
	exit 1
fi

# HANDEL THE ARCHINGING OF OLD PASSWORDS
if [ -f $dbDirectory/vault/$1.passwd ]
then
	if [ ! -d $dbDirectory/old/$1 ]
	then
        
		mkdir -p $dbDirectory/old/$1
		chown root:wheel $dbDirectory/old/$1
		chmod 700 $dbDirectory/old/$1
        printf "%s %s (%s) created database user backup folder [%s/old/%s].\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$dbDirectory" "$1" >> /var/log/system.log
	fi
	
	if [ -d $dbDirectory/old ]
	then
		#ARCHIVE THE OLD FLAT FILES IN AN ORGANIZED MANOR
		mv $dbDirectory/vault/$1.passwd $dbDirectory/old/$1/$1.passwd.$(date "+%s").old
		printf "%s %s (%s) archived old password [%s/vault/%s.passwd -> %s/old/%s/%s.passwd.%s.old]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$dbDirectory" "$1" "$dbDirectory" "$1" "$1" "`date \"+%s\"`" >> /var/log/system.log
	else
		printf "%s %s (%s) archive directory missing [%s/old], exiting.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$dbDirectory" >> /var/log/system.log
		exit 1
	fi
fi

#CREATE THE NEW PASSWORD CAPTURE FILE
touch $dbDirectory/vault/$1.passwd
chown root:wheel $dbDirectory/vault/$1.passwd
chmod 700 $dbDirectory/vault/$1.passwd

if [ ! -f $dbDirectory/vault/$1.passwd ]
then
	printf "%s %s (%s) could not create database password file [%s/vault/%s.passwd].\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$dbDirectory" "$1" >> /var/log/system.log
	exit 1
fi

printf "%s %s (%s) created database password file [%s/vault/%s.passwd].\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$dbDirectory" "$1" >> /var/log/system.log

#CREATE THE NEW INFO FILE
if [ ! -f $dbDirectory/info/$1.info ]
then
	touch $dbDirectory/info/$1.info
	chown root:wheel $dbDirectory/info/$1.info
	chmod 700 $dbDirectory/info/$1.info

	if [ ! -f $dbDirectory/info/$1.info ]
	then
		printf "%s %s (%s) could not create database info file [%s/info/%s.info].\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$dbDirectory" "$1" >> /var/log/system.log
		exit 1
	fi
	
	printf "%s %s (%s) created database info file [%s/info/%s.info].\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$dbDirectory" "$1" >> /var/log/system.log
fi




#WRITE THE TIMESTAMP HEADER
printf "[AUTO GENERATED FLAT FILE - DO NOT EDIT -]\n" > $dbDirectory/info/$1.info
printf "#WRITEDATE: %s\n" "`date`" >> $dbDirectory/info/$1.info

#CAPTURE THE USER INFORMATION
printf "#USERNAME:   %s\n" "$1" >> $dbDirectory/info/$1.info
printf "#USERROLE:   %s\n" "$2" >> $dbDirectory/info/$1.info

#HASHES THE USERNAME FOR THER PUBLIC/PRIVATE KEY FILE NAMES
keyFileName="`echo $1 | openssl dgst -sha1 -hex`"
keyFileSize=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync USER_KEYSIZE`

#CREATE NEW USER KEY PAIR IF NEEDED
if [ ! -f $dbDirectory/keys/public/$keyFileName.pem ]
then
    printf "%s %s (%s) missing users public key [%s/keys/public/%s.pem].\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$dbDirectory" "$keyFileName" >> /var/log/system.log
    if [ ! -f $dbDirectory/keys/private/$keyFileName.pem ]
    then
        printf "%s %s (%s) missing users private key [%s/keys/pprivate/%s.pem].\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$dbDirectory" "$keyFileName" >> /var/log/system.log
        #GENERATE A NEW PUBLIC/PRIVATE KEY PAIR FOR A SPECIFC USER
        /usr/sbin/admin/tools/googlePasswordSync/crypto.sh --gen $keyFileSize $dbDirectory/keys/private/$keyFileName.pem $dbDirectory/keys/public/$keyFileName.pem
    else
        printf "%s %s (%s) missing public/private key pair.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$dbDirectory" >> /var/log/system.log
        rm -rf $dbDirectory/keys/private/$keyFileName.pem
        
        #GENERATE A NEW PUBLIC/PRIVATE KEY PAIR FOR A SPECIFC USER
        /usr/sbin/admin/tools/googlePasswordSync/crypto.sh --gen $keyFileSize $dbDirectory/keys/private/$keyFileName.pem $dbDirectory/keys/public/$keyFileName.pem
    fi
else
    if [ ! -f $dbDirectory/keys/private/$keyFileName.pem ]
    then
        printf "%s %s (%s) missing users private key [%s/keys/pprivate/%s.pem].\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$dbDirectory" "$keyFileName" >> /var/log/system.log
        rm -rf $dbDirectory/keys/public/$keyFileName.pem
        
        #GENERATE A NEW PUBLIC/PRIVATE KEY PAIR FOR A SPECIFC USER
        /usr/sbin/admin/tools/googlePasswordSync/crypto.sh --gen $keyFileSize $dbDirectory/keys/private/$keyFileName.pem $dbDirectory/keys/public/$keyFileName.pem
    else
        printf "%s %s (%s) found users private/public key pair.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" >> /var/log/system.log
    fi
fi


#ENCRYPT THE PASSWORD
encPassword=`/usr/sbin/admin/tools/googlePasswordSync/crypto.sh --encode $dbDirectory/keys/public/$keyFileName.pem $password`
printf "%s %s (%s) encrypted users password.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" >> /var/log/system.log

odmAddress=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync ODM`
ldapBase=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync LDAP`


#GET THE LDAP REGISTERED E-MAIL ADDRESS
userEmail=`/usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh $odmAddress $ldapBase --uid $1 email`

#WRITE THE ENCRYPTED PASSWORD TO DISK
printf "%s" "$encPassword" > $dbDirectory/vault/$1.passwd

#WRITE THE USER INFO FILE TO DISK
printf "#USERMAIL:   %s\n" "$userEmail"                                          >> $dbDirectory/info/$1.info
printf "#EMAILNAME:  %s\n" "`echo $userEmail | awk -F@ '{print $1}'`"            >> $dbDirectory/info/$1.info
printf "#USERDOMAIN: %s\n" "`echo $userEmail | awk -F@ '{print $2}'`"            >> $dbDirectory/info/$1.info

printf "#FIRSTNAME:  %s\n" "`/usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh $odmAddress $ldapBase --uid $1 firstname`" >> $dbDirectory/info/$1.info
printf "#LASTNAME:   %s\n" "`/usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh $odmAddress $ldapBase --uid $1 lastname`"  >> $dbDirectory/info/$1.info

#FOR FUTURE USE
printf "#PASSWDSHA1: %s\n" "`echo -n $password | openssl dgst -sha1 -hex`"          >> $dbDirectory/info/$1.info
printf "#CHECKSUM:   %s\n" "`echo $1$2$encPassword$userEmail | openssl md5`"     >> $dbDirectory/info/$1.info

printf "%s %s (%s) finished writing capture files [%s]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$1" >> /var/log/system.log
printf "%s %s (%s) password change for user: %s.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$1" >> /var/log/googlePasswordSync/logs/passwordChange.log


#GADS INTEGRATION
GADS_ENABLED=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GADS_ENABLED`
if [ $GADS_ENABLED == 1 ]
then
    printf "%s %s (%s) Updating GADS LDAP record for: [%s]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$1" >> /var/log/system.log

    GADS_PASSWORD=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GADS_PASSWORD`
    GADS_USER=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GADS_USER`
    GADS_RECORD_NAME=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GADS_RECORD_NAME`
    adminPrivateKeyFileName=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PRIVATE_KEY`
    odmAddress=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync ODM`
    ldapBase=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync LDAP`
    
    #dn: uid=joseph.viscomi,cn=users,dc=myserver,dc=viscomi,dc=cdl
    gadsDn="cn=users,"
    gadsSkip="NO"
    IFS=',' read -ra LDAP_PARTS <<< "$ldapBase"
    for i in "${LDAP_PARTS[@]}"; do
        if [ "$gadsSkip" == "YES" ]
        then
            gadsSkip="NO"
        else
            gadsDn=$gadsDn"${i},"
        fi
    done

    gadsDn="${gadsDn%?}"

    printf "%s %s (%s) Adding / modifying the %s LDAP attribute\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$GADS_RECORD_NAME" >> /var/log/system.log

    OD_PASSWORD=`/usr/sbin/admin/tools/googlePasswordSync/crypto.sh --decode $dbDirectory/keys/private/$adminPrivateKeyFileName.pem "$GADS_PASSWORD"`
    
    shaUserPasswordHash=`echo -n $password | openssl dgst -sha1 -hex`
    #ldapModifyResults=`echo "dn: uid=$1,cn=users,$gadsDn\nchangetype: modify\nreplace: $GADS_RECORD_NAME\n$GADS_RECORD_NAME: $shaUserPasswordHash" | ldapmodify -xD uid=$GADS_USER,$gadsDn -w $OD_PASSWORD -v`
    tmpFileName=`date \"+%b %d %k:%M:%S\"$1 | /usr/bin/openssl dgst -sha1 -hex`

    printf "dn: uid=%s,%s\nchangetype: modify\nreplace: %s\n%s: %s" "$1" "$gadsDn" "$GADS_RECORD_NAME" "$GADS_RECORD_NAME" "$shaUserPasswordHash" > /tmp/$tmpFileName.ldif
    ldapModifyResults=`ldapmodify -xD uid=$GADS_USER,$gadsDn -w $OD_PASSWORD -v -f /tmp/$tmpFileName.ldif`
    srm /tmp/$tmpFileName.ldif

    printf "%s %s (%s) LDAP MODIFY RESULTS: \n[%s]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$ldapModifyResults" >> /var/log/system.log

fi
    
    
    


#HANDELING THE SYNC QUEUE [NEW PASSWORD CHANGE]
inqueue=`cat "$dbDirectory/.queue/push.queue" | grep $1`
inwait=`cat "$dbDirectory/.queue/.push.wait.queue" | grep $1`

if [ -z "$inqueue" ]
then
	printf "%s %s (%s) Queuing password sync process for user: [%s]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$1" >> /var/log/system.log
	
	if [ -z "$inwait" ]
	then
		if [ ! -f /tmp/push.queue.lock ]
		then
			printf "%s\n" "$1" >> $dbDirectory/.queue/push.queue
			printf "%s %s (%s) password sync scheduled in push.queue for user: %s.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$1" >> /var/log/googlePasswordSync/logs/passwordSync.log
		else
			printf "%s %s (%s) queue is locked by googlePasswordSync.sh placing in alternate queue: [%s]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$1" >> /var/log/system.log
			printf "%s\n" "$1" >> $dbDirectory/.queue/.push.wait.queue
			printf "%s %s (%s) password sync scheduled in .push.wait.queue for user: %s.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$1" >> /var/log/googlePasswordSync/logs/passwordSync.log
		fi
	fi
fi

#ADD COMPLETE SYNC QUEUE [ROUTINE SYNCING TO KEEPS THINGS CONSISTENT INCASE OF A USER CHANGES THEIR PASSWORD IN GOOGLE APPS]
inqueue=`cat "$dbDirectory/.queue/gps.queue" | grep $1`

if [ -z "$inqueue" ]
then
    printf "%s %s (%s) adding user to routine push: [%s]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$1" >> /var/log/system.log
    printf "%s\n" "$1" >> $dbDirectory/.queue/gps.queue
fi

#FINISHED
printf "%s %s (%s) finished password capture process [%s]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$1" >> /var/log/system.log

exit 0
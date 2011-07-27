#!/bin/sh

####################################################################################################
# File Name: gps.sh                                                                                #
#                                                                                                  #
# Created by Joseph J Viscomi on 7/8/11.                                                           #
# E-Mail: jjviscomi@gmail.com Facebook: (http://www.facebook.com/joe.viscomi)                      #
# Website: http://www.theObfuscated.org                                                            #
# Date Last Modified: 7/27/2011.                                                                   #
# Version: 0.7b                                                                                    #
#                                                                                                  #
# Description: This is the Launch Daemon that actual gets register to run to sync account info     #
#              that is distributed with org.theObfuscated.googlePasswordSync package.              #
#                                                                                                  #
# Instructions: This file is invoked by launchd to sync LDAP password changes to Google Apps.      #
#                                                                                                  #
# Arguments: [ --update | --sync ]                                                                 #
#            --update pushed the password change queue to Google Apps                              #
#            --sync pushes all passwords known by googlePasswordSync to Google Apps                #
#                                                                                                  #
# This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. #
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send a   #
# letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA. #
####################################################################################################

if [ "$1" == "--update" ]
then

    printf "%s %s (%s) sync --update process started.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" >> /var/log/system.log

    if [ -f /tmp/gps.lock ]
    then
        printf "%s %s (%s) sync process already started, Exiting.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" >> /var/log/system.log
        exit 1
    fi

    dbDirectory=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync DB_DIRECTORY`
    #CHECK TO SEE IF THE LOCK FILE IS PRESENT - QUIT IF IT IS
    if [ -f /tmp/push.queue.lock ]
    then
        printf "%s %s (%s) sync process already started, Exiting.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" >> /var/log/system.log
        exit 1
    fi

    #GET ALL NECESSARY DOMAIN SETTINGS
    odmAddress=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync ODM`
    ldapBase=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync LDAP`
    
    googleAppsCreateAccount=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_CREATE_ACCOUNTS`
    adminUserName=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_USER`
    adminEncryptedPasword=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PASSWORD`
    adminPrivateKeyFileName=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PRIVATE_KEY`
    adminPublicKeyFileName=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PUBLIC_KEY`

    #ESTABLISH LOCK FILE AND COMBINE QUEUES
    touch /tmp/push.queue.lock
    touch /tmp/gps.lock
    cat $dbDirectory/.queue/.push.wait.queue >> $dbDirectory/.queue/push.queue
    printf "" > $dbDirectory/.queue/.push.wait.queue
    


#BEGIN TO PROCESS THE QUEUE
    for i in $(cat $dbDirectory/.queue/push.queue) #LOOP OVER ALL USERS IN QUEUE
    do
        printf "%s %s (%s) syncing %s password.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$i" >> /var/log/system.log
	
        emailName=`/usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh $odmAddress $ldapBase --uid $i email | awk -F@ '{ print $1 }'`
        domainName=`/usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh $odmAddress $ldapBase --uid $i email | awk -F@ '{ print $2 }'`
        firstName=`/usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh $odmAddress $ldapBase --uid $i firstname`
        lastName=`/usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh $odmAddress $ldapBase --uid $i lastname`
        status=`/usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh $odmAddress $ldapBase --uid $i status`

        printf "%s %s (%s) syncing data for Google Apps Account: %s@%s\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$emailName" "$domainName" >> /var/log/system.log

        #FETCH AND DECRYPT THE USERS PASSWORD
        keyFileHash="`echo $i | openssl dgst -sha1 -hex`"
    
        printf "%s %s (%s) Fetching private key file: %s/keys/private/%s.pem\n." "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$dbDirectory" "$keyFileHash" >> /var/log/googlePasswordSync/logs/passwordSync.log
        printf "%s %s (%s) Fetching password file: %s/vault/%s.passwd\n." "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$dbDirectory" "$i" >> /var/log/googlePasswordSync/logs/passwordSync.log
        
        password=`/usr/sbin/admin/tools/googlePasswordSync/crypto.sh --decode $dbDirectory/keys/private/$keyFileHash.pem --file $dbDirectory/vault/$i.passwd`
        

        #FETCH AND DECRYPT THE ADMIN PASSWORD
        googleAdminPassword=`/usr/sbin/admin/tools/googlePasswordSync/crypto.sh --decode $dbDirectory/keys/private/$adminPrivateKeyFileName.pem "$adminEncryptedPasword"`
	
        #CONNECT TO GOOGLE APPS AND CHECK TO SEE IF THE USER ACCOUNT EXISTS
        googleAccount=`php /usr/sbin/authserver/tools/Gapps.php retrieveUser $adminUserName $domainName $googleAdminPassword $emailName`
        
        printf "%s %s (%s) Google APPS account check results: %s\n." "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$googleAccount" >> /var/log/googlePasswordSync/logs/passwordSync.log
        
        #ONLY CREATE THE ACCOUNT IF THE CONFIG SAYS TO
        if [ $googleAppsCreateAccount == 1 -a "$googleAccount" == "Error: Specified user not found." ]
        then
            printf "%s %s (%s)  Google Apps account not found for %s, attempting to create it now.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$emailName" >> /var/log/system.log
		
            #GOOGLE ACCOUNT DOES NOT EXIST, WE WILL CREATE A BASIC ACCOUNT HERE		
            googleCreateResult=`php /usr/sbin/authserver/tools/Gapps.php createUser $adminUserName $domainName $googleAdminPassword $emailName $firstName $lastName $password`
		
            if [ -z "$googleCreateResult" ]
            then
                printf "%s %s (%s)  successfully Created Google Apps Account [%s]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$emailName" >> /var/log/system.log
                printf "%s %s (%s)  successfully Created Google Apps Account [%s]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$emailName" >> /var/log/googlePasswordSync/logs/passwordSync.log
            else
                #COULD NOT CREATE ACCOUNTS
                if [ ! -f $dbDirectory/.queue/.errors.log ]
                then
                    touch $dbDirectory/.queue/.errors.log
                fi 
                printf "%s %s (%s)  ERROR [%s:%s]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$i" "$emailName" >> $dbDirectory/.queue/.errors.log
                printf "\t\tCREATE RESULT: %s\n\t\tACCOUNT CHECK: %s\n" "$googleCreateResult" "$googleAccount" >> $dbDirectory/.queue/.errors.log
            fi
		
        else
            #GOOGLE ACCONUT EXISTS, SO PUSH THE PASSWORD UPDATE
            printf "%s %s (%s)   Google Apps account found for %s, updating it now.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$emailName" >> /var/log/system.log
		
            #UPDATE THE GOOGLE APPS PASSWORD
            googleUpdateResult=`php /usr/sbin/authserver/tools/Gapps.php updateUserPassword $adminUserName $domainName $googleAdminPassword $emailName $password`
		
            if [ -z "$googleUpdateResult" ]
            then
                printf "%s %s (%s) successfully Updated GoogleApps Account [%s]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$emailName" >> /var/log/system.log
                printf "%s %s (%s) password sync sucessfull for user: %s.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$emailName" >> /var/log/googlePasswordSync/logs/passwordSync.log
            else
                #COULD NOT UPDATE ACCOUNTS
                if [ ! -f $dbDirectory/.queue/.errors.log ]
                then
                    touch $dbDirectory/.queue/.errors.log
                fi 

                printf "%s %s (%s) %s - %s\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$i" "$googleCreateResult" >> $dbDirectory/.queue/.errors.log
                printf "%s %s (%s) Password sync failure for user: %s.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$i" >> /var/log/googlePasswordSync/logs/passwordSync.log
            fi 
		
        fi
    done


    printf "" > $dbDirectory/.queue/push.queue
    rm -rf /tmp/push.queue.lock
    rm -rf /tmp/gps.lock

    printf "%s %s (%s) Sync --update process finished.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" >> /var/log/system.log

fi

if [ "$1" == "--sync" ]
then

    if [ -f /tmp/gps.lock ]
    then
        printf "%s %s (%s) sync process already started, Exiting.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" >> /var/log/system.log
        exit 1
    fi

    touch /tmp/gps.lock
    
    printf "%s %s (%s) sync --sync process started.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" >> /var/log/system.log

    
    dbDirectory=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync DB_DIRECTORY`

    #GET ALL NECESSARY DOMAIN SETTINGS
    odmAddress=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync ODM`
    ldapBase=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync LDAP`

    googleAppsCreateAccount=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_CREATE_ACCOUNTS`
    adminUserName=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_USER`
    adminEncryptedPasword=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PASSWORD`
    adminPrivateKeyFileName=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PRIVATE_KEY`
    adminPublicKeyFileName=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PUBLIC_KEY`

    for i in $(cat $dbDirectory/.queue/gps.queue) #LOOP OVER ALL USERS IN QUEUE
    do

        printf "%s %s (%s) syncing %s password.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1}'`" "$0" "$i" >> /var/log/system.log

        emailName=`/usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh $odmAddress $ldapBase --uid $i email | awk -F@ '{ print $1 }'`
        domainName=`/usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh $odmAddress $ldapBase --uid $i email | awk -F@ '{ print $2 }'`
        firstName=`/usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh $odmAddress $ldapBase --uid $i firstname`
        lastName=`/usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh $odmAddress $ldapBase --uid $i lastname`
        status=`/usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh $odmAddress $ldapBase --uid $i status`

        printf "%s %s (%s) syncing data for Google Apps Account: %s@%s\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$emailName" "$domainName" >> /var/log/system.log

        #FETCH AND DECRYPT THE USERS PASSWORD
        keyFileHash="`echo $i | openssl dgst -sha1 -hex`"

        printf "%s %s (%s) Fetching private key file: %s/keys/private/%s.pem\n." "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$dbDirectory" "$keyFileHash" >> /var/log/googlePasswordSync/logs/passwordSync.log
        printf "%s %s (%s) Fetching password file: %s/vault/%s.passwd\n." "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$dbDirectory" "$i" >> /var/log/googlePasswordSync/logs/passwordSync.log

        password=`/usr/sbin/admin/tools/googlePasswordSync/crypto.sh --decode $dbDirectory/keys/private/$keyFileHash.pem --file $dbDirectory/vault/$i.passwd`


        #FETCH AND DECRYPT THE ADMIN PASSWORD
        googleAdminPassword=`/usr/sbin/admin/tools/googlePasswordSync/crypto.sh --decode $dbDirectory/keys/private/$adminPrivateKeyFileName.pem "$adminEncryptedPasword"`

        #CONNECT TO GOOGLE APPS AND CHECK TO SEE IF THE USER ACCOUNT EXISTS
        googleAccount=`php /usr/sbin/authserver/tools/Gapps.php retrieveUser $adminUserName $domainName $googleAdminPassword $emailName`

        printf "%s %s (%s) Google APPS account check results: %s\n." "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$googleAccount" >> /var/log/googlePasswordSync/logs/passwordSync.log

        #ONLY CREATE THE ACCOUNT IF THE CONFIG SAYS TO
        if [ "$googleAccount" != "Error: Specified user not found." -a "$status" == "Enabled" ]
        then
            #GOOGLE ACCONUT EXISTS, SO PUSH THE PASSWORD UPDATE
            printf "%s %s (%s)   Google Apps account found for %s, updating it now.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$emailName" >> /var/log/system.log

            #UPDATE THE GOOGLE APPS PASSWORD
            googleUpdateResult=`php /usr/sbin/authserver/tools/Gapps.php updateUserPassword $adminUserName $domainName $googleAdminPassword $emailName $password`

            if [ -z "$googleUpdateResult" ]
            then
                printf "%s %s (%s) successfully Updated GoogleApps Account [%s]\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$emailName" >> /var/log/system.log
                printf "%s %s (%s) password sync sucessfull for user: %s.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$emailName" >> /var/log/googlePasswordSync/logs/passwordSync.log
            else
                #COULD NOT UPDATE ACCOUNTS
                if [ ! -f $dbDirectory/.queue/.errors.log ]
                then
                    touch $dbDirectory/.queue/.errors.log
                fi 

                printf "%s %s (%s) %s - %s\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$i" "$googleCreateResult" >> $dbDirectory/.queue/.errors.log
                printf "%s %s (%s) Password sync failure for user: %s.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" "$i" >> /var/log/googlePasswordSync/logs/passwordSync.log
            fi
        fi
    done

    rm -rf /tmp/gps.lock

    printf "%s %s (%s) Sync --sync process finished.\n" "`date \"+%b %d %k:%M:%S\"`" "`hostname | awk -F. '{ print $1 }'`" "$0" >> /var/log/system.log
fi
exit 0


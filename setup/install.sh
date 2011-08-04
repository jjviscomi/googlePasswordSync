#!/bin/sh

####################################################################################################
# File Name: install.sh                                                                            #
#                                                                                                  #
# Created by Joseph J Viscomi on 7/8/11.                                                           #
# E-Mail: jjviscomi@gmail.com Facebook: (http://www.facebook.com/joe.viscomi)                      #
# Website: http://www.theObfuscated.org                                                            #
# Date Last Modified: 7/27/2011.                                                                   #
# Version: 0.7b
#                                                                                                  #
# Description: This is the installer for googlePasswordSync.                                       #
#                                                                                                  #
# Instructions: You must be in the package directory and run this file as root: sudo ./install.sh  #
#                                                                                                  #
# Arguments: 1 OPTIONS [--check | --install | --upgrade]                                           #
#                                                                                                  #
# This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. #
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send a   #
# letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA. #
####################################################################################################

VERSION=0.7

printf "Welcome to the googlePasswordSync utility installer for Apple's Open Directory,\n"
printf "This is a collection of bash scripts designed to kepp the passwords synced between\n"
printf "your LDAP server and Google APPS Domain.\n"

printf "Requirements:\n"
printf "\t1. You must have the users actual e-mail address of the Google APPS domain entered under\n"
printf "\t   the info tab in WGM for each account you wish to sync.\n"
printf "\t2. You must have API access enabled on your Google APPS domain.\n"
printf "\t3. You must be root when installing these scripts.\n"
printf "\t4. You must install this on your Open Directory Master.\n"
printf "\t5. You must have the account information for a Google APPS user account that can manage\n"
printf "\t   the domain user accounts.\n"
printf "\t\t* If you have multipule Google APP domains make sure the managment account you want to\n"
printf "\t\t* use has the same username and password for each domain.\n"
printf "\t6. You must be installing this on 10.6 Server or greater.\n"
printf "\t\t* You also need PHP 5.2 or greater but the previous statement takes care of this.\n"
printf "\t7. You must have the DNS FQDN of your Open Directory Master.\n"
printf "\t8. You must know the base LDAP search path for the Open Directory Master.\n\n"
printf "**** While this script does basic checking and configuration it is not fool proof. ****\n\n"

if [ -z "$1" -o "$1" == "--check" -o "$1" == "--install"  -o "$1" == "--upgrade" ]
then
    printf "\nThis installer will now ask some questions and preform some tests to make sure\n"
    printf "everything will be configured correctly and work properly.\n"
    printf "\t\t**** NO MODIFICATIONS TO YOUR COMPUTER WILL BE DONE DURING THIS SEGMENT****\n\n"
    
    read -p "Continue? [Y/n]: " tmp
    if [ -n "$tmp" -a "$tmp" != "Y" -a "$tmp" != "y" ]
    then
        printf "\tExiting Install Checker ...\n"
        exit 1
    fi
    
    odmConnectionErrors=""
    ldapSearchErrors=""
    googleAppsConnectionErrors=""
    gdataFramworkErrors=""

    read -p "Please enter the FQDN of your Open Directory Master as it is entered into DNS: " odm
    if [ -z "$odm" ]
    then
        printf "\tExiting Install Checker ...\n"
        exit 1
    fi

    #MAKE SURE NETWORK CONNECTIVITY EXISTS TO THE LDAP SERVER
    printf " --> CHECKING CONNECTION TO OPEN DIRECTORY MASTER: [%s]\n" "$odm"
    printf "  --> CHECKING PROPER DNS SETTINGS FOR: [%s]\n" "$odm"
    odmIP=`dig $odm 2>&1 | grep -A1 ";; ANSWER SECTION" | grep $odm | awk '{ print $5 }'`
    if [ -z "$odmIP" ]
    then
        odmIP="NOT DETECTED"
    fi
    printf "  --> DNS REGISTERED LOOKUP IP ADDDRESS: %s\n" "$odmIP"

    printf "  --> CHECKING NETWORK CONNECTION TO: [%s]\n" "$odm"
    
    packet_count=`ping -c4 $odm 2>&1 | grep "4 packets transmitted," | awk '{ print $4}'`

    if [ -n "$packet_count" ]
    then
        if [ $packet_count -eq 4 ]
        then
            inetStatus="PERFECT CONNECTION"
        else
            if [ $packet_count -gt 0 ]
            then
                inetStatus="CONNECTION ESTABLISHED, BUT PROBLEMS EXIST"
            else
                inetStatus="NO NETWORK CONNECTION"
                odmConnectionErrors=$inetStatus
            fi
            
        fi
    else
        inetStatus="NO NETWORK CONNECTION"
        odmConnectionErrors=$inetStatus
        packet_count=0
    fi
    printf "       * CONNECTON RESULT TO %s: %s\n" "$odm" "$inetStatus"
    

    #ATTEMPT TO CONSTRUCT THE LDAP SEARCH PATH
    ldapBaseGuess=""
    IFS='.' read -ra LDAP_PARTS <<< "$odm"
    for i in "${LDAP_PARTS[@]}"; do 
        ldapBaseGuess=$ldapBaseGuess"dc=${i},"
    done

    ldapBaseGuess="${ldapBaseGuess%?}"
    
    if [ $packet_count -gt 4 ]
    then
        ldapconnect=`ldapsearch -xLLL -H ldap://$odm -b $ldapBaseGuess | grep "No such object (32)"`
    fi

    if [ -z "$ldapconnect" ]
    then
        if [ $packet_count -gt 0 ]
        then
            printf " --> AUTO CONSTRUCTED LDAP SEARCH BASE: [ %s ]\n" "$ldapBaseGuess"
            printf "       * SUCCESSFULLY SEARCHED THE ODM WITH THE PROVIDED INFORMATION\n"
        else
            printf " --> AUTO CONSTRUCTED LDAP SEARCH BASE: [ %s ]\n" "$ldapBaseGuess"
            printf "       * UNSUCCESSFULLY SEARCHED THE ODM: NO NETWORK CONNECTION TO ODM.\n"
        fi
    else
        printf " --> AUTO CONSTRUCTED LDAP SEARCH BASE: [ %s ]\n" "$ldapBaseGuess"
        printf "       * UNSUCCESSFULLY SEARCHED THE ODM THE LDAP SEARCH BASE MUST BE DIFFERENT\n"

        read -p "Please enter a proper LDAP search base: " ldapBaseGuess
        if [ -z "$ldapBaseGuess" ]
        then
            printf "\tExiting Install Checker ...\n"
            exit 1
        fi
        
        if [ -z "$odmConnectionErrors" ]
        then
            ldapconnect=`ldapsearch -xLLL -H ldap://$odm -b $ldapBaseGuess | grep "No such object (32)"`
        fi

        if [ -n "$ldapconnect" ]
        then
            if [ -n "$odmConnectionErrors" ]
            then
                printf "\tNO CONNECTION TO LDAP TO TEST SEARCH.\n"
                ldapSearchErrors="UNABLE TO TEST: "$ldapBaseGuess
            else
                printf "\tBad LDAP search path.\n"
                ldapSearchErrors="BAD SEARCH PATH: "$ldapBaseGuess
            fi
        fi
    fi

    ldapsearchbase=$ldapBaseGuess

    #MAKE SURE NETWORK CONNECTIVITY EXISTS TO GOOGLE
    printf " --> CHECKING CONNECTION TO GOOGLE APPS\n"
    printf "  --> CHECKING PROPER DNS SETTINGS FOR: [%s]\n" "mail.google.com"
    googleIP=`dig mail.google.com 2>&1 | grep -A1 ";; ANSWER SECTION" | grep mail.google.com | awk '{ print $5 }'`
    if [ -z "$googleIP" ]
    then
       googleIP="NOT DETECTED"
    fi
    printf "  --> DNS REGISTERED LOOKUP IP ADDDRESS: %s\n" "$googleIP"
    packet_count=`ping -c4 mail.google.com 2>&1 | grep "4 packets transmitted," | awk '{ print $4}'`

    
    if [ -n "$packet_count" ]
    then
        if [ $packet_count -eq 4 ]
        then
            inetStatus="PERFECT CONNECTION"
        else
            if [ $packet_count -gt 0 ]
            then
                inetStatus="CONNECTION ESTABLISHED, BUT PROBLEMS EXIST"
            else
                inetStatus="NO NETWORK CONNECTION"
                googleAppsConnectionErrors=$inetStatus
            fi
            
        fi 
    else
        inetStatus="NO NETWORK CONNECTION"
        googleAppsConnectionErrors=$inetStatus
        
    fi
    printf "       * CONNECTON RESULT TO GOOGLE APPS: %s\n" "$inetStatus"


    
    #CHECKING FOR ZEND GDATA FRAMEWORK
    if [ ! -d "/usr/include/php/Zend"  -o ! -d "/usr/include/php/Zend/Gdata" -o ! -f "/usr/include/php/Zend/Gdata/Gapps.php" ]
    then
        gdataFramworkErrors="MISSING LIBRARY"
        printf " --> CHECKING FOR GDATA LIBRARY [/usr/include/php/Zend/Gdata/Gapps.php]: NOT FOUND\n"
    else
        printf " --> CHECKING FOR GDATA LIBRARY [/usr/include/php/Zend/Gdata/Gapps.php]: FOUND\n"
    fi

    #SUMMARY
    printf "\n\n*****\tSUMMARY OF ERRORS:\t*****\n\n"
    checkErrors=0
    if [ -n "$odmConnectionErrors" ]
    then
        printf "CONNECTON ERRORS TO ODM [%s]: %s\n" "$odm" "$odmConnectionErrors"
        checkErrors=5
    else
        printf "CONNECTON ERRORS TO ODM [%s]: NONE\n" "$odm"
    fi

    if [ -n "$ldapSearchErrors" ]
    then
        printf "LDAP SEARCH ERRORS TO ODM [%s]: %s\n" "$odm" "$ldapSearchErrors"
        if [ $checkErrors == 5 ]
        then
            checkErrors=10
        else
            checkErrors=5
        fi
    else
        printf "LDAP SEARCH ERRORS TO ODM [%s]: NONE\n" "$odm"
    fi

    if [ -n "$googleAppsConnectionErrors" ]
    then
        if [ $checkErrors == 5 ]
        then
            checkErrors=10
        else
            checkErrors=5
        fi
        printf "CONNECTON ERRORS TO GOOGLE APPS: %s\n" "$googleAppsConnectionErrors"
    else
        printf "LDAP SEARCH ERRORS TO GOOGLE APPS: NONE\n"
    fi

    

    if [ -n "$gdataFramworkErrors" ]
    then
        printf "Zend's Gdata LIBRARY: NOT INSTALLED  (WE WILL INSTALL THIS - NOT A BIG DEAL)\n"
    else
        printf "Zend's Gdata LIBRARY: INSTALLED\n"
    fi

    if [ -f /LibraryPreferences/org.theObfuscated.googlePasswordSync ]
    then
        DB_DIRECTORY=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync DB_DIRECTORY`
        GAPPS_GLOBAL_SYNC_FILE=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_GLOBAL_SYNC_FILE`

        if [ -f $GAPPS_GLOBAL_SYNC_FILE.plist ]
        then
            if [ -d $DB_DIRECTORY ]
            then
                printf "PREVIOUS INSTALL FOUND (VERSION): %s\n" "`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GPS_VERSION`"
                if [ $checkErrors == 5 ]
                then
                    checkErrors=8
                else
                    checkErrors=3
                fi
            else
                printf "PREVIOUS INSTALL FOUND (INCOMPLETE VERSION): %s\n" "`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GPS_VERSION`"
                if [ $checkErrors == 5 ]
                then
                    checkErrors=9
                else
                    checkErrors=4
                fi
            fi
            
        else
            printf "SOMETHING PREVIOUSLY DETECTED, MIGHT BE OLD OR INCLOMPLETE/DAMAGED INSTALL\n"
            checkErrors=5
        fi
        previouslyInstalled="YES"
    else
        printf "NO PREVIOUS INSTALLATION FOUND\n"
        previouslyInstalled="NO"
    fi
    
    if [ $checkErrors -gt 4 ]
    then
        printf "RECOMENDATION: PLEASE RESOLVE ALL YOUR CONNECTION ISSUES BEFORE COMPLETEING THE INSTALL / UPDATE PROCESS\n"
        completedCheck="NO"
    else
        if [ $checkErrors == 4 ]
        then
            printf "RECOMENDATION: AN UNINSTALL IS SUGGESTED TO BE PREFORMED FIRS, FOLLOWED BY A CLEAN INSTALL\n"
            completedCheck="NO"
        else
            if [ c$heckErrors == 3 ]
            then
                printf "RECOMENDATION: AN UPGRADE IS SUGGESTED AT THIS POINT\n"
                completedCheck="YES"
            fi  
        fi

        if [ $checkErrors -lt 3 ]
        then
            printf "RECOMENDATION: PLEASE PREFORM A CLEAN INSTALL AT THIS POINT\n"
            completedCheck="YES"
        fi  
    fi
    

    
fi #END --check


#PREFORM THE UPGRADE PROCESS
if [ -n "$1" -a "$1" == "--upgrade" -a "$completedCheck" == "YES" ]
then
    if [ ! -f /Library/Preferences/org.theObfuscated.googlePasswordSync.plist ]
    then
        printf "\n\n *** WE CANNOT FIND THE PREVIOUS CONFIGURATION FILE: /Library/Preferences/org.theObfuscated.googlePasswordSync.plist\n Exiting update process\n"
        exit 1
    fi

    if [ ! -f /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist ]
    then
        printf "\n\n *** WE CANNOT FIND THE PREVIOUS CONFIGURATION FILE: /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist\n Exiting update process\n"
        exit 1
    fi

    DB_DIRECTORY=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync DB_DIRECTORY`
    GAPPS_GLOBAL_SYNC_FILE=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_GLOBAL_SYNC_FILE`
    GPS_VERSION=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GPS_VERSION`

    if [ ! -d $DB_DIRECTORY ]
    then
        printf "\n\n *** WE CANNOT FIND THE PREVIOUS DATABASE FOLDER: %s\n Exiting update process\n" "$DB_DIRECTORY"
        exit 1
    fi

    printf " --> READING OLD SETTINGS\n"
    GAPPS_USER=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_USER`
    printf " --> READ GAPPS_USER\n"
    GAPPS_PRIVATE_KEY=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PRIVATE_KEY`
    printf " --> READ GAPPS_PRIVATE_KEY\n"
    GAPPS_PUBLIC_KEY=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PUBLIC_KEY`
    printf " --> READ GAPPS_PUBLIC_KEY\n"
    GAPPS_PASSWORD=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PASSWORD`
    printf " --> READ GAPPS_PASSWORD\n"

    printf "\n***** SPECIAL NOTE: THIS UPGRADE PROCESS REPLACES THE GOOGLE ADMIN KEYPAIR WITH A NEW SET. ******\n"

    read -p "Continue? [Y/n]: " tmp
    if [ -n "$tmp" -a "$tmp" != "Y" -a "$tmp" != "y" ]
    then
        printf "\tExiting Install Checker ...\n"
        exit 1
    fi
    
    launchDaemon=`launchctl list | grep org.theObfuscated.googlePasswordSync`
    if [ -n "$launchDaemon" ]
    then
        printf "   --> UNLOADING UPDATE LAUNCH DAEMON\n"
        launchctl unload /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist
    fi 

    if [ -f $GAPPS_GLOBAL_SYNC_FILE.plist ]
    then
        printf "   --> UNLOADING SYNC LAUNCH DAEMON\n"
        launchctl unload $GAPPS_GLOBAL_SYNC_FILE.plist
    fi

    printf "   --> DISSABLING PASSWORD CHANGE CAPTURE\n"
    #INFORM THE APPLE PASSWORD SERVER TO NOT RUN THE SCRIPT ON PASSWORD CHANGE
    defaults write /Library/Preferences/com.apple.passwordserver ExternalCommand Disabled
    plutil -convert xml1 /Library/Preferences/com.apple.passwordserver.plist

    printf "   --> SERVICES STOPPED, BEGINING THE UPDATE PROCESS\n"
    
    printf "   --> UPDATING SCRIPTS\n"
    printf "    --> UPDATING googlePasswordSync TOOLS ...\n"
    cp -fv ../tools/*.sh /usr/sbin/admin/tools/googlePasswordSync/
    printf "    --> UPDATING gps SYSTEM ...\n"
    cp -fv ../gps/gps.sh /private/etc/org.theObfuscated/googlePasswordSync/gps.sh
    cp -fv ../gps/password_update.sh /usr/sbin/authserver/tools/password_update.sh

    printf "   --> UPDATING GOOGLE APPS ADMIN KEY PAIR\n"
    
    #GENERATING NEW KEY FILE NAME
    adminPrivateKeyFileName="`date \"+%sprivate\" | openssl dgst -sha1 -hex`"
    adminPublicKeyFileName="`date \"+%spublic\" | openssl dgst -sha1 -hex`"

    googleAppsAdminPassword=`/usr/sbin/admin/tools/googlePasswordSync/crypto.sh --decode $DB_DIRECTORY/keys/private/$GAPPS_PRIVATE_KEY.pem "$GAPPS_PASSWORD"`

    

    #RECORD THE KEYS FILE NAME IN THE PLIST FILE
    printf "   --> RECORDING NEW KEY PAIR FILE NAME\n"
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PRIVATE_KEY $adminPrivateKeyFileName
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PUBLIC_KEY $adminPublicKeyFileName

    #CREATE THE NEW KEYPAIR
    printf "   --> CREATING NEW KEY PAIR\n"
    /usr/sbin/admin/tools/googlePasswordSync/crypto.sh --gen 4096 $DB_DIRECTORY/keys/private/$adminPrivateKeyFileName.pem $DB_DIRECTORY/keys/public/$adminPublicKeyFileName.pem
    printf "   --> SAVED KEY PAIR\n"

    #REMOVE OLD KEY FILES
    printf "   --> REMOVING OLD KEY PAIR\n"
    rm -fv $DB_DIRECTORY/keys/private/$GAPPS_PRIVATE_KEY.pem
    rm -fv $DB_DIRECTORY/keys/private/$GAPPS_PUBLIC_KEY.pem

    encryptedGoogleAccountPassword="`/usr/sbin/admin/tools/googlePasswordSync/crypto.sh --encode $DB_DIRECTORY/keys/public/$adminPublicKeyFileName.pem $googleAppsAdminPassword`"

    ## RECORD THE GAPPS_PASSWORD ##
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PASSWORD "$encryptedGoogleAccountPassword"
    printf " --> SAVED GOOGLE APPS PASSWORD USING NEW PUBLIC KEY\n"

    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GPS_VERSION $VERSION
    printf " --> UPDATED googlePasswordSync VERSION\n"

    printf " --> CONFIGURING PASSWORD CHANGE SCRIPT HOOK\n"
    #INFORM THE APPLE PASSWORD SERVER TO RUN THE SCRIPT ON PASSWORD CHANGE
    defaults write /Library/Preferences/com.apple.passwordserver ExternalCommand password_update.sh
    plutil -convert xml1 /Library/Preferences/com.apple.passwordserver.plist

    printf " --> CONFIGURING launchd\n"
    #INFORM LAUNCHD TO LOAD THE DAEMON
    plutil -convert xml1 /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist
    launchctl load /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist
    printf "    --> SCHEDULED %s" "/Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist"
    launchctl load $GAPPS_GLOBAL_SYNC_FILE.plist
    printf "    --> SCHEDULED %s.plist" "$GAPPS_GLOBAL_SYNC_FILE"

    printf "UPGRADE COMPLETE\n"

fi #END --upgrade


# STD INSTALL STARTS HERE
if [ -z "$1" -o "$1" == "--install"  -a "$completedCheck" == "YES" ]
then

    printf "\n\nThis sript is now going to proceed with the installation of the necessary files.\n"
    printf "Please NOTE that ANY previous installation of googlePasswordSync will be removed or rendered unusable.\n"
    
    read -p "Proceed with the installation? [Y/n]: " tmp
    if [ -n "$tmp" -a "$tmp" != "Y" -a "$tmp" != "y" ]
    then
        printf "Exiting install ...\n"
        exit 1
    fi

    printf "BEGINING INSTALL OF googlePasswordSync Utility\n"


    #ZENDS Gdata Framework
    if [ ! -d "/usr/include/php/Zend"  -o ! -d "/usr/include/php/Zend/Gdata" -o ! -f "/usr/include/php/Zend/Gdata/Gapps.php" ]
    then
        read -p "googlePasswordSync requires the Zend Gdata library to work, which is not found, install it now? [Y/n]: " tmp
        if [ -z "$tmp" ]
        then
            tmp="Y"
        fi
        if [ "$tmp" == "Y" -o "$tmp" == "y" -o "$tmp" == "YES" -o "$tmp" == "yes" ]
        then
            printf "Installing Zend ...\n"
        else
            printf "Exiting install ...\n"
            exit 1
        fi

        #CREATE THE INSTALL DIRECTORY IF IT DOESN'T EXIST
        mkdir -pv /usr/include/php
        chown root:wheel /usr/include/php
        chmod 755 /usr/include/php
	
        #COPY THE LIBRARY TO ITS LOCATION
        cp -Rfv ../lib/Zend /usr/include/php/
	
        #ATTEMPT TO UPDATE THE PHP INCLUDE PATH
        if [ -f "/etc/php.ini" ]
        then
            LN=`cat /etc/php.ini | grep -n ";include_path = \".:/php/includes\"" | awk -F: '{ print $1 }'`
            if [ -n "$LN" ]
            then
                LINES=`wc -l /etc/php.ini | awk '{print $1}'`
                SLN=$(($LN-1))
                MLN=$(($LN+1))
			
                SED1=`printf "sed -n '1,%sp' /etc/php.ini" "$SLN"`
                SED2=`printf "sed -n '%s,%sp' /etc/php.ini" "$MLN" "$LINES"`
			
                eval $SED1 > /tmp/googlePasswordSync.modified.php.ini
			
                printf ";include_path = \".:/php/includes\" ;;;Original line\n" >> /tmp/googlePasswordSync.modified.php.ini
                printf "include_path = \".:/php/includes:/usr/include/php\" ;;;New line - added by googlePasswordSync Installer\n" >> /tmp/googlePasswordSync.modified.php.ini

                eval $SED2 >> /tmp/googlePasswordSync.modified.php.ini
			
                mv -f /tmp/googlePasswordSync.modified.php.ini /etc/php.ini
			
                printf "Completed Zend's Gdata library installation.\n"
            else
                printf "The installer is unable to make the change to /etc/php.ini file, so you must do this manually.\nYou must add /usr/include/php to your php include path.\n"
                read -p "Press any key to continue" c
            fi
        else
            if [ -f "/etc/php.ini.default" ]
            then
                LN=`cat /etc/php.ini.default | grep -n ";include_path = \".:/php/includes\"" | awk -F: '{ print $1 }'`
                if [ -n "$LN" ]
                then
                    LINES=`wc -l /etc/php.ini.default | awk '{print $1}'`
                    SLN=$(($LN-1))
                    MLN=$(($LN+1))
				
                    SED1=`printf "sed -n '1,%sp' /etc/php.ini" "$SLN"`
                    SED2=`printf "sed -n '%s,%sp' /etc/php.ini" "$MLN" "$LINES"`
				
                    eval $SED1 > /tmp/googlePasswordSync.modified.php.ini
				
                    printf ";include_path = \".:/php/includes\" ;;;Original line\n" >> /tmp/googlePasswordSync.modified.php.ini
                    printf "include_path = \".:/php/includes:/usr/include/php\" ;;;New line - added by googlePasswordSync Installer\n" >> /tmp/googlePasswordSync.modified.php.ini

                    eval $SED2 >> /tmp/googlePasswordSync.modified.php.ini
				
                    mv -f /tmp/googlePasswordSync.modified.php.ini /etc/php.ini
				
                    printf "Completed Zend's Gdata library installation.\n"
                else
                    prinf "The installer is unable to make the change to /etc/php.ini file, so you must do this manually.\nYou must add /usr/include/php to your php include path.\n"
                    read -p "Press any key to continue" c
                fi
		
            else
                printf "Unable to locate your php.ini file. You must manually edit this file, please add /usr/include/php to your php include path.\n"
                read -p "Press any key to continue" c
            fi
        fi
    fi 

    printf "\n"

    read -p "Enter in the directory you want the database installed to [/.secret]: " dbDirectory
    if [ -z "$dbDirectory" ]
    then
        dbDirectory="/.secret"
    fi

    printf "\n"

    read -p "Enter the username of the Google APPS Account (before the @) [authUpdater]: " googleAccountName
    if [ -z "$googleAccountName" ]
    then
        googleAccountName="authUpdater"
    fi

    printf "\n"

    read -s -p "Enter in the password for $googleAccountName: " googleAccountPassword
    if [ -z "$googleAccountPassword" ]
    then
        printf "\nYou must supply a password for this account, exiting installation of the googlePasswordSync Utility.\n"
        exit 1
    fi

    printf "\n"

    read -p "How often (in seconds) should the googlePasswordSync check for updated/changed passwords updates to your Google Apps Domain? [90]: " syncInterval
    if [ -z "$syncInterval" ]
    then
        syncInterval=90
    fi

    printf "\n"

    read -p "Do you want googlePasswordSync to sync all accounts to Google APPS that is has registered, even though their was no password change? [Y/n]: " tmp
    if [ -z "$tmp" ]
    then
        tmp="Y"
    fi

    if [ "$tmp" == "Y" -o "$tmp" == "y" -o "$tmp" == "yes" -o "$tmp" == "YES" ]
    then
        enableGlobalSync="YES"
        globalSyncFile="gps.`date \"+%s\" | openssl dgst -sha1 -hex`"
        cp -fv ../plists/org.theObfuscated.gpsGeneric.plist /Library/LaunchDaemons/org.theObfuscated.$globalSyncFile.plist
    else
        enableGlobalSync="NO"
    fi
    
    printf "\n"
    
    if [ "$enableGlobalSync" == "YES" ]
    then
        read -p "How often (in seconds) should the googlePasswordSync run to sync all register accounts? [7200] (2 Hours): " globalSync
        if [ -z "$globalSync" ]
        then
            globalSync=7200
        fi
    else
        globalSync=0
    fi

    if [ "$enableGlobalSync" == "YES" ]
    then
        defaults write /Library/LaunchDaemons/org.theObfuscated.$globalSyncFile StartInterval -int $globalSync
        defaults write /Library/LaunchDaemons/org.theObfuscated.$globalSyncFile ProgramArguments -array "/private/etc/org.theObfuscated/googlePasswordSync/gps.sh" "--sync"
        defaults write /Library/LaunchDaemons/org.theObfuscated.$globalSyncFile Label /Library/LaunchDaemons/org.theObfuscated.$globalSyncFile
        
        plutil -convert xml1 /Library/LaunchDaemons/org.theObfuscated.$globalSyncFile.plist

        chmod 640 /Library/LaunchDaemons/org.theObfuscated.$globalSyncFile.plist
    fi

    printf "\n"

    read -p "Do you want googlePasswordSync to create a Google APPS account if one doesn't exist? [Y/n]: " tmp
    if [ -z "$tmp" ]
    then
        tmp="Y"
    fi

    if [ "$tmp" == "Y" -o "$tmp" == "y" -o "$tmp" == "yes" -o "$tmp" == "YES" ]
    then
        createAccount="YES"
    else
        createAccount="NO"
    fi

    printf "\n"
    
    read -p "What size private encryption key do you want to use for user password storage (1024 | 2048 | 4096)? [1024]: " tmp
    if [ -z "$tmp" ]
    then
        userKeySize=1024
    else
        if [ "$tmp" == "1024" ]
        then
            userKeySize=1024
        else
            if [ "$tmp" == "2048" ]
            then
                userKeySize=2048
            else
                if [ "$tmp" == "4096" ]
                then
                    userKeySize=4096
                else
                    userKeySize=1024
                fi
            fi
        fi
    fi

    printf "\n"
    

    #DELETE ALL PREVIOUS LOCAL FLAT FILES
    if [ -d $dbDirectory ]
    then
        printf " --> REMOVING PREVIOUS INSTALATION FILES\n"
        rm -rfv $dbDirectory
    fi

    if [ -f "/Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist" ]
    then
        launchDaemon=`launchctl list | grep org.theObfuscated.googlePasswordSync`
        if [ -n "$launchDaemon" ]
        then
            printf "   --> UNLOADING PREVIOUS LAUNCH DAEMON AND REMOVING PLIST FILES\n"
            launchctl unload /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist
        fi 
        rm -rfv /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist
    fi


    if [ -d "/private/etc/org.theObfuscated/googlePasswordSync" ]
    then
        printf "   --> REMOVING PREVIOUS PROGRAM DIRECTORY\n"
        rm -rf /private/etc/org.theObfuscated/googlePasswordSync
    fi

    printf " --> FINISHED CLEANING PREVIOUS INSTALATION FILES\n"


    #CREATE ADMIN TOOLS DIRECTORY IF IT DOESN'T EXIST
    if [ ! -d /usr/sbin/admin ]
    then
        printf " --> CREATING ADMIN DIRECTORY\n"
        mkdir -vp /usr/sbin/admin
        chown root:wheel /usr/sbin/admin
        chmod 700 /usr/sbin/admin
	
        mkdir -vp /usr/sbin/admin/tools
        chown root:wheel /usr/sbin/admin/tools
        chmod 700 /usr/sbin/admin/tools

        mkdir -vp /usr/sbin/admin/tools/googlePasswordSync
        chown root:wheel /usr/sbin/admin/tools/googlePasswordSync
        chmod 700 /usr/sbin/admin/tools/googlePasswordSync
    else
        if [ ! -d /usr/sbin/admin/tools ]
        then
            mkdir -pv /usr/sbin/admin/tools
            chown root:wheel /usr/sbin/admin/tools
            chmod 700 /usr/sbin/admin/tools

            mkdir -vp /usr/sbin/admin/tools/googlePasswordSync
            chown root:wheel /usr/sbin/admin/tools/googlePasswordSync
            chmod 700 /usr/sbin/admin/tools/googlePasswordSync

        else
            if [ ! -d /usr/sbin/admin/tools/googlePasswordSync ]
            then
                mkdir -vp /usr/sbin/admin/tools/googlePasswordSync
                chown root:wheel /usr/sbin/admin/tools/googlePasswordSync
                chmod 700 /usr/sbin/admin/tools/googlePasswordSync
            else
                rm -rvf /usr/sbin/admin/tools/googlePasswordSync/
            fi
            
        fi 
    fi 

    #CREATE DIRECTORY TREE
    printf " --> CREATING DIRECTORY TREE\n"
    mkdir -vp $dbDirectory
    chown root:wheel $dbDirectory
    chmod 700 $dbDirectory

    mkdir -vp $dbDirectory/info 
    chown root:wheel $dbDirectory/info
    chmod 700 $dbDirectory/info

    mkdir -vp $dbDirectory/vault
    chown root:wheel $dbDirectory/vault
    chmod 700 $dbDirectory/vault

    mkdir -vp /var/log/googlePasswordSync/logs
    chown root:wheel /var/log/googlePasswordSync/logs
    chmod 755 /var/log/googlePasswordSync/logs
	
    mkdir -vp $dbDirectory/old
    chown root:wheel $dbDirectory/old
    chmod 700 $dbDirectory/old

    mkdir -vp $dbDirectory/.queue
    chown root:wheel $dbDirectory/.queue
    chmod 755 $dbDirectory/.queue

    mkdir -vp $dbDirectory/keys
    chown root:wheel $dbDirectory/keys
    chmod 700 $dbDirectory/keys
    
    mkdir -vp $dbDirectory/keys/public 
    chown root:wheel $dbDirectory/keys/public 
    chmod 700 $dbDirectory/keys/public 
    
    mkdir -vp $dbDirectory/keys/private
    chown root:wheel $dbDirectory/keys/private
    chmod 700 $dbDirectory/keys/private

    touch $dbDirectory/.queue/push.queue
    chown root:wheel $dbDirectory/.queue/push.queue
    chmod 755 $dbDirectory/.queue/push.queue

    touch $dbDirectory/.queue/.push.wait.queue
    chown root:wheel $dbDirectory/.queue/.push.wait.queue
    chmod 755 $dbDirectory/.queue/.push.wait.queue

    touch $dbDirectory/.queue/gps.queue
    chown root:wheel $dbDirectory/.queue/gps.queue
    chmod 755 $dbDirectory/.queue/gps.queue

    printf " --> COPYING FILES INTO THEIR FINAL DESTINATIONS\n"

    printf " --> INSTALLING ADMIN TOOLS\n"

    #INSTALL TOOLS TO THE ADMIN FOLDER
    #INSTALL CRYPTO TOOL
    cp -vf  ../tools/crypto.sh /usr/sbin/admin/tools/googlePasswordSync/crypto.sh
    chown root:wheel /usr/sbin/admin/tools/googlePasswordSync/crypto.sh
    chmod 700 /usr/sbin/admin/tools/googlePasswordSync/crypto.sh

    #INSTALL LDAP TOOL
    cp -vf ../tools/ldapinfo.sh /usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh
    chown root:wheel /usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh
    chmod 700 /usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh
    #chmod u+s /usr/sbin/admin/tools/googlePasswordSync/ldapinfo.sh

    printf " --> INSTALLING PASSWORD CAPTURE SCRIPT\n"
    #INSTALL PASSWORD CAPTURE SCRIPT - DONE
    if [ ! -d /usr/sbin/authserver/tools ]
    then
        printf "There is something wrong, creating directory that should already exist\n"
        mkdir -pv /usr/sbin/authserver/tools/
    fi
	
    cp -vf ../gps/password_update.sh /usr/sbin/authserver/tools/password_update.sh
    chown root:wheel /usr/sbin/authserver/tools/password_update.sh
    chmod 700 /usr/sbin/authserver/tools/password_update.sh
	chmod u+s /usr/sbin/authserver/tools/password_update.sh

	
    printf " --> INSTALLING GDATA SHELL INTERFACE\n"
    #INSTALL PHP SHELL INTERFACE
    cp -fv ../tools/Gapps.php /usr/sbin/admin/tools/googlePasswordSync/Gapps.php
    chmod +x /usr/sbin/admin/tools/googlePasswordSync/Gapps.php
    ln -s /usr/sbin/admin/tools/googlePasswordSync/Gapps.php /usr/sbin/authserver/tools/Gapps.php

    printf " --> CREATED SYMLINK TO GAPPS.PHP\n"

    #INSTALL SYNC DAEMON - DONE
    if [ ! -d /private/etc/org.theObfuscated ]
    then
        mkdir -p /private/etc/org.theObfuscated
    fi

    printf " --> INSTALLING googlePasswordSync SYNCING DAEMON\n"

    mkdir -p /private/etc/org.theObfuscated/googlePasswordSync
    cp -fv ../gps/gps.sh /private/etc/org.theObfuscated/googlePasswordSync/gps.sh
    chown root:wheel /private/etc/org.theObfuscated/googlePasswordSync/gps.sh
    chmod 750 /private/etc/org.theObfuscated/googlePasswordSync/gps.sh
    chmod u+s /private/etc/org.theObfuscated/googlePasswordSync/gps.sh

    printf " --> CONFIGURING LAUNCH DAEMON\n"

    #CONFIGURE SYNC DAEMON
    cp -fv ../plists/org.theObfuscated.googlePasswordSync.plist /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist
    chown root:wheel /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist

    #INSTALL THE PREFRENCES PLIST FILE
    cp -fv ../plists/org.theObfuscated.googlePasswordSyncServer.plist /Library/Preferences/org.theObfuscated.googlePasswordSync.plist
    chown root:wheel /Library/Preferences/org.theObfuscated.googlePasswordSync.plist
    chmod 700 /Library/Preferences/org.theObfuscated.googlePasswordSync.plist

    printf " --> GENERATING googlePasswordSync SERVER RSA KEYPAIR\n"

    adminPrivateKeyFileName="`date \"+%sprivate\" | openssl dgst -sha1 -hex`"
    adminPublicKeyFileName="`date \"+%spublic\" | openssl dgst -sha1 -hex`"

    #RECORD THE KEYS FILE NAME IN THE PLIST FILE
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PRIVATE_KEY $adminPrivateKeyFileName
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PUBLIC_KEY $adminPublicKeyFileName

    /usr/sbin/admin/tools/googlePasswordSync/crypto.sh --gen 4096 $dbDirectory/keys/private/$adminPrivateKeyFileName.pem $dbDirectory/keys/public/$adminPublicKeyFileName.pem
    
    plainTextGoogleAccountPassword=$googleAccountPassword
    printf " --> ENCRYPTING GOOGLE APPS PASSWORD\n"
    encryptedGoogleAccountPassword="`/usr/sbin/admin/tools/googlePasswordSync/crypto.sh --encode $dbDirectory/keys/public/$adminPublicKeyFileName.pem $plainTextGoogleAccountPassword`"
    ## RECORD THE GAPPS_PASSWORD ##
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_PASSWORD "$encryptedGoogleAccountPassword"
    printf " --> SAVED GOOGLE APPS PASSWORD\n"


    #RECORD THE REST OF THE SETTINGS
    printf " --> SAVING SETTINGS\n"
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync DB_DIRECTORY $dbDirectory
    printf " --> SAVED DB_DIRECTORY\n"
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_USER $googleAccountName
    printf " --> SAVED GAPPS_USER\n"
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync USER_KEYSIZE -int $userKeySize
    printf " --> SAVED USER_KEYSIZE\n"
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync ODM $odm
    printf " --> SAVED ODM\n"
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync LDAP $ldapsearchbase
    printf " --> SAVED LDAP\n"
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_CREATE_ACCOUNTS -bool $createAccount
    printf " --> SAVED GAPPS_CREATE_ACCOUNTS\n"
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_GLOBAL_SYNC_INTERVAL $globalSync
    printf " --> SAVED GAPPS_GLOBAL_SYNC_INTERVAL\n"
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_SYNC_INTERVAL -int $syncInterval
    printf " --> GAPPS_SYNC_INTERVAL\n"
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GPS_VERSION $VERSION
    printf " --> SAVED GPS VERSION\n"

    
    if [ "$enableGlobalSync" == "YES" ]
    then
        defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_GLOBAL_SYNC -bool $enableGlobalSync
        printf " --> SAVED GAPPS_GLOBAL_SYNC\n"
        defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_GLOBAL_SYNC_FILE /Library/LaunchDaemons/org.theObfuscated.$globalSyncFile
        printf " --> SAVED GLOBAL SYNC FILE\n"
    else
        defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_GLOBAL_SYNC -bool NO
        printf " --> SAVED GAPPS_GLOBAL_SYNC\n"
    fi
    
    plutil -convert xml1 /Library/Preferences/org.theObfuscated.googlePasswordSync.plist

    defaults write /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync StartInterval -int $syncInterval
    defaults write /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync ProgramArguments -array "/private/etc/org.theObfuscated/googlePasswordSync/gps.sh" "--update"
    plutil -convert xml1 /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist

    chmod 640 /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist

	read -p "What is the Google APPS domain the user $googleAccountName can connect with, this is everything after the '@': " googleAppsDomain
	googleAppsTest=`php /usr/sbin/authserver/tools/Gapps.php retrieveUser $googleAccountName $googleAppsDomain $plainTextGoogleAccountPassword $googleAccountName | grep "Admin: Yes"`
	if [ -n "$googleAppsTest" ]
	then
		printf "  --> TESTING AUTHENTICATION TO GOOGLE APPS: Sucessful\n"
	else
		printf "  --> TESTING AUTHENTICATION TO GOOGLE APPS: Failed\n"
	fi

fi

printf " --> CONFIGURING PASSWORD CHANGE SCRIPT HOOK\n"
#INFORM THE APPLE PASSWORD SERVER TO RUN THE SCRIPT ON PASSWORD CHANGE
defaults write /Library/Preferences/com.apple.passwordserver ExternalCommand password_update.sh
plutil -convert xml1 /Library/Preferences/com.apple.passwordserver.plist

printf " --> CONFIGURING launchd\n"
#INFORM LAUNCHD TO LOAD THE DAEMON
plutil -convert xml1 /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist
launchctl load /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist

if [ "$enableGlobalSync" == "YES" ]
then
    printf " --> CONFIGURING GLOBAL SYNC launchd\n"
    launchctl load "/Library/LaunchDaemons/org.theObfuscated.$globalSyncFile.plist"
fi

printf "INSTALATION COMPLETE\n"

exit 0
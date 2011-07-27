#!/bin/sh

####################################################################################################
# File Name: uninstall.sh                                                                          #
#                                                                                                  #
# Created by Joseph J Viscomi on 7/8/11.                                                           #
# E-Mail: jjviscomi@gmail.com Facebook: (http://www.facebook.com/joe.viscomi)                      #
# Website: http://www.theObfuscated.org                                                            #
# Date Last Modified: 7/27/2011.                                                                   #
# Version: 0.7b                                                                                    #
#                                                                                                  #
# Description: This script will effetivly remove all installation and changes made by              #
#              googlePasswordSync installer and while the service was running.                     #
#              This is distributed with org.theObfuscated.googlePasswordSync package.              #
#                                                                                                  #
# Instructions: sudo ./uninstall.sh                                                                #
#                                                                                                  #
# Arguments: NONE                                                                                  #
#                                                                                                  #
#                                                                                                  #
# This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. #
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send a   #
# letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA. #
####################################################################################################


printf "UNINSTALLING googlePasswordSync.\n"

dbDirectory=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync DB_DIRECTORY`
GAPPS_GLOBAL_SYNC_FILE=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_GLOBAL_SYNC_FILE`

printf "INSTALLED DIRECTORY: %s\n" "$dbDirectory"
printf "GLOBAL SYNC FILE: %s\n" "$GAPPS_GLOBAL_SYNC_FILE"

#DELETE ALL LOCAL FLAT FILES
if [ -d $dbDirectory ]
then
	printf " --> REMOVING PREVIOUS INSTALATION FILES\n"
	rm -rfv $dbDirectory
fi



if [ -f "$GAPPS_GLOBAL_SYNC_FILE.plist" ]
then
    launchDaemon=`launchctl list | grep $GAPPS_GLOBAL_SYNC_FILE`
    if [ -n "$launchDaemon" ]
    then
        printf "   --> UNLOADING PREVIOUS LAUNCH DAEMON AND REMOVING PLIST FILES\n"
        launchctl unload $GAPPS_GLOBAL_SYNC_FILE.plist
        rm -rfv $GAPPS_GLOBAL_SYNC_FILE.plist
    fi 
    
fi        


if [ -f "/Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist" ]
then
	launchDaemon=`launchctl list | grep org.theObfuscated.googlePasswordSync`
	if [ -n "$launchDaemon" ]
	then
		printf "   --> UNLOADING PREVIOUS LAUNCH DAEMON AND REMOVING PLIST FILES\n"
		launchctl unload /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist
        rm -rfv /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist
	fi 
	
fi


if [ -d "/private/etc/org.theObfuscated/googlePasswordSync" ]
then
	printf "   --> REMOVING PREVIOUS PROGRAM DIRECTORY\n"
	rm -rf /private/etc/org.theObfuscated/googlePasswordSync
fi

rm -rfv /Library/Preferences/org.theObfuscated.googlePasswordSync.plist

printf " --> FINISHED CLEANING INSTALATION FILES\n"

#REMOVE ADMIN TOOLS DIRECTORY IF IT DOESN'T EXIST
if [ -d /usr/sbin/admin/tools/googlePasswordSync ]
then
	rm -rfv /usr/sbin/admin/tools/googlePasswordSync
fi 

#INFORM THE APPLE PASSWORD SERVER TO NOT RUN THE SCRIPT ON PASSWORD CHANGE
defaults write /Library/Preferences/com.apple.passwordserver ExternalCommand Disabled
plutil -convert xml1 /Library/Preferences/com.apple.passwordserver.plist

#REMOVE PASSWORD CAPTURE SCRIPT - DONE
rm -vrf /usr/sbin/authserver/tools/password_update.sh
rm -vff /usr/sbin/authserver/tools/Gapps.php

#REMOVE SYNC DAEMON - DONE
if [ -d /private/etc/org.theObfuscated/gps ]
then
	rm -rfv /private/etc/gps
fi

rm -rfv /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist
rm -rfv /Library/Preferences/org.theObfuscated.googlePasswordSync.plist



#REMOVE ZENDS Gdata Framework
if [ -d "/usr/include/php/Zend/Gdata" ]
then
	read -p "Would you like to uninstall the Gdata Zend library [Y]: " installZend
	if [ -z "$installZend" -o  "$installZend" == "Y" -o "$installZend" == "y" ]
	then
		rm -rfv /usr/include/php/Zend/Gdata
	fi
fi

if [ -d "/var/log/googlePasswordSync" ]
then
	read -p "Would you like to remove the log files [Y]: " uninstallLogs
	if [ -z "$uninstallLogs" -o  "$uninstallLogs" == "Y" -o "$uninstallLogs" == "y" ]
	then
		rm -rfv /var/log/googlePasswordSync
	fi
fi


printf "UNINSTALATION COMPLETE\n"
#!/bin/sh

####################################################################################################
# File Name: install.sh                                                                            #
#                                                                                                  #
# Created by Joseph J Viscomi on 7/8/11.                                                           #
# E-Mail: jjviscomi@gmail.com Facebook: (http://www.facebook.com/joe.viscomi)                      #
# Website: http://www.theObfuscated.org                                                            #
# Date Last Modified: 7/27/2011.                                                                   #
# Version: 0.8
#                                                                                                  #
# Description: This is the installer for googlePasswordSync.                                       #
#                                                                                                  #
# Instructions: You must be in the package directory and run this file as root: sudo ./install.sh  #
#                                                                                                  #
#                                                                                                  #
# This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. #
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send a   #
# letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA. #
####################################################################################################


#####    START GLOBAL VARS    #####

VERSION=0.8
DEBUG=false

#INSTALL ARGS
INSTALL=
CHECK=
UPGRADE=
VERBOSE=
QUIET=
TESTING=
STOP=1

#SYSTEM ARGS
OPENDIRECTORY_MASTER_FQDN=
OPENDIRECTORY_MASTER_IPADDRESS=
OPENDIRECTORY_LDAP_SEARCH_BASE=
OSX_NAME=
OSX_VERSION=
OSX_MAJOR=
OSX_BUILD=

#IS ZEND GDATA LIBRARY INSTALLED YES/NO
ZEND_GDATA=

#IS THERE A PREVIOUS INSTALATION YES/NO
PREVIOUS_VERSION=

DB_DIRECTORY=
GPS_VERSION=

GADS_PASSWORD=
GADS_USER=
GADS_RECORD_NAME=



#####    END GLOBAL VARS    #####

function DEBUG_MSG()
{
    if [ $DEBUG == true ]
    then
        printf " ** [DEBUG_MSG - %s(%s)]: %s\n" "$2" "$3" "$1"
    fi
}


#PRINTS OUT HOW TO USE THE INSTALLER
function usage()
{
    printf "Usage: %s [-c | -i | -u] [-q] [-v | -t] [-d]\n\n" "$0"

    printf "This script is used to check, install, or upgrade googlePasswordSync.\n\n"

    printf "OPTIONS:\n"
    printf " -c      This will inspect the state of the system and see if googlePasswordSync can be successfully\n"
    printf "         installed and what what needs to be done.\n\n"

    printf " -i      This will install googlePasswordSync, it will overwrite any previous modifications or installations.\n\n"

    printf " -u      This will preform the upgrade process, saving all current states and information of a previous installations.\n\n"

    printf " -v      This will make the installer be verbose.\n\n"

    printf " -q      This will make the installer be as quite as possible, accepting all the defaults.\n\n"

    printf " -t      This will install googlePasswordSync in test mode and cause it to be VERY verbose in the logging\n"
    printf "         (NOT RECCOMMEND FOR PRODUCTION USE).\n\n"

    printf " -d      This will enable DEBUG MESSAGES TO BE PRINTED DURING INSTALL>\n\n"

}

#SETS UP THE INSTALLER FROM THE PASSED COMMANDLINE ARGS
while getopts "hciuvqtd" OPTION
do
    case $OPTION in 
        h)
            usage
            exit 1
            ;;
        c)
            CHECK="YES"
            ;;
        i)
            INSTALL="YES"
            ;;
        u)
            UPGRADE="YES"
            ;;
        v)
            VERBOSE="YES"
            ;;
        q)
            QUIET="YES"
            ;;
        t)  
            TESTING="YES"
            ;;
        d)
            DEBUG=true
            ;;
        \?)
            usage
            exit
            ;;
    esac
done        





##### START SCRIPT FUNCTIONS #####


function welcomeMessage()
{

    printf "Welcome to the googlePasswordSync utility installer for Apple's Open Directory,\n"
    printf "This is a collection of bash scripts designed to keep the passwords synced between\n"
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
    printf "\t6. You must be installing this on 10.58, 10.6, or 10.7 Server or greater.\n"
    printf "\t\t* You also need PHP 5.2 or greater but the previous statement takes care of this.\n"
    printf "\t7. You must have the DNS FQDN of your Open Directory Master (NOT A .local).\n"
    printf "\t8. You must know the base LDAP search path for the Open Directory Master.\n\n"
    printf "**** While this script does basic checking and configuration it is not fool proof. ****\n\n"

    return 0
}

function preCheckMessage()
{
    printf "\nThis installer will now ask some questions and preform some tests to make sure\n"
    printf "everything will be configured correctly and work properly.\n"
    printf "\t\t**** NO MODIFICATIONS TO YOUR COMPUTER WILL BE DONE DURING THIS SEGMENT****\n\n"

    return 0
}

function yesCheck()
{
    if [ "$1" == "Y" -o "$1" == "y" -o "$1" == "YES" -o "$1" == "yes" -o "$1" == "Yes" -o "$1" == "YEs" -o "$1" == "yES" -o "$1" == "yeS" ]
    then
        return 0
    fi

    return 1
}

function continueInstall()
{
    local tmp
    
    if [ "$QUIET" == "YES" ]
    then
        printf "Continue with install? [Y/n]: Y\n"
        tmp="Y"
    else
        read -p "Continue with the install? [Y/n]: " tmp
    fi

    if [ -z "$tmp" ]
    then
        tmp="Y"
    fi

    yesCheck $tmp
    if [ $? == 1 ]
    then
        exit 1
    fi

    return $?
}

function getOSInformation(){

    local tmp
    tmp=`sw_vers`

    OSX_NAME=`echo $tmp | awk '{ printf "%s %s %s", $2, $3, $4 }'`
    OSX_VERSION=`echo $tmp | awk '{ printf "%s", $6 }'`
    OSX_MAJOR=`echo $OSX_VERSION | awk -F. '{ printf "%s", $2 }'` 
    OSX_BUILD=`echo $tmp | awk '{ printf "%s", $8 }'`

    return 0
}

#PROMPTS FOR THE FQDN OF THE OPEN DIRECTORY MASTER
function getOpenDirectoryMasterFQDN()
{
    #REQUIRES FQDN OF SERVER TO CHECK
    local tmp
    if [ "$QUIET" == "YES" ]
    then
        tmp=`hostname`
        printf "Please enter the FQDN of your Open Directory Master as it is entered into DNS: %s\n" "$tmp"
    else
        while [ -z $tmp ]
        do
            read -p "Please enter the FQDN of your Open Directory Master as it is entered into DNS: " tmp
        done
    fi

    #SET THE OPENDIRECTORY
    OPENDIRECTORY_MASTER_FQDN=$tmp
    
    #CHECK TO SEE IF $tmp == hostname
    return 0

}

#TAKES A FQDN AND PRINTS ITS IPADDRESS TO STDOUT
function getIPAddressFromFQDN()
{
    OPENDIRECTORY_MASTER_IPADDRESS=`dig $1 2>&1 | grep -A1 ";; ANSWER SECTION" | grep $1 | awk '{ printf "%s" $5 }'`

    return 0
}

#CHECKS THE NETWORK CONNECTION OF THE SPECIFIED ADDRESS
function checkNetworkConnection()
{
    local ip

    if [ "$VERBOSE" == "YES" ]
    then
        printf " --> CHECKING CONNECTION TO: [%s]\n" "$1"
        printf "  --> CHECKING PROPER DNS SETTINGS FOR: [%s]\n" "$1"
    fi

    ip=`dig $1 2>&1 | grep -A1 ";; ANSWER SECTION" | grep $1 | awk '{ printf "%s" $5 }'`

    if [ -z $ip ]
    then
        if [ "$VERBOSE" == "YES" ]
        then
            printf "  --> UNABLE TO DETERMIN THE IP ADDRESS FOR: %s\n" "$1"
        fi

        DEBUG_MSG "IP ADDRESS: CANNOT BETERMIN THE IP ADDRESS" $FUNCNAME $LINENO
        STOP=0
        return 1
    fi

    if [ -n $ip ]
    then
        if [ "$VERBOSE" == "YES" ]
        then
            printf "  --> DNS REGISTERED LOOKUP IP ADDDRESS: %s\n" "$ip"
            printf "  --> CHECKING NETWORK CONNECTION TO: [%s]\n" "$1"
        fi
        DEBUG_MSG "IP ADDRESS: $ip" $FUNCNAME $LINENO
    fi
    
    #CHECK HOW MANY PACKETS ARE RETURNED FROM 4 ICMP PACKETS
    packet_count=`ping -c4 $1 2>&1 | grep "4 packets transmitted," | awk '{ print $4}'`

    if [ -n $packet_count ]
    then
        if [ $packet_count -eq 4 ]
        then
            if [ "$VERBOSE" == "YES" ]
            then
                printf "  --> NETWORK CONNECTIVITY TEST TO %s IS SUCCESSFULL.\n" "$1"
            fi
            DEBUG_MSG "NETWORK CONNECTIVITY TEST TO $1 IS SUCCESSFULL" $FUNCNAME $LINENO
        else
            if [ $packet_count -gt 0 ]
            then
                if [ "$VERBOSE" == "YES" ]
                then
                    printf "  --> NETWORK CONNECTIVITY TEST TO %s DETECTED PROBLEMS.\n" "$1"
                fi
                DEBUG_MSG "NETWORK CONNECTIVITY PROBLEMS, PACKET COUNT: $packet_count" $FUNCNAME $LINENO
            else
                if [ "$VERBOSE" == "YES" ]
                then
                    printf "  --> NETWORK CONNECTIVITY TEST TO %s FAILED.\n" "$1"
                fi
                DEBUG_MSG "NETWORK CONNECTIVITY FAILURE" $FUNCNAME $LINENO
                STOP=0
                return 1
            fi
        fi
    else
        if [ "$VERBOSE" == "YES" ]
        then
            printf "  --> NETWORK CONNECTIVITY TEST TO %s FAILED.\n" "$1"
        fi
        STOP=0
        return 1
    fi
    return 0
}

#GUESS WHAT THE CONPUTER LDAP SEARCH BASE IS
function guessLDAPSearchBase()
{
    #ATTEMPT TO CONSTRUCT THE LDAP SEARCH PATH
    local ldapBaseGuess=""
    IFS='.' read -ra LDAP_PARTS <<< "$1"
    for i in "${LDAP_PARTS[@]}"; do 
        ldapBaseGuess=$ldapBaseGuess"dc=${i},"
    done

    ldapBaseGuess="${ldapBaseGuess%?}"

    OPENDIRECTORY_LDAP_SEARCH_BASE=$ldapBaseGuess

}

#PROMPT THE USER TO ENTER IN THE LDAP SEARCH BASE
function getLDAPSearchBase()
{
    read -p "Please enter the base LDAP search path: " tmp

    while [ -z $tmp ]
    do
        printf "\n"
        read -p "Please enter the base LDAP search path: " tmp
    done

    #//TO DO SET THE GLOBAL VARIABLE INSTEAD OF THE PRINTF
    OPENDIRECTORY_LDAP_SEARCH_BASE=$tmp
}

#CHECK TO SEE IF YOU CAN PREFORM A LOOKUP IN LDAP
function checkLDAPSearchBase()
{
    local ldapconnect=`ldapsearch -xLLL -H ldap://$1 -b $2 2>&1`
    local noLDAPObject=` echo $ldapconnect | grep "No such object (32)"`
    local noLDAPConnection=`echo $ldapconnect | grep "Can't contact LDAP server (-1)"`

    if [ -n "$noLDAPConnection" ]
    then
        DEBUG_MSG "LDAP UNSUCESSFULLY SEARCHED $1, USING $2: Can't contact LDAP server (-1)" $FUNCNAME $LINENO
        return 2
    fi

    if [ -n "$noLDAPObject" ]
    then
        DEBUG_MSG "LDAP UNSUCESSFULLY SEARCHED $1, USING $2: No such object (32)" $FUNCNAME $LINENO
        return 1
    fi

    DEBUG_MSG "LDAP SUCESSFULLY SEARCHED $1, USING $2" $FUNCNAME $LINENO 
    return 0
    
}

#CHECK TO SEE IF THE COMPUTER CAN CONNECT TO GOOGLE (BASICALLY SEE IF THERE IS AN INTERNET CONNECTION)
function checkConnectionToGoogle()
{
    local googleIP=`dig mail.google.com 2>&1 | grep -A1 ";; ANSWER SECTION" | grep mail.google.com | awk '{ print $5 }'`
    DEBUG_MSG "IP ADDRESS FOR MAIL.GOOGLE.COM: $googleIP" $FUNCNAME $LINENO

    if [ -z "$googleIP" ]
    then
        if [ "$VERBOSE" == "YES" ]
        then
            printf "  --> UNABLE TO DETERMIN IP ADDRESS OF MAIL.GOOGLE.COM\n"
        fi
    else
        if [ "$VERBOSE" == "YES" ]
        then
            printf "  --> DNS REGISTERED LOOKUP IP ADDDRESS: %s\n" "$googleIP"
        fi
        DEBUG_MSG "IP ADDRESS FOR MAIL.GOOGLE.COM: $googleIP" $FUNCNAME $LINENO
    fi

      
    packet_count=`ping -c4 mail.google.com 2>&1 | grep "4 packets transmitted," | awk '{ print $4}'`
    DEBUG_MSG "PACKET COUNT TO MAIL.GOOGLE.COM: $packet_count" $FUNCNAME $LINENO


    if [ -n "$packet_count" ]
    then
        if [ $packet_count -eq 4 ]
        then
            if [ "$VERBOSE" == "YES" ]
            then
                printf "  --> PERFECT CONNECTION TO MAIL.GOOGLE.COM\n"
            fi
            DEBUG_MSG "PERFECT CONNECTION TO MAIL.GOOGLE.COM" $FUNCNAME $LINENO
        else
            if [ $packet_count -gt 0 ]
            then
                if [ "$VERBOSE" == "YES" ]
                then
                    printf "  --> PROBLEMS WITH CONNECTION TO MAIL.GOOGLE.COM\n"
                fi
                DEBUG_MSG "PROBLEMS WITH CONNECTION TO MAIL.GOOGLE.COM" $FUNCNAME $LINENO
            else
                if [ "$VERBOSE" == "YES" ]
                then
                    printf "  --> PROBLEMS WITH CONNECTION TO MAIL.GOOGLE.COM\n"
                fi
                DEBUG_MSG "PROBLEMS WITH CONNECTION TO MAIL.GOOGLE.COM" $FUNCNAME $LINENO
            fi

        fi 
    else
        if [ "$VERBOSE" == "YES" ]
        then
            printf "  --> NO CONNECTION TO MAIL.GOOGLE.COM\n"
        fi
        DEBUG_MSG "NO CONNECTION TO MAIL.GOOGLE.COM" $FUNCNAME $LINENO
        STOP=0
        return 1
    fi

    return 0
}

#CHECK TO SEE IF THE ZEND LIBRARY IS PROPERLY INSTALLED
function checkForZendGdataLibrary()
{
    #CHECKING FOR ZEND GDATA FRAMEWORK
    if [ ! -d "/usr/include/php/Zend"  -o ! -d "/usr/include/php/Zend/Gdata" -o ! -f "/usr/include/php/Zend/Gdata/Gapps.php" ]
    then
        if [ "$VERBOSE" == "YES" ]
        then
            printf "  --> MISSING ZEND Gdata LIBRARY\n"
        fi
        DEBUG_MSG "MISSING ZEND Gdata LIBRARY: /usr/include/php/Zend/Gdata/Gapps.php" $FUNCNAME $LINENO
        return 1
    else
        if [ "$VERBOSE" == "YES" ]
        then
            printf "  --> FOUND ZEND Gdata LIBRARY\n"
        fi
        DEBUG_MSG "FOUND ZEND Gdata LIBRARY: /usr/include/php/Zend/Gdata/Gapps.php" $FUNCNAME $LINENO
        return 0
    fi

    return 0
}

#CHECK TO SEE IF GPS WAS INSTALLED BEFORE
function checkForPreviousInstallation()
{
    if [ -f /LibraryPreferences/org.theObfuscated.googlePasswordSync ]
    then
        DB_DIRECTORY=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync DB_DIRECTORY`
        GAPPS_GLOBAL_SYNC_FILE=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_GLOBAL_SYNC_FILE`
        DEBUG_MSG "FOUND PREVIOUS GPS SETTINGS FILE" $FUNCNAME $LINENO

        if [ -d $DB_DIRECTORY ]
        then
            GPS_VERSION=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GPS_VERSION`
            DEBUG_MSG "PREVIOUS VERSION NUMBER: $GPS_VERSION" $FUNCNAME $LINENO
        fi

       
        return 0
    fi
    DEBUG_MSG "NO PREVIOUS VERSION DETECTED" $FUNCNAME $LINENO
    return 1
}

#SHUTDOWN THE GPS DAEMON
function stopGooglePasswordSync(){

    local launchDaemon=`launchctl list | grep org.theObfuscated.googlePasswordSync`

    DEBUG_MSG "org.theObfuscated.googlePasswordSync: $launchDaemon" $FUNCNAME $LINENO
    
    if [ -f "/Library/Preferences/org.theObfuscated.googlePasswordSync.plist" ]
    then
        DEBUG_MSG "DETECTED /Library/Preferences/org.theObfuscated.googlePasswordSync.plist" $FUNCNAME $LINENO

        local gapsSyncFile=`defaults read /Library/Preferences/org.theObfuscated.googlePasswordSync GAPPS_GLOBAL_SYNC_FILE`

        DEBUG_MSG "GAPPS_GLOBAL_SYNC_FILE: $gapsSyncFile" $FUNCNAME $LINENO
    else
        local gapsSyncFile=""
    fi

    if [ -n "$launchDaemon" ]
    then
        DEBUG_MSG "UNLOADING launchd: $launchDaemon" $FUNCNAME $LINENO

        printf "   --> UNLOADING UPDATE LAUNCH DAEMON\n"
        launchctl unload /Library/LaunchDaemons/org.theObfuscated.googlePasswordSync.plist
        
    fi 

    if [ -f $gapsSyncFile.plist ]
    then
        DEBUG_MSG "UNLOADING launchd: $gapsSyncFile.plist" $FUNCNAME $LINENO

        printf "   --> UNLOADING SYNC LAUNCH DAEMON\n"
        launchctl unload $gapsSyncFile.plist
    fi

    printf "   --> DISSABLING PASSWORD CHANGE CAPTURE\n"
    #INFORM THE APPLE PASSWORD SERVER TO NOT RUN THE SCRIPT ON PASSWORD CHANGE
    defaults write /Library/Preferences/com.apple.passwordserver ExternalCommand Disabled

    local checkDisabled=`defaults read /Library/Preferences/com.apple.passwordserver ExternalCommand`

    if [ "$checkDisabled" == "Disabled" ]
    then
        DEBUG_MSG "Sucessfully disabled update sync daemon" $FUNCNAME $LINENO
        printf "   --> SERVICES STOPPED\n"
        plutil -convert xml1 /Library/Preferences/com.apple.passwordserver.plist
        return 0
    else
        DEBUG_MSG "Update sync daemon still loaded: $checkDisabled" $FUNCNAME $LINENO
    fi

    plutil -convert xml1 /Library/Preferences/com.apple.passwordserver.plist

    return 1
}

#CHECK THE COMPATABILITY
function preInstall()
{

    DEBUG_MSG "PRE-INSTALL MESSAGE." $FUNCNAME $LINENO

}








###############################
##### START THE INSTALLER #####
###############################

# THIS DOES ALL OF THE PRECHECKING AND GATHERS ALL THE SETUP INFO NEEDED BY THE INSTALLER TO PROCEED

#DISPLAY THE INTRO MESSAGE
welcomeMessage

#MAKE SURE THEY WANT TO CONTINUE
continueInstall

DEBUG_MSG "CONTINUE THE INSTALL" $0 $LINENO

getOSInformation

DEBUG_MSG "OSX_NAME: $OSX_NAME" $0 $LINENO
DEBUG_MSG "OSX_VERSION: $OSX_VERSION" $0 $LINENO
DEBUG_MSG "OSX_MAJOR: $OSX_MAJOR" $0 $LINENO
DEBUG_MSG "OSX_BUILD: $OSX_BUILD" $0 $LINENO

getOpenDirectoryMasterFQDN

DEBUG_MSG "ODM FQDN: $OPENDIRECTORY_MASTER_FQDN" $0 $LINENO

if [ $STOP == 0 ]
then
    DEBUG_MSG "STOP CONDITION TRIGGERED, EXITING INSTALLER" $0 $LINENO
    exit 1
fi

getIPAddressFromFQDN $OPENDIRECTORY_MASTER_FQDN

DEBUG_MSG "ODM IP: $OPENDIRECTORY_MASTER_IPADDRESS" $0 $LINENO

if [ $STOP == 0 ]
then
DEBUG_MSG "STOP CONDITION TRIGGERED, EXITING INSTALLER." $0 $LINENO
exit 1
fi

checkNetworkConnection $OPENDIRECTORY_MASTER_FQDN

if [ $STOP == 0 ]
then
    DEBUG_MSG "STOP CONDITION TRIGGERED, EXITING INSTALLER" $0 $LINENO
    exit 1
fi


guessLDAPSearchBase $OPENDIRECTORY_MASTER_FQDN
DEBUG_MSG "LDAP SEARCH BASE GUESS: $OPENDIRECTORY_LDAP_SEARCH_BASE" $0 $LINENO


if [ $STOP == 0 ]
then
    DEBUG_MSG "STOP CONDITION TRIGGERED, EXITING INSTALLER." $0 $LINENO
    exit 1
fi

checkLDAPSearchBase $OPENDIRECTORY_MASTER_FQDN $OPENDIRECTORY_LDAP_SEARCH_BASE

#MAKE SURE YOU CAN CONNECTO TO THE LDAP SERVER
if [ $? == 2 ]
then
    printf "Cannot Connect to ldap://%s\n" "$OPENDIRECTORY_MASTER_FQDN"
    while [ $? != 2 ]
    do
        getOpenDirectoryMasterFQDN
        getLDAPSearchBase
        checkLDAPSearchBase $OPENDIRECTORY_MASTER_FQDN $OPENDIRECTORY_LDAP_SEARCH_BASE
    done
fi

if [ $STOP == 0 ]
then
    DEBUG_MSG "STOP CONDITION TRIGGERED, EXITING INSTALLER." $0 $LINENO
    exit 1
fi

#MAKE SURE YOU HAVE THE CORRECT SEARCH BASE
if [ $? == 1 ]
then
    printf "It seems that the LDAP search base cannot be automatically generated.\n"
    while [ !$? ]
    do
        printf "It seems that the LDAP search base you entered was NOT valid.\n"
        getLDAPSearchBase
        checkLDAPSearchBase $OPENDIRECTORY_MASTER_FQDN $OPENDIRECTORY_LDAP_SEARCH_BASE
        
    done
fi

preCheckMessage

if [ $STOP == 0 ]
then
    DEBUG_MSG "STOP CONDITION TRIGGERED, EXITING INSTALLER." $0 $LINENO
    exit 1
fi
    
checkConnectionToGoogle

if [ $STOP == 0 ]
then
    DEBUG_MSG "STOP CONDITION TRIGGERED, EXITING INSTALLER." $0 $LINENO
    exit 1
fi

checkForZendGdataLibrary

#SET GLOBAL FLAG TO DETERMINE IF WE NEED TO INSTALL ZEND
if [ $? == 1 ]
then
    ZEND_GDATA="NO"
else
    ZEND_GDATA="YES"
fi

checkForPreviousInstallation
if [ $? == 1 ]
then
    PREVIOUS_VERSION="NO"
else
    PREVIOUS_VERSION="YES"
fi



continueInstall
exit 0















########################
########################
#START THE ACTUAL SETUP#
########################
########################

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
    
    ### GADS COMPATIBILITY MODE ###
    read -p "googlePasswordSync is now compatablie with GADS, do you want to enable this compatability? [y/N]: " enableGads
    if [ -z "$enableGads" ]
    then
        enableGads="NO"
    else
        if [ "$enableGads" == "y" -o "$enableGads" == "Y" -o "$enableGads" == "yes" -o "$enableGads" == "YES" ]
        then
            printf "\n"
            enableGads="YES"
            read -p "Enter in a OpenDirectory admin account short name, this will be used to modify user records: " odAdmin
            if [ -z "$odAdmin" ]
            then
                printf "Since no Open Directory admin account was given we are disabling GADS compatability mode\n"
                enableGads="NO"
            else
                printf "\n"
                read -s -p "Enter in the password for $odAdmin: " odAdminPassword
                if [ -z "$odAdminPassword" ]
                then
                    printf "Empty Administrator passwords are not allowed, disabling GADS compatability mode\n"
                    enableGads="NO"
                else
                    printf "\n"
                    read -p "What is the ldap attribute name you wish to use to store the information in? [pager]: " odRecordName
                    if [ -z "$odRecordName" ]
                    then
                        odRecordName="pager"
                    fi
                fi
            fi
        else
            enableGads="NO"
        fi
    fi
    # END GADS #

    printf "\n"

    read -p "How often (in seconds) should the googlePasswordSync check for updated/changed passwords updates to your Google Apps Domain? [90]: " syncInterval
    if [ -z "$syncInterval" ]
    then
        syncInterval=90
    fi

    printf "\n"

    if [ "$enableGads" == "NO" ]
    then
        read -p "Do you want googlePasswordSync to sync all accounts to Google APPS that is has registered, even though their was no password change? [Y/n]: " tmp
        if [ -z "$tmp" ]
        then
            tmp="Y"
        fi
    else
        read -p "Do you want googlePasswordSync to sync all accounts to Google APPS that is has registered, even though their was no password change (since you are using GADS this option is NOT recommended )? [y/N]: " tmp
        if [ -z "$tmp" ]
        then
            tmp="N"
        fi
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

    
    #GADS#
    if [ "$enableGads" == "YES" ]
    then
        encryptedOdAdminPassword="`/usr/sbin/admin/tools/googlePasswordSync/crypto.sh --encode $dbDirectory/keys/public/$adminPublicKeyFileName.pem $odAdminPassword`"
        defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GADS_PASSWORD "$encryptedOdAdminPassword"
        defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GADS_USER $odAdmin
        defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GADS_RECORD_NAME $odRecordName
        printf " --> SAVED GADS INFORMATION\n"
    fi
    #END GADS#


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
    printf " --> SAVED GAPPS_SYNC_INTERVAL\n"
    defaults write /Library/Preferences/org.theObfuscated.googlePasswordSync GADS_ENABLED -bool $enableGads
    printf " --> SAVED GADS_ENABLED\n"
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
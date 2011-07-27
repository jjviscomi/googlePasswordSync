#!/bin/sh

####################################################################################################
# File Name: ldapinfo.sh                                                                           #
#                                                                                                  #
# Created by Joseph J Viscomi on 7/8/11.                                                           #
# E-Mail: jjviscomi@gmail.com Facebook: (http://www.facebook.com/joe.viscomi)                      #
# Website: http://www.theObfuscated.org                                                            #
# Date Last Modified: 7/27/2011.                                                                   #
# Version: 0.7b                                                                                    #
#                                                                                                  #
# Description: This is a admin tool script used to OD for user information                         #
#              that is distributed with org.theObfuscated.googlePasswordSync package.              #
#                                                                                                  #
# Location:                                                                                        #
# /usr/sbin/admin/tools/googlePasswordSync/                                                        #
# ldapinfo.sh <fqdn odm> <search path> --uid <uid> [firstname | lastname | email | status]         #
#                                                                                                  #
# Arguments:                                                                                       #
#                                                                                                  #
# This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. #
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send a   #
# letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA. #
####################################################################################################

#LIST ALL USERS: base dn | grep cn= | grep uid=

#CHECK FOR FQDN OF OPEN DIRECTORY MASTER
if [ -n "$1" ]
then
    #ATTEMPT TO ESTABLISH CONTACT TO SERVER
    packetCount=`ping -c4 $1 | grep "4 packets transmitted," | awk '{ print $4}'`
    if [ $packetCount -gt 0 ]
    then
        if [ -n "$2" ]
        then
            ldapconnect=`ldapsearch -xLLL -H ldap://$1 -b $2 | grep "No such object (32)"`
            if [ -n "$ldapconnect" ]
            then
                printf "%s (%s) Bad ldap search query.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" >> /var/log/system.log
                exit 1
            fi
        else
            printf "%s (%s) Missing ldap search path.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" >> /var/log/system.log
            exit 1
        fi
    else
        printf "%s (%s) Cannot connect to ldap server.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" >> /var/log/system.log
        exit 1
    fi

    #IF WE GET HERE THEN WE HAVE GOOD CONNECTION TO LDAP AND CORRECT BASE SEARCH PATH

    if [ "$3" == "--uid" ]
    then
        if [ -z "$4" ]
        then
            printf "%s (%s) missing uid.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" >> /var/log/system.log
            exit 1
        fi
        
        case "$5" in
        'firstname')
        ldapinfo=`ldapsearch -xLLL -H ldap://$1 -b $2 uid=$4 givenName | grep givenName | awk '{ print $2 }'`
        ;;
        'lastname')
        ldapinfo=`ldapsearch -xLLL -H ldap://$1 -b $2 uid=$4 sn | grep sn | awk '{ print $2 }'`
        ;;
        'email')
        ldapinfo=`ldapsearch -xLLL -H ldap://$1 -b $2 uid=$4 mail | grep mail | awk '{ print $2 }'`
        ;;
        'status')
        ldapinfo=`ldapsearch -xLLL -H ldap://$1 -b $2 uid=$4`
        if [ -z "$ldapinfo" ]
        then    
            printf "%s (%s) User account (%s) not found.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" "$4">> /var/log/system.log
            exit 1
        fi
        ldapinfo=`pwpolicy -u $4 -getpolicy | grep isDisabled=1`
        if [ -z "$ldapinfo" ]
        then
            ldapinfo="Enabled"
        else
            ldapinfo="Disabled"
        fi
        ;;
        esac
        
        printf "%s" "$ldapinfo"
        exit 0
    fi

    printf "%s (%s) missing --uid flag.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" >> /var/log/system.log
    exit 1
fi

printf "%s (%s) Incorrect Usage.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" >> /var/log/system.log
exit 1

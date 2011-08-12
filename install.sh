#!/bin/sh

####################################################################################################
# File Name: install.sh                                                                            #
#                                                                                                  #
# Created by Joseph J Viscomi on 08/11/11.                                                         #
# E-Mail: jjviscomi@gmail.com Facebook: (http://www.facebook.com/joe.viscomi)                      #
# Website: http://www.theObfuscated.org                                                            #
# Date Last Modified: 08/11/11.                                                                    #
# Version: 0.8                                                                                     #
#                                                                                                  #
# Description: This is the installer for googlePasswordSync.                                       #
#                                                                                                  #
# Instructions: You must run this file as root: sudo ./install.sh                                  #
#                                                                                                  #
# Arguments: 1 OPTIONS [--check | --install | --upgrade]                                           #
#                                                                                                  #
# This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. #
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send a   #
# letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA. #
####################################################################################################

installLocation="${0%install.sh}"

if [ -d $installLocation/setup ]
then
    cd $installLocation/setup
    if [ -f ./install.sh ]
    then
        ./install.sh $1
    else
        printf "Unable to locate package installer.\n"
        exit 1
    fi
else
    printf "Unable to locate setup directory.\n"
    exit 1
fi

exit 0
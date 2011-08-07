#!/bin/sh

####################################################################################################
# File Name: crypto.sh                                                                             #
#                                                                                                  #
# Created by Joseph J Viscomi on 7/8/11.                                                           #
# E-Mail: jjviscomi@gmail.com Facebook: (http://www.facebook.com/joe.viscomi)                      #
# Website: http://www.theObfuscated.org                                                            #
# Date Last Modified: 7/27/2011.                                                                   #
# Version: 0.7b                                                                                    #
#                                                                                                  #
# Description: This is a admin tool script used to encrypt and decrypt messages with RSA KEYS      #
#              that is distributed with org.theObfuscated.googlePasswordSync package.              #
#              when decoding it expects a base64 encoder cipher text.                              #
#                                                                                                  #
# Instructions:                                                                                    #
# Location: /usr/sbin/admin/tools/googlePasswordSync/                                              #
#                                                                                                  #
# The first arguments specifies what operation to preform on the message. The second argument is   #
# the actual public or private key file (.pem) to use in the operation, and last is the message to #
# preform the operation on. However if the --file flag is present just before the messsage then it #
# refers to the message within the given file. If you are decoding the message is expected to be   #
# in base64 format. The script sends the results to stdout.                                        #
#                                                                                                  #
# This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. #
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send a   #
# letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA. #
####################################################################################################


########## ENCODING ###########

#ENCODE THE CONTENTS OF A FILE
if [ "$1" == "--encode" -a "$3" == "--file" ]
then
    #BOTH THE MESSAGE FILE AND THE PUBLIC KEY FILE SHOULD EXIST
    if [ -f $4 -a -f $2 ]
    then
        #ENCODE THE CONTENTS OF THE FILE
        b64CipherText=`cat "$4" | openssl rsautl -encrypt -inkey $2 -pubin | openssl base64`
        printf "%s" "$b64CipherText"
        exit 0
    else
        printf "%s (%s) Specified key file (%s) or message file (%s) not found for the encoding process.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" "$2" "4" >> /var/log/system.log
        exit 1
    fi
fi

#ENCODE THE CONTENTS OF THE STRING ARGUMENT
if [ "$1" == "--encode" ]
then
    #KEY FILE NEEDS TO EXIST
    if [ -f $2 ]
    then
        #ENCODE THE TEXT ARGUMENT
        b64CipherText=`echo "$3" | openssl rsautl -encrypt -inkey $2 -pubin | openssl base64`
        printf "%s" "$b64CipherText"
        exit 0
    else
        printf "%s (%s) Specified key file (%s) not found for the encoding process.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" "$2" >> /var/log/system.log
        exit 1
    fi
fi



########### DECODING #############
if [ "$1" == "--decode" -a "$3" == "--file" ]
then
    #BOTH THE MESSAGE FILE AND THE PRIVATE KEY FILE SHOULD EXIST
    if [ -f $4 -a -f $2 ]
    then
        #DECODE THE CONTENTS OF THE FILE
        plainText=`cat "$4" | openssl enc -a -d | openssl rsautl -decrypt -inkey $2`
        printf "%s" "$plainText"
        exit 0
    else
        printf "%s (%s) Specified key file (%s) or message file (%s) not found for the decoding process.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" "$2" "4" >> /var/log/system.log
        exit 1
    fi
fi

if [ "$1" == "--decode" ]
then
    #THE PRIVATE KEY FILE SHOULD EXIST
    if [ -f $2 ]
    then
        #DECODE THE TEXT ARGUMENT
        plainText=`echo "$3" | openssl enc -a -d | openssl rsautl -decrypt -inkey $2`
        printf "%s" "$plainText"
        exit 0
    else
        printf "%s (%s) Specified key file (%s) not found for the decoding process.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" "$2" >> /var/log/system.log
        exit 1
    fi
fi

if [ "$1" == "--hash" ]
then
    #HASH TYPE
    if [ "$2" == "--sha" -a "$3" == "--file" ]
    then
        if [ -f $4 ]
        then
            #HASH THE CONTENTS OF THE FILE
            hash=`echo "$4" | /usr/bin/openssl dgst -sha1 -hex`
            printf "%s" "$hash"
            exit 0
        else
            printf "%s (%s) Specified file (%s) not found for the hashing process.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" "$4" >> /var/log/system.log
            exit 1
        fi
    fi

    if [ "$2" == "--sha" ]
    then
        #HASH THE STRING PROVIDED
        hash=`echo "$3" | /usr/bin/openssl dgst -sha1 -hex`
        printf "%s" "$hash"
        exit 0
    fi

    printf "%s (%s) Specified invalid hash type (%s) for the hashing process.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" "$2" >> /var/log/system.log
    exit 1
    
fi


########### GENERATE KEYS #############
if [ "$1" == "--gen" ]
then
    if [ $2 == 1024 -o $2 == 2048 -o $2 == 4096 ]
    then
    
        #GENERATE PRIVATE KEY
        openssl genrsa -out $3 $2
    
        #GENERATE PUBLIC KEY
        openssl rsa -in $3 -out $4 -outform PEM -pubout

        exit 0
    else
        printf "%s (%s) Incorrect key length specified.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" "$2" >> /var/log/system.log
        exit 1
    fi
fi

########### END OF ARGUMENTS ############

printf "Bad command syntax.\n\n"
printf "EXAMPLES (ENCODING):\n"
printf "\t crypto.sh --encode <path to public key file> --file <path to plain text file>\n"
printf "\t crypto.sh --encode <path to public key file> \"Text to have encoded\"\n\n"
printf "EXAMPLES (DECODING):\n"
printf "\t crypto.sh --decode <path to private key file> --file <path to cipher text file>\n"
printf "\t crypto.sh --decode <path to private key file> \"Cipher text to have decoded\"\n\n"
printf "EXAMPLE (GENERATING KEY PAIRS):\n"
printf "\t crypto.sh --gen [1024 | 2048 | 4096] <path to private key file> <path to public key file>\n"
printf "HASHING (SHA1):\n"
printf "\t crypto.sh --hash --sha \"TEXT TO HASH\"\n"
printf "\t crypto.sh --hash --sha --file <path to file contents to hash>\n\n"


printf "%s (%s) Unknown arguments [ %s %s %s %s ] passed to this script.\n" "`date +%Y:%m:%d:%H:%M:%S`" "$0" "$1" "$2" "$3" "$4" >> /var/log/system.log
exit 1

<?php
/**
 * Zend Framework
 *
 * LICENSE
 *
 * This source file is subject to the new BSD license that is bundled
 * with this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://framework.zend.com/license/new-bsd
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@zend.com so we can send you a copy immediately.
 *
 * @category   Zend
 * @package    Zend_Gdata
 * @subpackage Demos
 * @copyright  Copyright (c) 2005-2011 Zend Technologies USA Inc. (http://www.zend.com)
 * @license    http://framework.zend.com/license/new-bsd     New BSD License
 */

/**
 * PHP sample code for the Google Calendar data API.  Utilizes the
 * Zend Framework Gdata components to communicate with the Google API.
 *
 * Requires the Zend Framework Gdata components and PHP >= 5.1.4
 *
 * You can run this sample both from the command line (CLI) and also
 * from a web browser.  Run this script without any command line options to
 * see usage, eg:
 *     /usr/bin/env php Gapps.php
 *
 * More information on the Command Line Interface is available at:
 *     http://www.php.net/features.commandline
 *
 * When running this code from a web browser, be sure to fill in your
 * Google Apps credentials below and choose a password for authentication
 * via the web browser.
 *
 * Since this is a demo, only minimal error handling and input validation
 * are performed. THIS CODE IS FOR DEMONSTRATION PURPOSES ONLY. NOT TO BE
 * USED IN A PRODUCTION ENVIRONMENT.
 *
 * NOTE: You must ensure that Zend Framework is in your PHP include
 * path.  You can do this via php.ini settings, or by modifying the
 * argument to set_include_path in the code below.
 */



/**
 * @see Zend_Loader
 */
require_once 'Zend/Loader.php';

/**
 * @see Zend_Gdata
 */
Zend_Loader::loadClass('Zend_Gdata');

/**
 * @see Zend_Gdata_ClientLogin
 */
Zend_Loader::loadClass('Zend_Gdata_ClientLogin');

/**
 * @see Zend_Gdata_Gapps
 */
Zend_Loader::loadClass('Zend_Gdata_Gapps');

/**
 * Returns a HTTP client object with the appropriate headers for communicating
 * with Google using the ClientLogin credentials supplied.
 *
 * @param  string $user The username, in e-mail address format, to authenticate
 * @param  string $pass The password for the user specified
 * @return Zend_Http_Client
 */
function getClientLoginHttpClient($user, $pass) {
  $service = Zend_Gdata_Gapps::AUTH_SERVICE_NAME;
  $client = Zend_Gdata_ClientLogin::getHttpClient($user, $pass, $service);
  return $client;
}

/**
 * Creates a new user for the current domain. The user will be created
 * without admin privileges.
 *
 * @param  Zend_Gdata_Gapps $gapps      The service object to use for communicating with the Google
 *                                      Apps server.
 * @param  boolean          $html       True if output should be formatted for display in a web browser.
 * @param  string           $username   The desired username for the user.
 * @param  string           $givenName  The given name for the user.
 * @param  string           $familyName The family name for the user.
 * @param  string           $password   The plaintext password for the user.
 * @return void
 */
function createUser($gapps, $html, $username, $givenName, $familyName, $password) {
    $gapps->createUser($username, $givenName, $familyName, $password);
}

/**
 * Retrieves a user for the current domain by username. Information about
 * that user is then output.
 *
 * @param  Zend_Gdata_Gapps $gapps    The service object to use for communicating with the Google Apps server.
 * @param  boolean          $html     True if output should be formatted for display in a web browser.
 * @param  string           $username The desired username for the user.
 * @return void
 */
function retrieveUser($gapps, $html, $username) {

    $user = $gapps->retrieveUser($username);

    if ($user !== null) {
        echo '             Username: ' . $user->login->username;
        echo "\n";

        echo '           Given Name: ';
        
        echo $user->name->givenName;
        
        
        echo "\n";

        echo '          Family Name: ';
        
        echo $user->name->familyName;
        
        echo "\n";

        echo '            Suspended: ' . ($user->login->suspended ? 'Yes' : 'No');

        echo "\n";

        echo '                Admin: ' . ($user->login->admin ? 'Yes' : 'No');
       
        echo "\n";

        echo ' Must Change Password: ' .
            ($user->login->changePasswordAtNextLogin ? 'Yes' : 'No');
        
        echo "\n";

        echo '  Has Agreed To Terms: ' .
            ($user->login->agreedToTerms ? 'Yes' : 'No');

    } else {
        echo 'Error: Specified user not found.';
    }
    
    echo "\n";
}

/**
 * Retrieves the list of users for the current domain and outputs
 * that list.
 *
 * @param  Zend_Gdata_Gapps $gapps The service object to use for communicating with the Google Apps server.
 * @param  boolean          $html  True if output should be formatted for display in a web browser.
 * @return void
 */
function retrieveAllUsers($gapps, $html) {

    $feed = $gapps->retrieveAllUsers();


    foreach ($feed as $user) {
        
        echo "  * ";
        
        echo $user->login->username . ' (';
        
        echo $user->name->givenName . ' ' . $user->name->familyName;
        
        echo ')';
        
        echo "\n";
    }
    
}

/**
 * Change the name for an existing user.
 *
 * @param  Zend_Gdata_Gapps $gapps         The service object to use for communicating with the Google
 *                                         Apps server.
 * @param  boolean          $html          True if output should be formatted for display in a web browser.
 * @param  string           $username      The username which should be updated
 * @param  string           $newGivenName  The new given name for the user.
 * @param  string           $newFamilyName The new family name for the user.
 * @return void
 */
function updateUserName($gapps, $html, $username, $newGivenName, $newFamilyName) {

    $user = $gapps->retrieveUser($username);

    if ($user !== null) {
        $user->name->givenName = $newGivenName;
        $user->name->familyName = $newFamilyName;
        $user->save();
    } else {
        echo 'Error: Specified user not found.';
        echo "\n";
    }

}

/**
 * Change the password for an existing user.
 *
 * @param  Zend_Gdata_Gapps $gapps       The service object to use for communicating with the Google
 *                                       Apps server.
 * @param  boolean          $html        True if output should be formatted for display in a web browser.
 * @param  string           $username    The username which should be updated
 * @param  string           $newPassword The new password for the user.
 * @return void
 */
function updateUserPassword($gapps, $html, $username, $newPassword) {


    $user = $gapps->retrieveUser($username);

    if ($user !== null) {
        $user->login->password = $newPassword;
        $user->save();
    } else {
        
        echo 'Error: Specified user not found.';
       
        echo "\n";
    }

}

/**
 * Suspend a given user. The user will not be able to login until restored.
 *
 * @param  Zend_Gdata_Gapps $gapps    The service object to use for communicating with the Google
 *                                    Apps server.
 * @param  boolean          $html     True if output should be formatted for display in a web browser.
 * @param  string           $username The username which should be updated.
 * @return void
 */
function suspendUser($gapps, $html, $username) {

    $user = $gapps->retrieveUser($username);

    if ($user !== null) {
        $user->login->suspended = true;
        $user->save();
    } else {
        
        echo 'Error: Specified user not found.';

        echo "\n";
    }

}

/**
 * Restore a given user after being suspended.
 *
 * @param  Zend_Gdata_Gapps $gapps    The service object to use for communicating with the Google
 *                                    Apps server.
 * @param  boolean          $html     True if output should be formatted for display in a web browser.
 * @param  string           $username The username which should be updated.
 * @return void
 */
function restoreUser($gapps, $html, $username) {

    $user = $gapps->retrieveUser($username);

    if ($user !== null) {
        $user->login->suspended = false;
        $user->save();
    } else {
        
        echo 'Error: Specified user not found.';
       
        echo "\n";
    }

}

/**
 * Give a user admin rights.
 *
 * @param  Zend_Gdata_Gapps $gapps    The service object to use for communicating with the Google
 *                                    Apps server.
 * @param  boolean          $html     True if output should be formatted for display in a web browser.
 * @param  string           $username The username which should be updated.
 * @return void
 */
function giveUserAdminRights($gapps, $html, $username) {

    $user = $gapps->retrieveUser($username);

    if ($user !== null) {
        $user->login->admin = true;
        $user->save();
    } else {
        
        echo 'Error: Specified user not found.';
     
        echo "\n";
    }

}

/**
 * Revoke a user's admin rights.
 *
 * @param  Zend_Gdata_Gapps $gapps    The service object to use for communicating with the Google
 *                                    Apps server.
 * @param  boolean          $html     True if output should be formatted for display in a web browser.
 * @param  string           $username The username which should be updated.
 * @return void
 */
function revokeUserAdminRights($gapps, $html, $username) {
    

    $user = $gapps->retrieveUser($username);

    if ($user !== null) {
        $user->login->admin = false;
        $user->save();
    } else {
       
        echo 'Error: Specified user not found.';

        echo "\n";
    }

}

/**
 * Force a user to change their password at next login.
 *
 * @param  Zend_Gdata_Gapps $gapps    The service object to use for communicating with the Google
 *                                    Apps server.
 * @param  boolean          $html     True if output should be formatted for display in a web browser.
 * @param  string           $username The username which should be updated.
 * @return void
 */
function setUserMustChangePassword($gapps, $html, $username) {

    $user = $gapps->retrieveUser($username);

    if ($user !== null) {
        $user->login->changePasswordAtNextLogin = true;
        $user->save();
    } else {
       
        echo 'Error: Specified user not found.';
       
        echo "\n";
    }
}

/**
 * Undo forcing a user to change their password at next login.
 *
 * @param  Zend_Gdata_Gapps $gapps    The service object to use for communicating with the Google
 *                                    Apps server.
 * @param  boolean          $html     True if output should be formatted for display in a web browser.
 * @param  string           $username The username which should be updated.
 * @return void
 */
function clearUserMustChangePassword($gapps, $html, $username) {

    $user = $gapps->retrieveUser($username);

    if ($user !== null) {
        $user->login->changePasswordAtNextLogin = false;
        $user->save();
    } else {
        echo 'Error: Specified user not found.';
   
        echo "\n";
    }

}

/**
 * Delete the user who owns a given username.
 *
 * @param  Zend_Gdata_Gapps $gapps    The service object to use for communicating with the Google
 *                                    Apps server.
 * @param  boolean          $html     True if output should be formatted for display in a web browser.
 * @param  string           $username The username which should be deleted.
 * @return void
 */
function deleteUser($gapps, $html, $username) {
    

    $gapps->deleteUser($username);

}

/**
 * Create a new nickname.
 *
 * @param  Zend_Gdata_Gapps $gapps    The service object to use for communicating with the Google
 *                                    Apps server.
 * @param  boolean          $html     True if output should be formatted for display in a web browser.
 * @param  string           $username The username to which the nickname should be assigned.
 * @param  string           $nickname The name of the nickname to be created.
 * @return void
 */
function createNickname($gapps, $html, $username, $nickname) {
    $gapps->createNickname($username, $nickname);


}

/**
 * Retrieve a specified nickname and output its ownership information.
 *
 * @param  Zend_Gdata_Gapps $gapps    The service object to use for communicating with the Google
 *                                    Apps server.
 * @param  boolean          $html     True if output should be formatted for display in a web browser.
 * @param  string           $nickname The name of the nickname to be retrieved.
 * @return void
 */
function retrieveNickname($gapps, $html, $nickname) {
   
    $nickname = $gapps->retrieveNickname($nickname);


    if ($nickname !== null) {
        echo ' Nickname: ' . $nickname->nickname->name;
        echo "\n";

        echo '    Owner: ' . $nickname->login->username;
    } else {
        echo 'Error: Specified nickname not found.';
    }
    
    echo "\n";
}

/**
 * Outputs all nicknames owned by a specific username.
 *
 * @param  Zend_Gdata_Gapps $gapps    The service object to use for communicating with the Google
 *                                    Apps server.
 * @param  boolean          $html     True if output should be formatted for display in a web browser.
 * @param  string           $username The username whose nicknames should be displayed.
 * @return void
 */
function retrieveNicknames($gapps, $html, $username) {
   

    $feed = $gapps->retrieveNicknames($username);



    foreach ($feed as $nickname) {
        
        echo "  * ";
        
        echo $nickname->nickname->name;
        
        echo "\n";
    }
   
}


/**
 * Retrieves the list of nicknames for the current domain and outputs
 * that list.
 *
 * @param  Zend_Gdata_Gapps $gapps The service object to use for communicating with the Google
 *                                 Apps server.
 * @param  boolean          $html  True if output should be formatted for display in a web browser.
 * @return void
 */
function retrieveAllNicknames($gapps, $html) {
    
    $feed = $gapps->retrieveAllNicknames();

   

    foreach ($feed as $nickname) {
       
        echo "  * ";
        
        echo $nickname->nickname->name . ' => ' . $nickname->login->username;
        
        echo "\n";
    }

}

/**
 * Delete's a specific nickname from the current domain.
 *
 * @param  Zend_Gdata_Gapps $gapps    The service object to use for communicating with the Google
 *                                    Apps server.
 * @param  boolean          $html     True if output should be formatted for display in a web browser.
 * @param  string           $nickname The nickname that should be deleted.
 * @return void
 */
function deleteNickname($gapps, $html, $nickname) {
    
    $gapps->deleteNickname($nickname);

}

/**
 * Create a new email list.
 *
 * @param  Zend_Gdata_Gapps $gapps     The service object to use for communicating with the Google
 *                                     Apps server.
 * @param  boolean          $html      True if output should be formatted for display in a web browser.
 * @param  string           $emailList The name of the email list to be created.
 * @return void
 */
function createEmailList($gapps, $html, $emailList) {

    $gapps->createEmailList($emailList);
}

/**
 * Outputs the list of email lists to which the specified address is
 * subscribed.
 *
 * @param  Zend_Gdata_Gapps $gapps     The service object to use for communicating with the Google
 *                                     Apps server.
 * @param  boolean          $html      True if output should be formatted for display in a web browser.
 * @param  string           $recipient The email address of the recipient whose subscriptions should
 *                                     be retrieved. Only a username is required if the recipient is a
 *                                     member of the current domain.
 * @return void
 */
function retrieveEmailLists($gapps, $html, $recipient) {
   

    $feed = $gapps->retrieveEmailLists($recipient);

    foreach ($feed as $list) {
       
        echo "  * ";
        
        echo $list->emailList->name;
        
        echo "\n";
    }

}

/**
 * Outputs the list of all email lists on the current domain.
 *
 * @param  Zend_Gdata_Gapps $gapps The service object to use for communicating with the Google
 *                                 Apps server.
 * @param  boolean          $html  True if output should be formatted for display in a web browser.
 * @return void
 */
function retrieveAllEmailLists($gapps, $html) {

    $feed = $gapps->retrieveAllEmailLists();


    foreach ($feed as $list) {
        
        echo "  * ";
        
        echo $list->emailList->name;
       
        echo "\n";
    }
    
}

/**
 * Delete's a specific email list from the current domain.
 *
 * @param  Zend_Gdata_Gapps $gapps     The service object to use for communicating with the Google
 *                                     Apps server.
 * @param  boolean          $html      True if output should be formatted for display in a web browser.
 * @param  string           $emailList The email list that should be deleted.
 * @return void
 */
function deleteEmailList($gapps, $html, $emailList) {
    
    $gapps->deleteEmailList($emailList);

}

/**
 * Add a recipient to an existing email list.
 *
 * @param  Zend_Gdata_Gapps $gapps            The service object to use for communicating with the
 *                                            Google Apps server.
 * @param  boolean          $html             True if output should be formatted for display in a
 *                                            web browser.
 * @param  string           $recipientAddress The address of the recipient who should be added.
 * @param  string           $emailList        The name of the email address the recipient be added to.
 * @return void
 */
function addRecipientToEmailList($gapps, $html, $recipientAddress, $emailList) {

    $gapps->addRecipientToEmailList($recipientAddress, $emailList);

}

/**
 * Outputs the list of all recipients for a given email list.
 *
 * @param  Zend_Gdata_Gapps $gapps     The service object to use for communicating with the Google
 *                                     Apps server.
 * @param  boolean          $html      True if output should be formatted for display in a web browser.
 * @param  string           $emailList The email list whose recipients should be output.
 * @return void
 */
function retrieveAllRecipients($gapps, $html, $emailList) {


    $feed = $gapps->retrieveAllRecipients($emailList);

    foreach ($feed as $recipient) {
        
        echo "  * ";
        
        echo $recipient->who->email;
   
        echo "\n";
    }
}

/**
 * Remove an existing recipient from an email list.
 *
 * @param  Zend_Gdata_Gapps $gapps            The service object to use for communicating with the
 *                                            Google Apps server.
 * @param  boolean          $html             True if output should be formatted for display in a
 *                                            web browser.
 * @param  string           $recipientAddress The address of the recipient who should be removed.
 * @param  string           $emailList        The email list from which the recipient should be removed.
 * @return void
 */
function removeRecipientFromEmailList($gapps, $html, $recipientAddress, $emailList) {
   

    $gapps->removeRecipientFromEmailList($recipientAddress, $emailList);

}

// ************************ BEGIN CLI SPECIFIC CODE ************************

/**
 * Display list of valid commands.
 *
 * @param  string $executable The name of the current script. This is usually available as $argv[0].
 * @return void
 */
function displayHelp($executable)
{
    echo "Usage: php {$executable} <action> [<username>] [<password>] " .
        "[<arg1> <arg2> ...]\n\n";
    echo "Possible action values include:\n" .
        "createUser\n" .
        "retrieveUser\n" .
        "retrieveAllUsers\n" .
        "updateUserName\n" .
        "updateUserPassword\n" .
        "suspendUser\n" .
        "restoreUser\n" .
        "giveUserAdminRights\n" .
        "revokeUserAdminRights\n" .
        "setUserMustChangePassword\n" .
        "clearUserMustChangePassword\n" .
        "deleteUser\n" .
        "createNickname\n" .
        "retrieveNickname\n" .
        "retrieveNicknames\n" .
        "retrieveAllNicknames\n" .
        "deleteNickname\n" .
        "createEmailList\n" .
        "retrieveEmailLists\n" .
        "retrieveAllEmailLists\n" .
        "deleteEmailList\n" .
        "addRecipientToEmailList\n" .
        "retrieveAllRecipients\n" .
        "removeRecipientFromEmailList\n";
}

/**
 * Parse command line arguments and execute appropriate function when
 * running from the command line.
 *
 * If no arguments are provided, usage information will be provided.
 *
 * @param  array   $argv    The array of command line arguments provided by PHP.
 *                 $argv[0] should be the current executable name or '-' if not available.
 * @param  integer $argc    The size of $argv.
 * @return void
 */
function runCLIVersion($argv, $argc)
{
    if (isset($argc) && $argc >= 2) {
        # Prepare a server connection
        if ($argc >= 5) {
            try {
                $client = getClientLoginHttpClient($argv[2] . '@' . $argv[3], $argv[4]);
                $gapps = new Zend_Gdata_Gapps($client, $argv[3]);
            } catch (Zend_Gdata_App_AuthException $e) {
                echo "Error: Unable to authenticate. Please check your credentials.\n";
                exit(1);
            }
        }

        # Dispatch arguments to the desired method
        switch ($argv[1]) {
            case 'createUser':
                if ($argc == 9) {
                    createUser($gapps, false, $argv[5], $argv[6], $argv[7], $argv[8]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<user's username> <given name> <family name> <user's password>\n\n";
                    echo "This creates a new user with the given username.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "jdoe John Doe p4ssw0rd\n";
                }
                break;
            case 'retrieveUser':
                if ($argc == 6) {
                    retrieveUser($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<user's username>\n\n";
                    echo "This retrieves the user with the specified " .
                        "username and displays information about that user.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "jdoe\n";
                }
                break;
            case 'retrieveAllUsers':
                if ($argc == 5) {
                    retrieveAllUsers($gapps, false);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "\n\n";
                    echo "This lists all users on the current domain.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password>\n";
                }
                break;
            case 'updateUserName':
                if ($argc == 8) {
                    updateUserName($gapps, false, $argv[5], $argv[6], $argv[7]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<user's username> <new given name> <new family name>\n\n";
                    echo "Renames an existing user.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "jdoe Jane Doe\n";
                }
                break;
            case 'updateUserPassword':
                if ($argc == 7) {
                    updateUserPassword($gapps, false, $argv[5], $argv[6]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<user's username> <new user password>\n\n";
                    echo "Changes the password for an existing user.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "jdoe password1\n";
                }
                break;
            case 'suspendUser':
                if ($argc == 6) {
                    suspendUser($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<user's username>\n\n";
                    echo "This suspends the given user.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "jdoe\n";
                }
                break;
            case 'restoreUser':
                if ($argc == 6) {
                    restoreUser($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<user's username>\n\n";
                    echo "This restores the given user after being suspended.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "jdoe\n";
                }
                break;
            case 'giveUserAdminRights':
                if ($argc == 6) {
                    giveUserAdminRights($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<user's username>\n\n";
                    echo "Give a user admin rights for this domain.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "jdoe\n";
                }
                break;
            case 'revokeUserAdminRights':
                if ($argc == 6) {
                    revokeUserAdminRights($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<user's username>\n\n";
                    echo "Remove a user's admin rights for this domain.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "jdoe\n";
                }
                break;
            case 'setUserMustChangePassword':
                if ($argc == 6) {
                    setUserMustChangePassword($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<user's username>\n\n";
                    echo "Force a user to change their password at next login.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "jdoe\n";
                }
                break;
            case 'clearUserMustChangePassword':
                if ($argc == 6) {
                    clearUserMustChangePassword($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<user's username>\n\n";
                    echo "Clear the flag indicating that a user must change " .
                        "their password at next login.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "jdoe\n";
                }
                break;
            case 'deleteUser':
                if ($argc == 6) {
                    deleteUser($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<user's username>\n\n";
                    echo "Delete the user who owns a given username.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "jdoe\n";
                }
                break;
            case 'createNickname':
                if ($argc == 7) {
                    createNickname($gapps, false, $argv[5], $argv[6]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<user's username> <nickname>\n\n";
                    echo "Create a new nickname for the specified user.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "jdoe johnny\n";
                }
                break;
            case 'retrieveNickname':
                if ($argc == 6) {
                    retrieveNickname($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<nickname>\n\n";
                    echo "Retrieve a nickname and display its ownership " .
                        "information.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "johnny\n";
                }
                break;
            case 'retrieveNicknames':
                if ($argc == 6) {
                    retrieveNicknames($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<user's username>\n\n";
                    echo "Output all nicknames owned by a specific username.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "jdoe\n";
                }
                break;
            case 'retrieveAllNicknames':
                if ($argc == 5) {
                    retrieveAllNicknames($gapps, false);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "\n\n";
                    echo "Output all registered nicknames on the system.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "\n";
                }
                break;
            case 'deleteNickname':
                if ($argc == 6) {
                    deleteNickname($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<nickname>\n\n";
                    echo "Delete a specific nickname.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "johnny\n";
                }
                break;
            case 'createEmailList':
                if ($argc == 6) {
                    createEmailList($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<email list>\n\n";
                    echo "Create a new email list with the specified name.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "friends\n";
                }
                break;
            case 'retrieveEmailLists':
                if ($argc == 6) {
                    retrieveEmailLists($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<recipient>\n\n";
                    echo "Retrieve all email lists to which the specified " .
                        "address is subscribed.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "johnny@somewhere.com.invalid\n";
                }
                break;
            case 'retrieveAllEmailLists':
                if ($argc == 5) {
                    retrieveAllEmailLists($gapps, false);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "\n\n";
                    echo "Retrieve a list of all email lists on the current " .
                        "domain.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "\n";
                }
                break;
            case 'deleteEmailList':
                if ($argc == 6) {
                    deleteEmailList($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<email list>\n\n";
                    echo "Delete a specified email list.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "friends\n";
                }
                break;
            case 'addRecipientToEmailList':
                if ($argc == 7) {
                    addRecipientToEmailList($gapps, false, $argv[5], $argv[6]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<recipient> <email list>\n\n";
                    echo "Add a recipient to an existing email list.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "johnny@somewhere.com.invalid friends\n";
                }
                break;
            case 'retrieveAllRecipients':
                if ($argc == 6) {
                    retrieveAllRecipients($gapps, false, $argv[5]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<email list>\n\n";
                    echo "Retrieve all recipients for an existing email list.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "friends\n";
                }
                break;
            case 'removeRecipientFromEmailList':
                if ($argc == 7) {
                    removeRecipientFromEmailList($gapps, false, $argv[5], $argv[6]);
                } else {
                    echo "Usage: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "<recipient> <email list>\n\n";
                    echo "Remove an existing recipient from an email list.\n";
                    echo "EXAMPLE: php {$argv[0]} {$argv[1]} <username> <domain> <password> " .
                        "johnny@somewhere.com.invalid friends\n";
                }
                break;
            default:
                // Invalid action entered
                displayHelp($argv[0]);
        // End switch block
        }
    } else {
        // action left unspecified
        displayHelp($argv[0]);
    }
}


runCLIVersion($argv, $argc);


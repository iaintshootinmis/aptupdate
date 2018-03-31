#!/bin/bash

log_file(){
if [ ! -f "/var/log/aptupdate-*.log" ]; then

    echo "Generating Log File"
    touch "/var/log/aptupdate-`date +%Y%M%d%H%m%S`.log"
    logfile="/var/log/aptupdate-*.log"

else
    echo -e "Log file found.\n Archiving old logs"

    if [ ! -f "/var/log/aptupdate.tar*" ]; then
        echo "Generating new log archive."
        touch "/var/log/aptupdate.tar*"
        echo "Moving old logs to aptupdate.tar"
        tar -rf "aptupdate.tar*" "/var/log/aptupdate-*.log"
    else
        echo "This needs to be fixed."
    fi
fi
}

echo -e "\n"
echo -e "\e[1m*~~~~~ Checking for uid of 0 (root). ~~~~*\e[0m"
if [ "$(id -u)" != "0" ]; then
   echo -e "\n"
   echo "This script must be ran as root." 1>&2
   echo -e "Try \e[3msudo aptupdate\e[0m"
   exit 1
fi

apt_update(){
echo -e "\n"
echo -e "\e[1mUpdating apt repo cache.\e[0m" 
apt-get update >/dev/null 2>&1
if [ $? = "100" ]; then
    echo -e "\e[33mError's exist in the repo cache.\e[0mRun apt-get update manually to review."
elif [  $? != "0" ]; then
    echo -e "\e[31mSomething went wrong. Try running apt-get update manually.\e[0m"
    echo "Exiting painfully."
    exit 1
else
    echo -e "\e[32mUpdate Successful\e[0m"
fi

echo -e "\n"
echo -e "\e[1m*~~~~ Listing available upgrades. ~~~~*" 
echo -e "\n"
apt list --upgradeable 
echo -e "\n" 
}

apt_upgrade(){
read -p "Do you want to install all upgrades? [y]es/[n]o/[c]ancel: " upgradevar
case $upgradevar in
"y")
    echo "Starting silent upgrade."
    apt-get -y upgrade 1>>$logfile
    if [ $? != "0" ]; then
        echo "Something went wrong. Try running apt-get upgrade manually."
        exit 1
    else
        echo "Upgrade Successful."
    fi
    ;;
"n")
    echo -e "Exiting script. Please run apt-get \e[3mpackage name\e[0m upgrade for individual or interactive upgrades."
    exit 0
    ;;
"c")
    echo "Script cancelled. No upgrades performed."
    exit 0
    ;;
*)
    echo "That is an invalid choice."
    return 10
    ;;
esac
}

apt_clean(){
    echo -e "\n Starting AutoClean and AutoRemove of Unused Packages and Orphaned dependencies."
    apt-get -y autoclean
    if [ $? = 0 ]; then
        echo -e "\n Autoclean Successful"
    else
        echo -e "Something went wrong. Try running \e[3apt-get autoclean\e[0m manually."
        return 1
    fi

    apt-get -y autoremove
     if [ $? = 0 ]; then
        echo -e "\n Autoremove Successful"
    else
        echo -e "Something went wrong. Try running \e[3apt-get autoclean\e[0m manually."
        return 1
    fi

    echo -e "Do you want to clean the local repo of \e[33ALL\e[0m files? [y]es/[n]o/[c]ancel: "
    read cleanvar
    case $cleanvar in
    "y")
        echo -e "Beginning removal of ALL local repo files.\n See \e[3mman apt-get\e[0m for additional information."
        apt-get -y clean
        return 0
    ;;
    "n")
        echo -e "Exiting script. Run \e[3mapt-get clean \e[0m manually to remove all local repo files."
        return 0
    ;;
    "c")
        echo "Script cancelled. Local repo left intact."
        return 0
     ;;
    *)
         echo "That is an invalid choice."
         return 10
    ;;
    esac
    return 0
}
apt_update
apt_upgrade
if [ $? = "10" ]; then
    apt_upgrade
else
    return 0
fi
apt_clean
if [ $? = "10" ]; then
    apt_clean
else
    return 0
fi

#echo "All actions performed successfully. Log available at: " $logfile

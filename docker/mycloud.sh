#!/bin/bash
#title           :mycloud.sh
#description     :This script will help manage my personal cloud server
#author          :H.R. Shadhin <dev@hrshadhin.me>
#date            :2020-08-14
#version         :0.1
#usage           :bash mycloud.sh
#bash_version    :4.4.20(1)-release
#==============================================================

# Functions
bootup(){
	startdocker
   	startportainer
   	startapps
   	exit 0
}

startdocker(){
	echo "Starting docker...."
}

startportainer(){
	echo "Starting portainer...."
	docker container start portainer
}

startapps(){
	echo "Starting apps...."
	docker container start postgres
	docker container start tt-rss
	docker container start dnote
}

shutdown(){
	stopapps
   	stopportainer
   	stopdocker
   	exit 0
}

stopdocker(){
	echo "Stoping docker...."
}

stopportainer(){
	echo "Stoping portainer...."
	docker container stop portainer
}

stopapps(){
	echo "Stoping apps...."
	docker container stop tt-rss
	docker container stop dnote
	docker container stop postgres
}



# welcome
welcomeText() {
    cat << "EOF"
                      __  ___      ________                __
                     /  |/  /_  __/ ____/ /___  __  ______/ /
                    / /|_/ / / / / /   / / __ \/ / / / __  /
                   / /  / / /_/ / /___/ / /_/ / /_/ / /_/ /
                  /_/  /_/\__, /\____/_/\____/\__,_/\__,_/
                         /____/
EOF
}



showHelp(){
    echo "::: Control all MyCloud specific functions!"
    echo ":::"
    echo "::: Usage: mycloud <command> [option]"
    echo ":::"
    echo "::: Commands:"
    echo ":::  -b,   bootup		Start services"
    echo ":::  -s,   shutdown	Stop services"
    echo ":::  -h,   help		Show this help dialog"
    exit 0
}

# Main
main() {
    # show welcome info
    welcomeText

    if [ $# = 0 ]; then
        showHelp
    fi

    # Handle redirecting to specific functions based on arguments
    case "$1" in
    "-b"   | "bootup"            ) bootup "$@";;
    "-s"   | "shutdown"          ) shutdown;;
    "-h"   | "help"              ) showHelp;;
    *                            ) showHelp;;
    esac

}

# Program start from here
main "$@"

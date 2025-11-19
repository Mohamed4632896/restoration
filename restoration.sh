#!/bin/bash

# ----------[ COLORS ]----------
reset="\e[0m"
colors=("\e[31m" "\e[32m" "\e[33m" "\e[34m" "\e[35m" "\e[36m" "\e[91m" "\e[92m")
rand_color=${colors[$RANDOM % ${#colors[@]}]}

green="\e[32m"
red="\e[31m"
yellow="\e[33m"

# ----------[ BANNER ]----------
banner() {
    clear
    echo -e "${rand_color}"
    echo "██████╗ ███████╗████████╗ ██████╗ ████████╗ ██████╗ ███╗   ██╗"
    echo "██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗╚══██╔══╝██╔═══██╗████╗  ██║"
    echo "██████╔╝█████╗     ██║   ██║   ██║   ██║   ██║   ██║██╔██╗ ██║"
    echo "██╔══██╗██╔══╝     ██║   ██║   ██║   ██║   ██║   ██║██║╚██╗██║"
    echo "██║  ██║███████╗   ██║   ╚██████╔╝   ██║   ╚██████╔╝██║ ╚████║"
    echo "╚═╝  ╚═╝╚══════╝   ╚═╝    ╚═════╝    ╚═╝    ╚═════╝ ╚═╝  ╚═══╝"
    echo -e "${reset}"
    echo -e "${yellow}             ★ RESTORATION TOOL — LOGIN SYSTEM ★${reset}"
    echo
}

# ----------[ MENU ]----------
menu() {
    echo -e "${green}X1 > LOGIN${reset}"
    echo -e "${red}X2 > CREATE ACCOUNT${reset}"
    echo
    read -p "Choose an option: " option
}

# ----------[ LOGIN ]----------
login() {
    echo
    echo "Enter your email address and password as an example:"
    echo "\"xxxxxxxx@gmail.com:**********\""
    echo
    read -p "> " login_input

    # تقسيم الايميل والباسوورد
    email=$(echo "$login_input" | cut -d ":" -f 1)
    password=$(echo "$login_input" | cut -d ":" -f 2)

    if [[ -z "$email" || -z "$password" ]]; then
        echo -e "${red}Invalid format! Use email:password${reset}"
        sleep 2
        return
    fi

    echo -e "${green}Login successful!${reset}"
    echo "Email: $email"
    echo "Password: $password"
    echo
    sleep 2
}

# ----------[ CREATE ACCOUNT ]----------
create_account() {
    echo
    echo "Enter your new email and password as example:"
    echo "\"newemail@gmail.com:myPassword\""
    echo
    read -p "> " reg_input

    email=$(echo "$reg_input" | cut -d ":" -f 1)
    password=$(echo "$reg_input" | cut -d ":" -f 2)

    if [[ -z "$email" || -z "$password" ]]; then
        echo -e "${red}Invalid format! Use email:password${reset}"
        sleep 2
        return
    fi

    echo "$email:$password" >> accounts.txt
    echo
    echo -e "${green}Account created successfully!${reset}"
    sleep 2
}

# ----------[ MAIN ]----------
while true; do
    banner
    menu

    case $option in
        X1|x1) login ;;
        X2|x2) create_account ;;
        *) echo -e "${red}Invalid option!${reset}"; sleep 1 ;;
    esac
done

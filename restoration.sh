#!/bin/bash

# ======================================
# COLOR VARIABLES
# ======================================
green="\e[32m"
red="\e[31m"
yellow="\e[33m"
blue="\e[34m"
reset="\e[0m"

# ======================================
# GITHUB API CONFIG  ⚠️ مهم جداً ⚠️
# ======================================
# ➤ هنا بالضبط غادي تلصق التوكين الجديد
# داخل علامات الاقتباس ""
# وما تشاركوش مع حتى أحد.

GITHUB_TOKEN="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"
REPO_OWNER="Mohamed4632896"
REPO_NAME="restoration-accounts"
FILE_PATH="users.txt"

# ======================================
# FUNCTION: UPLOAD USER DATA TO GITHUB
# ======================================
upload_users() {
    users_data=$(base64 users.txt | tr -d '\n')

    curl -X PUT \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"message\":\"update users\", \"content\":\"$users_data\"}" \
    "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/$FILE_PATH" >/dev/null 2>&1
}

# ======================================
# FUNCTION: DOWNLOAD USER DATA FROM GITHUB
# ======================================
download_users() {
    curl -H "Authorization: Bearer $GITHUB_TOKEN" \
    -s "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/$FILE_PATH" |
    jq -r '.content' | base64 -d > users.txt 2>/dev/null
}

# ======================================
# PRINT LOGO
# ======================================
logo() {
echo -e "${yellow}"
echo "██████╗ ███████╗███████╗████████╗ ██████╗ ██████╗ ██╗ ██████╗ ███╗   ██╗"
echo "██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██║██╔═══██╗████╗  ██║"
echo "██████╔╝█████╗  ███████╗   ██║   ██║   ██║██████╔╝██║██║   ██║██╔██╗ ██║"
echo "██╔══██╗██╔══╝  ╚════██║   ██║   ██║   ██║██╔═══╝ ██║██║   ██║██║╚██╗██║"
echo "██║  ██║███████╗███████║   ██║   ╚██████╔╝██║     ██║╚██████╔╝██║ ╚████║"
echo "╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝"
echo -e "${reset}"
}

# ======================================
# MENU
# ======================================
menu() {
    clear
    logo
    echo -e "${green}X1 > LOGIN${reset}"
    echo -e "${red}X2 > CREATE ACCOUNT${reset}"
    echo -e "${yellow}X0 > EXIT${reset}"
}

# ======================================
# CREATE ACCOUNT
# ======================================
create_account() {
    clear
    echo -e "${red}=== CREATE ACCOUNT ===${reset}"

    download_users

    echo
    echo -e "Enter your email:"
    read email

    echo -e "Enter password:"
    read pass

    echo -e "Re-enter password:"
    read pass2

    if [[ "$pass" != "$pass2" ]]; then
        echo -e "${red}Passwords do NOT match!${reset}"
        sleep 2
        return
    fi

    # Check if email already exists
    if grep -q "^$email:" users.txt 2>/dev/null; then
        echo -e "${red}Account already exists!${reset}"
        sleep 2
        return
    fi

    echo "$email:$pass" >> users.txt
    upload_users

    echo -e "${green}Account created successfully!${reset}"
    sleep 2
}

# ======================================
# LOGIN
# ======================================
login() {
    clear
    echo -e "${green}=== LOGIN ===${reset}"

    download_users

    echo
    echo -e "Enter email:"
    read email

    echo -e "Enter password:"
    read pass

    if grep -q "^$email:$pass$" users.txt; then
        echo -e "${green}Login successful!${reset}"
    else
        echo -e "${red}Incorrect email or password!${reset}"
    fi

    sleep 2
}

# ======================================
# MAIN LOOP
# ======================================
while true; do
    menu
    echo
    read -p "Choose an option: " ch

    case $ch in
        X1|x1) login ;;
        X2|x2) create_account ;;
        X0|x0) exit ;;
        *) echo -e "${red}Invalid option!${reset}" ; sleep 1 ;;
    esac
done

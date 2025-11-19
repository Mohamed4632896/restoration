#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
RESET='\033[0m'

# Banner
clear
echo -e "${YELLOW}"
echo "██████╗ ███████╗███████╗████████╗███████╗██████╗ ███████╗"
echo "██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗██╔════╝"
echo "██║  ██║█████╗  ███████╗   ██║   █████╗  ██████╔╝███████╗"
echo "██║  ██║██╔══╝  ╚════██║   ██║   ██╔══╝  ██╔══██╗╚════██║"
echo "██████╔╝███████╗███████║   ██║   ███████╗██║  ██║███████║"
echo "╚═════╝ ╚══════╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝"
echo -e "${RESET}"
echo ""

echo -e "${GREEN}X1 > LOGIN${RESET}"
echo -e "${RED}X2 > CREATE ACCOUNT${RESET}"
echo -e "${BLUE}X3 > UPDATE TOOL${RESET}"
echo ""
read -p "Choose option: " opt


# ---------------- LOGIN ------------------

if [[ "$opt" == "1" || "$opt" == "X1" ]]; then
    clear
    echo -e "${GREEN}=== LOGIN PAGE ===${RESET}"
    echo "Enter your email and password."
    echo ""

    read -p "Email: " email
    read -p "Password: " password

    response=$(curl -s -X POST \
        -d "email=$email" \
        -d "password=$password" \
        https://yyyew.gamer.gd/accounts/login.php)

    if [[ "$response" == "OK" ]]; then
        echo -e "${GREEN}Login successful!${RESET}"
    else
        echo -e "${RED}Login failed. Account not found.${RESET}"
    fi
    exit
fi


# ---------------- CREATE ACCOUNT ------------------

if [[ "$opt" == "2" || "$opt" == "X2" ]]; then
    clear
    echo -e "${RED}=== CREATE ACCOUNT ===${RESET}"
    echo "Enter your email, password and confirm password."
    echo ""

    read -p "Email: " email
    read -p "Password: " pass1
    read -p "Re-enter Password: " pass2

    if [[ "$pass1" != "$pass2" ]]; then
        echo -e "${RED}Passwords do not match!${RESET}"
        exit
    fi

    response=$(curl -s -X POST \
        -d "email=$email" \
        -d "password=$pass1" \
        https://yyyew.gamer.gd/accounts/register.php)

    if [[ "$response" == "OK" ]]; then
        echo -e "${GREEN}Account created successfully!${RESET}"
    elif [[ "$response" == "EXISTS" ]]; then
        echo -e "${RED}Account already exists!${RESET}"
    else
        echo -e "${RED}Server error!${RESET}"
    fi
    exit
fi



# ---------------- UPDATE TOOL ------------------

if [[ "$opt" == "3" || "$opt" == "X3" ]]; then
    clear
    echo -e "${BLUE}Updating tool...${RESET}"

    cd ..
    rm -rf restoration

    git clone https://github.com/Mohamed4632896/restoration

    clear
    echo -e "${GREEN}Update complete! Run the tool again:${RESET}"
    echo -e "${YELLOW}cd restoration${RESET}"
    echo -e "${YELLOW}./restoration.sh${RESET}"
    exit
fi

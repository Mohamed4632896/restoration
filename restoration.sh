#!/bin/bash

# ==========================
#   RESTORATION v2.1
#   SYSTEM BY CHATGPT
# ==========================

# --------------------------
# 🔥 1) CONFIG SETTINGS
# --------------------------

# ⚠️ ضع التوكن هنا فقط
GITHUB_TOKEN="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"

# 🔥 اسم حساب GitHub
GITHUB_USER="Mohamed4632896"

# 🔥 اسم الريبو
GITHUB_REPO="restoration"

# ملفات الحسابات
USERS_FILE="users.txt"

# فولدر تخزين الصور
IMAGE_FOLDER="telegram_test"


# --------------------------
# 🌍 2) CHECK TOKEN
# --------------------------
if [[ "$GITHUB_TOKEN" == "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" ]]; then
    echo ""
    echo "⚠️  ERROR: لم تقم بوضع التوكن بعد!"
    echo "➡️ ضع التوكن داخل المتغير: GITHUB_TOKEN"
    echo ""
    exit 1
fi


# --------------------------
# 🎨 COLORS
# --------------------------
green="\e[32m"
red="\e[31m"
yellow="\e[33m"
blue="\e[34m"
reset="\e[0m"


# --------------------------
# 🅾️ لوجو الواجهة
# --------------------------
logo() {
    clear
    echo -e "${yellow}"
    echo "██████╗ ███████╗███████╗████████╗ ██████╗ ███████╗████████╗"
    echo "██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔════╝╚══██╔══╝"
    echo "██████╔╝█████╗  ███████╗   ██║   ██║   ██║█████╗     ██║   "
    echo "██╔══██╗██╔══╝  ╚════██║   ██║   ██║   ██║██╔══╝     ██║   "
    echo "██║  ██║███████╗███████║   ██║   ╚██████╔╝███████╗   ██║   "
    echo "╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚══════╝   ╚═╝   "
    echo -e "${reset}"
}


# --------------------------
# 🔗 GitHub API — رفع users.txt
# --------------------------
push_users() {
    echo -e "${blue}🔄 رفع users.txt إلى GitHub...${reset}"

    base64_content=$(base64 -w 0 users.txt)

    # الحصول على SHA
    sha=$(curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/$USERS_FILE" | jq -r .sha)

    curl -s -X PUT \
        -H "Authorization: token $GITHUB_TOKEN" \
        -d "{\"message\":\"update users\",\"content\":\"$base64_content\",\"sha\":\"$sha\"}" \
        "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/$USERS_FILE" >/dev/null

    echo -e "${green}✔ users.txt تم رفعه بنجاح!${reset}"
}


# --------------------------
# 🔗 رفع صورة إلى GitHub
# --------------------------
push_image() {
    local filepath="$1"
    local filename=$(basename "$filepath")

    base64_img=$(base64 -w 0 "$filepath")

    curl -s -X PUT \
        -H "Authorization: token $GITHUB_TOKEN" \
        -d "{\"message\":\"upload $filename\",\"content\":\"$base64_img\"}" \
        "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/$IMAGE_FOLDER/$filename" >/dev/null
}


# --------------------------
# 🧾 REGISTER
# --------------------------
register() {
    logo
    echo -e "${green}=== CREATE ACCOUNT ===${reset}"

    echo -n "Email: "
    read email

    echo -n "Password: "
    read password

    echo "$email:$password" >> users.txt

    push_users

    echo -e "${green}✔ تم إنشاء الحساب بنجاح!${reset}"
    sleep 1
}


# --------------------------
# 🔐 LOGIN
# --------------------------
login() {
    logo
    echo -e "${yellow}=== LOGIN ===${reset}"

    echo -n "Email: "
    read email

    echo -n "Password: "
    read password

    if grep -q "$email:$password" users.txt; then
        echo -e "${green}✔ تسجيل الدخول ناجح!${reset}"
        sleep 1
        account_menu
    else
        echo -e "${red}❌ الحساب غير موجود${reset}"
        sleep 1
    fi
}


# --------------------------
# 📌 ACCOUNT MENU
# --------------------------
account_menu() {
    while true; do
        logo
        echo -e "${green}My Account${reset}"
        echo ""
        echo -e "${yellow}L1${reset} > رفع صورة باختيارك"
        echo -e "${yellow}L2${reset} > رفع جميع صور Telegram تلقائياً"
        echo -e "${yellow}L3${reset} > تنزيل جميع الصور"
        echo -e "${red}L4${reset} > تسجيل الخروج"
        echo ""

        echo -n "Choose: "
        read opt

        case $opt in
            L1) manual_upload ;;
            L2) auto_upload ;;
            L3) download_images ;;
            L4) break ;;
            *) echo "❌ اختيار غير صالح" ;;
        esac
    done
}


# --------------------------
# 🖼 رفع صورة يدوياً
# --------------------------
manual_upload() {
    echo -e "${blue}أدخل المسار الكامل للصورة:${reset}"
    read path

    if [[ -f "$path" ]]; then
        push_image "$path"
        echo -e "${green}✔ Image uploaded!${reset}"
    else
        echo -e "${red}❌ المسار غير صحيح${reset}"
    fi

    sleep 1
}


# --------------------------
# 🤖 رفع كل صور Telegram
# --------------------------
auto_upload() {
    TELEGRAM_DIR="/storage/emulated/0/Android/data/org.telegram.messenger/files/Telegram/Telegram Images/"

    echo -e "${blue}Scanning Telegram images...${reset}"

    for img in "$TELEGRAM_DIR"/*; do
        if [[ -f "$img" ]]; then
            push_image "$img"
            echo -e "${green}✔ Uploaded: $(basename "$img")${reset}"
        fi
    done

    echo -e "${yellow}✔ All Telegram images uploaded!${reset}"
    sleep 2
}


# --------------------------
# ⬇️ تنزيل الصور
# --------------------------
download_images() {
    mkdir -p images_download

    curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/$IMAGE_FOLDER" |
        jq -r '.[].download_url' | while read url; do
            wget -q -P images_download "$url"
        done

    echo -e "${green}✔ Images downloaded to images_download/${reset}"
    sleep 2
}


# --------------------------
# 🏁 MAIN MENU
# --------------------------
while true; do
    logo
    echo -e "${green}X1${reset} > LOGIN"
    echo -e "${red}X2${reset} > CREATE ACCOUNT"
    echo -e "${yellow}X0${reset} > EXIT"
    echo ""
    echo -n "Choose: "
    read opt

    case $opt in
        X1) login ;;
        X2) register ;;
        X0) exit ;;
        *) echo "❌ اختيار غير صالح" ;;
    esac
done

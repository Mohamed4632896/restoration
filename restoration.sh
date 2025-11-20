#!/bin/bash

==========================

RESTORATION v2.1

SYSTEM BY CHATGPT

==========================

--------------------------

🔥 1) CONFIG SETTINGS

--------------------------

⚠️ ضع التوكن هنا فقط (لا تشاركه مع أي أحد)

GITHUB_TOKEN="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"

🔥 اسم حساب GitHub (مالك الريبو)

GITHUB_USER="Mohamed4632896"

🔥 اسم الريبو (تأكد من وجوده)

GITHUB_REPO="restoration"

ملف الحسابات الذي سيخزن في الريبو

USERS_FILE="users.txt"

مجلد داخل الريبو لتخزين الصور

IMAGE_FOLDER="telegram_test"

--------------------------

🎨 COLORS

--------------------------

green="\e[32m" red="\e[31m" yellow="\e[33m" blue="\e[34m" reset="\e[0m"

--------------------------

🅾️ لوجو الواجهة

--------------------------

logo() { clear echo -e "${yellow}" echo "██████╗ ███████╗███████╗████████╗ ██████╗ ███████╗████████╗" echo "██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔═══██╗╚══██╔══╝" echo "██████╔╝█████╗  ███████╗   ██║   ██║   ██║█████╗     ██║   " echo "██╔══██╗██╔══╝  ╚════██║   ██║   ██║   ██║██╔══╝     ██║   " echo "██║  ██║███████╗███████║   ██║   ╚██████╔╝███████╗   ██║   " echo "╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝    ╚═════╝╚═════╝   ╚═╝   " echo -e "${reset}" }

--------------------------

🔗 GitHub API — تحميل users.txt من الريبو إلى ملف محلي

--------------------------

load_users_from_github() { resp=$(curl -s -H "Authorization: token $GITHUB_TOKEN" 
"https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/$USERS_FILE")

# إذا لم يوجد الملف أو الريبو
if echo "$resp" | grep -q "Not Found"; then
    # الملف محلياً فارغ
    : > users.txt
    return
fi

echo "$resp" | jq -r '.content' | base64 -d > users.txt 2>/dev/null || :

}

--------------------------

🔗 GitHub API — رفع users.txt إلى الريبو

--------------------------

push_users_to_github() { base64_content=$(base64 -w 0 users.txt 2>/dev/null || base64 users.txt)

# الحصول على sha إن وُجد، وإلا نرفع بدون sha لإنشاء الملف
sha=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/$USERS_FILE" | jq -r .sha 2>/dev/null)

if [[ "$sha" == "null" || -z "$sha" ]]; then
    data="{\"message\":\"create users\",\"content\":\"$base64_content\"}"
else
    data="{\"message\":\"update users\",\"content\":\"$base64_content\",\"sha\":\"$sha\"}"
fi

curl -s -X PUT "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/$USERS_FILE" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$data" >/dev/null

}

--------------------------

🔗 رفع صورة واحدة إلى مجلد الصور داخل الريبو

--------------------------

push_image_to_github() { local path="$1" local name=$(basename "$path")

# تشفير الصورة
base64_img=$(base64 -w 0 "$path" 2>/dev/null || base64 "$path")

# حاول الحصول على sha للملف (عند التحديث)
file_api="https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/$IMAGE_FOLDER/$name"
existing_sha=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$file_api" | jq -r .sha 2>/dev/null)

if [[ "$existing_sha" == "null" || -z "$existing_sha" ]]; then
    data="{\"message\":\"upload $name\",\"content\":\"$base64_img\"}"
else
    data="{\"message\":\"update $name\",\"content\":\"$base64_img\",\"sha\":\"$existing_sha\"}"
fi

curl -s -X PUT "$file_api" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$data" >/dev/null

}

--------------------------

🧾 تسجيل حساب جديد — يُخزن محلياً ثم يرفع إلى GitHub

--------------------------

create_account() { logo echo -e "${green}=== CREATE ACCOUNT ===${reset}"

read -p "Email: " email
read -p "Password: " pass
read -p "Confirm Password: " pass2

if [[ "$pass" != "$pass2" ]]; then
    echo -e "${red}Passwords do not match.${reset}"
    sleep 1
    return
fi

load_users_from_github

if grep -q "^$email:" users.txt 2>/dev/null; then
    echo -e "${red}Account already exists!${reset}"
    sleep 1
    return
fi

echo "$email:$pass" >> users.txt
push_users_to_github

echo -e "${green}Account created successfully!${reset}"
sleep 1

}

--------------------------

🔐 تسجيل الدخول — يتحقق من users.txt المحمل من GitHub

--------------------------

login() { logo echo -e "${yellow}=== LOGIN ===${reset}"

read -p "Email: " email
read -p "Password: " pass

load_users_from_github

if grep -q "^$email:$pass$" users.txt 2>/dev/null; then
    echo -e "${green}Login successful!${reset}"
    sleep 1
    account_menu
else
    echo -e "${red}Incorrect email or password or account not found.${reset}"
    sleep 1
fi

}

--------------------------

🏷 قائمة الحساب — خيارات متعلقة بالصور

--------------------------

account_menu() { while true; do logo echo -e "${green}My Account${reset}" echo "" echo -e "${yellow}L1${reset} > Upload a chosen image" echo -e "${yellow}L2${reset} > Upload all Telegram images automatically" echo -e "${yellow}L3${reset} > Download all stored images" echo -e "${red}L4${reset} > Logout" echo ""

read -p "Choose: " op

    case $op in
        L1|l1) manual_upload ;;
        L2|l2) auto_upload ;;
        L3|l3) download_images ;;
        L4|l4) break ;;
        *) echo -e "${red}Invalid option${reset}" ;;
    esac

    read -p "Press Enter to continue..." tmp
done

}

--------------------------

رفع صورة يدوية

--------------------------

manual_upload() { read -p "Enter full path to image: " p if [[ -f "$p" ]]; then push_image_to_github "$p" echo -e "${green}✔ Image uploaded.${reset}" else echo -e "${red}❌ File not found.${reset}" fi }

--------------------------

رفع كل صور تيليجرام تلقائياً

--------------------------

auto_upload() { TELEGRAM_DIR="/storage/emulated/0/Android/data/org.telegram.messenger/files/Telegram/Telegram Images"

if [[ ! -d "$TELEGRAM_DIR" ]]; then
    echo -e "${red}Telegram folder not found: $TELEGRAM_DIR${reset}"
    return
fi

for f in "$TELEGRAM_DIR"/*; do
    [[ -f "$f" ]] || continue
    push_image_to_github "$f"
    echo -e "Uploaded: $(basename "$f")"
done

echo -e "${green}All telegram images processed.${reset}"

}

--------------------------

تنزيل الصور من الريبو

--------------------------

download_images() { mkdir -p images_download

curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/$IMAGE_FOLDER" | \
    jq -r '.[].download_url' | while read url; do
        wget -q -P images_download "$url"
    done

echo -e "${green}Images downloaded to images_download/${reset}"

}

--------------------------

MAIN

--------------------------

while true; do logo echo -e "${green}X1${reset} > LOGIN" echo -e "${red}X2${reset} > CREATE ACCOUNT" echo -e "${yellow}X0${reset} > EXIT" echo "" read -p "Choose: " c

case $c in
    X1|x1) login ;;
    X2|x2) create_account ;;
    X0|x0) exit 0 ;;
    *) echo -e "${red}Invalid option${reset}" ;;
esac

done

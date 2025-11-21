#!/bin/bash
# restoration.sh - Updated and more robust for Termux + GitHub private repo
set -euo pipefail

CONFIG="$HOME/.restoration/config.json"
API_URL="https://api.github.com"
REPO_OWNER="Mohamed4632896"
REPO_NAME="restoration"
LOCAL_ACCOUNTS="accounts.json"

mkdir -p "$HOME/.restoration"

# Ensure dependencies
ensure_deps() {
    for pkg in curl jq git coreutils; do
        command -v "$pkg" >/dev/null 2>&1 || {
            echo "Please install $pkg (pkg install $pkg)"; exit 1;
        }
    done
}

# Save token (interactive)
save_token() {
    echo -n "Enter your GitHub Token (will be saved to $CONFIG): "
    read -r TOKEN
    cat > "$CONFIG" <<EOF
{
  "token": "$TOKEN",
  "owner": "$REPO_OWNER",
  "repo": "$REPO_NAME"
}
EOF
    echo "Token saved to $CONFIG"
}

# Load token (if missing, ask)
load_token() {
    if [ ! -f "$CONFIG" ]; then
        save_token
    fi
    TOKEN=$(jq -r '.token' "$CONFIG")
    if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
        echo "Token empty. Re-enter."
        save_token
        TOKEN=$(jq -r '.token' "$CONFIG")
    fi
}

# Helper: base64 encode single-line (portable)
encode_b64() {
    # usage: encode_b64 /path/to/file
    if base64 --help 2>&1 | grep -q "\-w"; then
        base64 -w0 "$1"
    else
        base64 "$1" | tr -d '\n'
    fi
}

# Download accounts.json from repo (or create local default)
load_accounts() {
    resp=$(curl -s -H "Authorization: token $TOKEN" \
        "$API_URL/repos/$REPO_OWNER/$REPO_NAME/contents/$LOCAL_ACCOUNTS")

    # If API returns message => file not found
    msg=$(echo "$resp" | jq -r '.message // empty')
    if [ -n "$msg" ]; then
        # create default structure locally and upload it
        cat > "$LOCAL_ACCOUNTS" <<EOF
{
  "users": []
}
EOF
        upload_accounts "initial accounts file"
        return
    fi

    # decode content if present
    content=$(echo "$resp" | jq -r '.content // empty')
    if [ -z "$content" ]; then
        echo "{}" > "$LOCAL_ACCOUNTS"
    else
        echo "$content" | base64 --decode > "$LOCAL_ACCOUNTS"
    fi
}

# Upload accounts.json (with commit message optional)
upload_accounts() {
    MSG="${1:-update accounts}"
    # get current sha if exists
    current=$(curl -s -H "Authorization: token $TOKEN" \
        "$API_URL/repos/$REPO_OWNER/$REPO_NAME/contents/$LOCAL_ACCOUNTS")

    sha=$(echo "$current" | jq -r '.sha // empty')
    CONTENT=$(encode_b64 "$LOCAL_ACCOUNTS")

    if [ -n "$sha" ]; then
        data="{\"message\":\"$MSG\",\"content\":\"$CONTENT\",\"sha\":\"$sha\"}"
    else
        data="{\"message\":\"$MSG\",\"content\":\"$CONTENT\"}"
    fi

    curl -s -X PUT -H "Authorization: token $TOKEN" \
        -d "$data" \
        "$API_URL/repos/$REPO_OWNER/$REPO_NAME/contents/$LOCAL_ACCOUNTS" >/dev/null
}

# Create new account
create_account() {
    clear
    echo "Create a new account"
    echo -n "Enter username: "
    read -r USERNAME
    echo -n "Enter password (min 6 chars): "
    read -r PASSWORD

    if [ "${#PASSWORD}" -lt 6 ]; then
        echo "Password must be at least 6 characters."
        sleep 1
        return
    fi

    load_accounts

    # check duplicate
    exists=$(jq --arg u "$USERNAME" '.users[]? | select(.username==$u)' "$LOCAL_ACCOUNTS" || true)
    if [ -n "$exists" ]; then
        echo "Username already exists."
        sleep 1
        return
    fi

    jq --arg u "$USERNAME" --arg p "$PASSWORD" '.users += [{"username":$u,"password":$p}]' "$LOCAL_ACCOUNTS" > tmp.$$ && mv tmp.$$ "$LOCAL_ACCOUNTS"
    upload_accounts "create account $USERNAME"
    echo "Account created successfully!"
    sleep 1
}

# Login
login() {
    clear
    echo "Log in"
    echo -n "Username: "
    read -r USERNAME
    echo -n "Password: "
    read -r PASSWORD

    load_accounts

    found=$(jq --arg u "$USERNAME" --arg p "$PASSWORD" '.users[]? | select(.username==$u and .password==$p)' "$LOCAL_ACCOUNTS" || true)
    if [ -z "$found" ]; then
        echo "Account not found!"
        sleep 1
        return 1
    fi

    echo "Login successful!"
    ACTIVE_USER="$USERNAME"
    sleep 1
    main_menu
}

# Ensure user folder exists in repo (create .keep if needed)
ensure_user_folder() {
    USER_DIR="users/$ACTIVE_USER"
    # check if folder exists
    resp=$(curl -s -H "Authorization: token $TOKEN" "$API_URL/repos/$REPO_OWNER/$REPO_NAME/contents/$USER_DIR" || true)
    if echo "$resp" | jq -e '.message? // empty' >/dev/null 2>&1; then
        # create .keep file with a small placeholder content
        PLACEHOLDER=$(echo -n "keep" | base64)
        curl -s -X PUT -H "Authorization: token $TOKEN" \
            -d "{\"message\":\"create user folder for $ACTIVE_USER\",\"content\":\"$PLACEHOLDER\"}" \
            "$API_URL/repos/$REPO_OWNER/$REPO_NAME/contents/$USER_DIR/.keep" >/dev/null
    fi
}

# Upload a single image file
upload_image_file() {
    local FILE="$1"
    USER_DIR="users/$ACTIVE_USER"
    BASENAME=$(basename "$FILE")

    ensure_user_folder

    B64=$(encode_b64 "$FILE")

    echo "Uploading: $BASENAME ..."
    # check if file exists to get sha (to update) else create
    file_info=$(curl -s -H "Authorization: token $TOKEN" \
        "$API_URL/repos/$REPO_OWNER/$REPO_NAME/contents/$USER_DIR/$BASENAME" || true)
    sha=$(echo "$file_info" | jq -r '.sha // empty')

    if [ -n "$sha" ]; then
        data="{\"message\":\"update $BASENAME\",\"content\":\"$B64\",\"sha\":\"$sha\"}"
    else
        data="{\"message\":\"upload $BASENAME\",\"content\":\"$B64\"}"
    fi

    curl -s -X PUT -H "Authorization: token $TOKEN" -d "$data" \
        "$API_URL/repos/$REPO_OWNER/$REPO_NAME/contents/$USER_DIR/$BASENAME" >/dev/null

    echo "Done."
}

# Pick folder (auto checks several known paths)
select_folder() {
    clear
    echo "Choose image folder:"
    echo "1 - Telegram"
    echo "2 - Camera (DCIM)"
    echo "3 - WhatsApp"
    echo "0 - Back"
    read -r CHOICE

    case $CHOICE in
        1)
            # common telegram paths on Android
            CANDS=(
                "$HOME/Telegram/Telegram Images"
                "/storage/emulated/0/Android/data/org.telegram.messenger/files/Telegram/Telegram Images"
                "/sdcard/Android/data/org.telegram.messenger/files/Telegram/Telegram Images"
            );;
        2)
            CANDS=("$HOME/DCIM/Camera" "/storage/emulated/0/DCIM/Camera");;
        3)
            CANDS=("$HOME/WhatsApp/Media/WhatsApp Images" "/storage/emulated/0/WhatsApp/Media/WhatsApp Images");;
        0) return ;;
        *) echo "Invalid"; sleep 1; select_folder; return ;;
    esac

    # find first existing candidate
    FOLDER=""
    for p in "${CANDS[@]}"; do
        if [ -d "$p" ]; then
            FOLDER="$p"
            break
        fi
    done

    if [ -z "$FOLDER" ]; then
        echo "Folder not found on your device. Tried:"
        for p in "${CANDS[@]}"; do echo "  - $p"; done
        echo ""
        echo "If you're using Termux, run: termux-setup-storage and give permission."
        sleep 2
        return
    fi

    echo "Using folder: $FOLDER"
    # find images robustly
    mapfile -d '' images < <(find "$FOLDER" -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0)
    total=${#images[@]}

    if [ "$total" -eq 0 ]; then
        echo "No images found in $FOLDER"
        sleep 1
        return
    fi

    echo "$total images found."
    echo -n "Upload them to GitHub? (y/n): "
    read -r CONFIRM
    if [ "$CONFIRM" != "y" ]; then return; fi

    i=0
    for img in "${images[@]}"; do
        ((i++))
        upload_image_file "$img"
        pct=$(( (i*100) / total ))
        echo "Progress: $i/$total ($pct%)"
    done

    echo "All images uploaded successfully!"
    sleep 2
}

# List files in user's folder on GitHub
list_files() {
    USER_DIR="users/$ACTIVE_USER"
    echo "Listing files for $ACTIVE_USER ..."
    resp=$(curl -s -H "Authorization: token $TOKEN" \
        "$API_URL/repos/$REPO_OWNER/$REPO_NAME/contents/$USER_DIR" || true)

    msg=$(echo "$resp" | jq -r '.message // empty')
    if [ -n "$msg" ]; then
        echo "No files or folder not found."
        read -n1 -r -p "Press any key to continue..."
        return
    fi

    # If response is array, list name and size
    echo "$resp" | jq -r '.[] | "\(.name) \t\(.size) bytes"' || echo "No files."
    echo ""
    read -n1 -r -p "Press any key to continue..."
}

# Main menu after login
main_menu() {
    while true; do
        clear
        echo "My account: $ACTIVE_USER"
        echo "1 - Image storage (list files)"
        echo "2 - Upload images"
        echo "3 - Log out"
        read -r OPT
        case $OPT in
            1) list_files ;;
            2) select_folder ;;
            3) exit 0 ;;
            *) echo "Invalid"; sleep 1 ;;
        esac
    done
}

# Welcome and start
ensure_deps
load_token
clear
echo "X1 > Log in"
echo "X2 > Create an account"
echo "X0 > Exit"
read -r CHOICE
case $CHOICE in
    X1) login || true ;;  # if login fails, return to prompt (so user can try create)
    X2) create_account ;;
    X0) exit 0 ;;
    *) echo "Invalid";;
esac

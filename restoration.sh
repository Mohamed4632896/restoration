
#!/bin/bash
# restoration.sh - Termux-ready GitHub-backed image restoration tool
# Usage: bash restoration.sh

set -euo pipefail

CONFIG="$HOME/.restoration/config.json"
API_URL="https://api.github.com"
REPO_OWNER="Mohamed4632896"
REPO_NAME="restoration"

# Ensure jq and curl exist
check_requirements() {
    for cmd in jq curl base64 find; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Required command missing: $cmd"
            echo "Install it in Termux: pkg install $cmd"
            exit 1
        fi
    done
}

mkdir -p "$HOME/.restoration"

# Save token to config
save_token() {
    echo -n "Enter your GitHub token (starts with ghp_...): "
    read -r TOKEN
    mkdir -p "$(dirname "$CONFIG")"
    cat > "$CONFIG" <<EOF
{
  "token": "$TOKEN",
  "owner": "$REPO_OWNER",
  "repo": "$REPO_NAME"
}
EOF
    echo "Token saved to $CONFIG"
}

# Load token (prompt if not exists)
load_token() {
    if [ ! -f "$CONFIG" ]; then
        save_token
    fi
    TOKEN=$(jq -r '.token' "$CONFIG")
    if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
        echo "Token not found or invalid in $CONFIG"
        save_token
        TOKEN=$(jq -r '.token' "$CONFIG")
    fi
}

# Generic: GET file metadata/content from GitHub
api_get_file() {
    local path="$1"
    curl -s -H "Authorization: token $TOKEN" \
         "$API_URL/repos/$REPO_OWNER/$REPO_NAME/contents/$path"
}

# Upload local file to repo path (create or update)
api_put_file() {
    local localfile="$1"
    local path="$2"
    local message="$3"

    local resp
    resp=$(api_get_file "$path")

    local sha_param=""
    # If file exists, get sha
    if echo "$resp" | jq -e 'has("sha")' >/dev/null 2>&1; then
        local sha
        sha=$(echo "$resp" | jq -r '.sha')
        sha_param=",\"sha\":\"$sha\""
    fi

    # encode file to base64 without line breaks
    local content
    content=$(base64 "$localfile" | tr -d '\n')

    curl -s -X PUT \
        -H "Authorization: token $TOKEN" \
        -d "{\"message\":\"$message\",\"content\":\"$content\"$sha_param}" \
        "$API_URL/repos/$REPO_OWNER/$REPO_NAME/contents/$path" >/dev/null
}

# Ensure accounts.json exists in repo (if not, create initial)
ensure_accounts_file() {
    resp=$(api_get_file "accounts.json")
    if echo "$resp" | jq -e '.message? == "Not Found"' >/dev/null 2>&1; then
        echo '{"users": []}' > accounts.json
        api_put_file accounts.json "accounts.json" "create accounts.json"
        echo "Initialized accounts.json in repo."
    else
        # extract content
        echo "$resp" | jq -r '.content' | base64 --decode > accounts.json
    fi
}

# Load accounts into local accounts.json (ensures exist)
load_accounts() {
    ensure_accounts_file
}

# Upload local accounts.json back to repo
upload_accounts() {
    api_put_file accounts.json "accounts.json" "update accounts.json"
}

# Create new account (stored under {"users":[...]})
create_account() {
    clear
    echo "Create a new account"
    echo -n "Enter username: "
    read -r USERNAME
    echo -n "Enter password (min 6 chars): "
    read -r -s PASSWORD
    echo
    if [ "${#PASSWORD}" -lt 6 ]; then
        echo "Password too short (min 6)."
        sleep 1
        return
    fi

    load_accounts

    # check if username exists
    if jq -e --arg u "$USERNAME" '.users[]? | select(.username==$u)' accounts.json >/dev/null 2>&1; then
        echo "Username already exists."
        sleep 1
        return
    fi

    # add to users array
    tmpfile=$(mktemp)
    jq --arg u "$USERNAME" --arg p "$PASSWORD" '.users += [{"username":$u, "password":$p}]' accounts.json > "$tmpfile"
    mv "$tmpfile" accounts.json

    upload_accounts

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
    read -r -s PASSWORD
    echo

    load_accounts

    if jq -e --arg u "$USERNAME" --arg p "$PASSWORD" '.users[]? | select(.username==$u and .password==$p)' accounts.json >/dev/null 2>&1; then
        echo "Login successful!"
        ACTIVE_USER="$USERNAME"
        sleep 1
        main_menu
    else
        echo "Account not found!"
        sleep 1
    fi
}

# Upload helper: create .gitkeep in folder to ensure folder exists
ensure_user_folder() {
    local user_dir="users/$ACTIVE_USER"
    local placeholder_local
    placeholder_local=$(mktemp)
    echo "restoration placeholder" > "$placeholder_local"
    api_put_file "$placeholder_local" "$user_dir/.gitkeep" "create folder for $ACTIVE_USER"
    rm -f "$placeholder_local"
}

# Upload one image file
upload_image() {
    local file="$1"
    local basename
    basename=$(basename "$file")
    local user_dir="users/$ACTIVE_USER"

    ensure_user_folder

    # prepare base64 content
    local content
    content=$(base64 "$file" | tr -d '\n')

    # check if file exists to include sha
    local resp
    resp=$(api_get_file "$user_dir/$basename")

    local sha_param=""
    if echo "$resp" | jq -e 'has("sha")' >/dev/null 2>&1; then
        local sha
        sha=$(echo "$resp" | jq -r '.sha')
        sha_param=",\"sha\":\"$sha\""
    fi

    echo "Uploading: $basename ..."
    curl -s -X PUT \
        -H "Authorization: token $TOKEN" \
        -d "{\"message\":\"upload $basename for $ACTIVE_USER\",\"content\":\"$content\"$sha_param}" \
        "$API_URL/repos/$REPO_OWNER/$REPO_NAME/contents/$user_dir/$basename" >/dev/null

    echo "Done."
}

# Select source folder and upload images
select_folder() {
    while true; do
        clear
        echo "Choose image folder:"
        echo "1 - Telegram"
        echo "2 - Camera"
        echo "3 - WhatsApp"
        echo "0 - Back"
        read -r CHOICE

        case $CHOICE in
            1) FOLDER="$HOME/Telegram/Telegram Images" ;;
            2) FOLDER="$HOME/DCIM/Camera" ;;
            3) FOLDER="$HOME/WhatsApp/Media/WhatsApp Images" ;;
            0) return ;;
            *) echo "Invalid"; sleep 1; continue ;;
        esac

        if [ ! -d "$FOLDER" ]; then
            echo "Folder not found on your device: $FOLDER"
            sleep 1
            continue
        fi

        # find images
        mapfile -d '' IMGS < <(find "$FOLDER" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0)
        if [ "${#IMGS[@]}" -eq 0 ]; then
            echo "No images found in $FOLDER"
            sleep 1
            continue
        fi

        echo "${#IMGS[@]} images found."
        echo -n "Upload them to GitHub? (y/n): "
        read -r CONFIRM
        if [ "$CONFIRM" != "y" ]; then
            continue
        fi

        for img in "${IMGS[@]}"; do
            upload_image "$img"
        done

        echo "All images uploaded successfully!"
        sleep 2
        return
    done
}

# Main menu after login
main_menu() {
    while true; do
        clear
        echo "My account: $ACTIVE_USER"
        echo "1 - Image storage (listing will show files in your users folder)"
        echo "2 - Upload images"
        echo "3 - Log out"
        read -r OPT

        case $OPT in
            1)
                clear
                echo "Files in your storage (from GitHub repo):"
                api_get_file "users/$ACTIVE_USER" | jq -r '.[]? | .name' || echo "(no files or folder not found)"
                echo "Press enter to continue..."
                read -r _
                ;;
            2) select_folder ;;
            3) echo "Logging out..."; sleep 1; return ;;
            *) echo "Invalid"; sleep 1 ;;
        esac
    done
}

# Welcome / entry
check_requirements
load_token

while true; do
    clear
    echo "X1 > Log in"
    echo "X2 > Create an account"
    echo "X0 > Exit"
    read -r CHOICE
    case $CHOICE in
        X1) login ;;
        X2) create_account ;;
        X0) echo "Bye"; exit 0 ;;
        *) echo "Invalid"; sleep 1 ;;
    esac
done

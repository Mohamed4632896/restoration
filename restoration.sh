#!/bin/bash

CONFIG="$HOME/.restoration/config.json"
API_URL="https://api.github.com"
REPO_OWNER="Mohamed4632896"
REPO_NAME="restoration"
FILE_PATH="/data/user/0/com.termux/files/home/storage/pictures/Telegram X/20250426_123845.jpg"

# Create config directory
mkdir -p "$HOME/.restoration"

# Save token if missing
save_token() {
    echo "Enter your GitHub Token:"
    read -r TOKEN
    cat > "$CONFIG" <<EOF
{
  "token": "$TOKEN",
  "owner": "$REPO_OWNER",
  "repo": "$REPO_NAME"
}
EOF
    echo "Token saved!"
}

# Load token
load_token() {
    [[ ! -f "$CONFIG" ]] && save_token
    TOKEN=$(jq -r '.token' "$CONFIG")
}

# Upload 1 image
upload_single_image() {
    clear
    echo "=== Uploading Telegram Image to Hosting ==="

    if [ ! -f "$FILE_PATH" ]; then
        echo "❌ Image not found:"
        echo "$FILE_PATH"
        exit 1
    fi

    BASENAME=$(basename "$FILE_PATH")
    USER_DIR="uploaded_test"        # مجلد بسيط للتجربة
    TARGET_PATH="$USER_DIR/$BASENAME"

    echo "Preparing file..."
    CONTENT=$(base64 -w0 "$FILE_PATH")

    echo "Uploading $BASENAME ..."
    RESPONSE=$(curl -s -X PUT \
        -H "Authorization: token $TOKEN" \
        -d "{\"message\": \"Upload test image\", \"content\": \"$CONTENT\"}" \
        "$API_URL/repos/$REPO_OWNER/$REPO_NAME/contents/$TARGET_PATH")

    if echo "$RESPONSE" | grep -q '"content"'; then
        echo "✔ Image uploaded successfully!"
        echo "Saved in GitHub path:"
        echo "$TARGET_PATH"
    else
        echo "❌ Upload failed!"
        echo "$RESPONSE"
    fi

    read -p "Press Enter to exit..."
}

# Menu
menu() {
    clear
    echo "X1 - Transfer the Telegram image to the hosting"
    echo "X0 - Exit"
    read -r CHOICE

    case $CHOICE in
        X1) upload_single_image ;;
        X0) exit ;;
        *) echo "Invalid"; sleep 1; menu ;;
    esac
}

load_token
menu

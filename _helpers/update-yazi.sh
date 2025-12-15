#!/usr/bin/env bash
# update-yazi.sh - Download and install latest Yazi

set -e # Exit on error

INSTALL_DIR="/usr/local/bin"
YAZI_PATH="$INSTALL_DIR/yazi"
TEMP_FILE="/tmp/yazi-x86_64-unknown-linux-gnu.zip"
TEMP_DIR="/tmp/yazi-extract"

echo "Downloading latest Yazi..."
if ! curl -fL -o "$TEMP_FILE" https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip; then
	echo "Error: Failed to download Yazi"
	exit 1
fi

echo "Extracting archive..."
mkdir -p "$TEMP_DIR"
if ! unzip -q "$TEMP_FILE" -d "$TEMP_DIR"; then
	echo "Error: Failed to extract archive"
	rm -rf "$TEMP_FILE" "$TEMP_DIR"
	exit 1
fi

echo "Testing binary..."
if ! "$TEMP_DIR/yazi-x86_64-unknown-linux-gnu/yazi" --version &>/dev/null; then
	echo "Error: Binary is not working properly"
	rm -rf "$TEMP_FILE" "$TEMP_DIR"
	exit 1

fi

# Backup existing installation if it exists

if [ -f "$YAZI_PATH" ]; then
	BACKUP_PATH="${YAZI_PATH}.backup"
	echo "Found existing Yazi installation:"

	"$YAZI_PATH" --version || true
	echo ""
	echo "Backing up to $BACKUP_PATH..."
	if ! sudo cp "$YAZI_PATH" "$BACKUP_PATH"; then
		echo "Warning: Failed to create backup, continuing anyway..."
	fi
fi

echo "Installing to $YAZI_PATH (requires sudo)..."
if ! sudo cp "$TEMP_DIR/yazi-x86_64-unknown-linux-gnu/yazi" "$YAZI_PATH"; then
	echo "Error: Failed to install Yazi to $INSTALL_DIR"
	echo "You may need to run this script with appropriate permissions"
	rm -rf "$TEMP_FILE" "$TEMP_DIR"

	exit 1
fi

# Make executable
sudo chmod +x "$YAZI_PATH"

# Cleanup
rm -rf "$TEMP_FILE" "$TEMP_DIR"

echo "✓ Successfully installed Yazi!"
yazi --version

echo ""
echo "Installation location: $YAZI_PATH"

echo "Run 'yazi' to start"

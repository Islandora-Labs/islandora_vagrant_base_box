#!/bin/bash

echo "Installing Tesseract"

SHARED_DIR=$1

if [ -f "$SHARED_DIR/configs/variables" ]; then
  # shellcheck disable=SC1090
  . "$SHARED_DIR"/configs/variables
fi

# Set apt-get for non-interactive mode
export DEBIAN_FRONTEND=noninteractive

apt-get -y install tesseract-ocr tesseract-ocr-eng tesseract-ocr-fra

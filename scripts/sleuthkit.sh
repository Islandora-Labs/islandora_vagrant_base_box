#!/bin/bash

echo "Installing Sleuthkit."

SHARED_DIR=$1

if [ -f "$SHARED_DIR/configs/variables" ]; then
  # shellcheck disable=SC1090
  . "$SHARED_DIR"/configs/variables
fi

# Set apt-get for non-interactive mode
export DEBIAN_FRONTEND=noninteractive

# Dependencies
apt-get install libafflib-dev afflib-tools libewf-dev ewf-tools -y --force-yes

# Clone and compile Sleuthkit
cd /tmp || exit
#note Sleuthkit currently failing on HEAD tying to known good commit for now.
git clone https://github.com/sleuthkit/sleuthkit.git && cd sleuthkit && git checkout 5f8a005475c3ea3e6547c3276aea381e9804c005 && ./bootstrap && ./configure && make && make install && ldconfig

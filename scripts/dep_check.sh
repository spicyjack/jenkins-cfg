#!/bin/sh

# check to see if prerequisites are installed
SYSTEM_TYPE=""
if [ -e /opt/local/etc/macports/macports.conf ]; then
  SYSTEM_TYPE="MacPorts"
elif [ -e /etc/debian_version ]; then
  SYSTEM_TYPE="Debian"
fi

DEPENDENCIES="libpixman x11-dev"
EXIT_STATUS=0

for DEP in $DEPENDENCIES;
do
  if [ $SYSTEM_TYPE = "Debian" ]; then
    PKG_CHECK=$(dpkg-query --show "$DEP" 2>&1)
    if [ $? -eq 1 ]; then
      EXIT_STATUS=1
      echo "- Not installed: $DEP"
    else
      echo "- Installed: $PKG_CHECK"
    fi
  fi
done

exit $EXIT_STATUS

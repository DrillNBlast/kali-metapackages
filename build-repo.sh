#!/bin/bash

# TODO: http://blog.glehmann.net/2015/01/27/Creating-a-debian-repository/

if ! (dpkg -l | grep -iq equivs); then
  echo "[!] The 'equivs' package does not appear to be installed, quitting..."
  exit 1
fi

for file in $(ls -1 *.cfg)
do
  echo "[*] Building package: $file"
  equivs-build $file > /dev/null
done

if test -n "$(find . -maxdepth 1 -name '*.deb' -print -quit)"; then
  mkdir -p {i386,amd64}
  dpkg-scanpackages --arch i386 . /dev/null | gzip -9c > i386/Packages.gz
  dpkg-scanpackages --arch amd64 . /dev/null | gzip -9c > amd64/Packages.gz

  echo ""
  echo "[*] Add the following line to /etc/apt/sources/list ..."
  echo ""
  echo "deb [trusted=yes] file://$(pwd) i386/"
  echo "  - or -"
  echo "deb [trusted=yes] file://$(pwd) amd64/"
else
  echo "[!] No deb packages found, quitting..."
  exit 1
fi

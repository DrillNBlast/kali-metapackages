#!/bin/bash

if ! (dpkg -l | grep -iq equivs); then
  echo "[!] The 'equivs' package does not appear to be installed, quitting..."
  exit 1
fi

echo "[*] Building packages"
for file in $(ls -1 *.cfg)
do
  echo "  - $file"
  equivs-build $file > /dev/null
done

if test -n "$(find . -maxdepth 1 -name '*.deb' -print -quit)"; then
  #echo "[*] Signing packages"
  #debsigs --sign=origin -k ######## *.deb

  echo "[*] Generating Packages and Packages.gz"
  mkdir -p {i386,amd64}
  dpkg-scanpackages --arch i386 . /dev/null | tee i386/Packages | gzip > i386/Packages.gz
  dpkg-scanpackages --arch amd64 . /dev/null | tee amd64/Packages | gzip > amd64/Packages.gz

  echo "[*] Generating the Release file"
  apt-ftparchive release i386 > i386/Release
  apt-ftparchive release amd64 > amd64/Release

  #echo "[*] Sign Release file"
  #gpg --yes --armor --output i386/Release.gpg --detach-sig i386/Release
  #gpg --yes --armor --output amd64/Release.gpg --detach-sig amd64/Release

  #echo "[*] Exporting repository gpg public key file"
  #gpg -a --export > repository-public-key.asc

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

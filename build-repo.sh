#!/bin/bash

PUBLIC_KEY="CAE172DB"

if ! (dpkg -l | grep -iq equivs); then
  echo "[!] The 'equivs' package does not appear to be installed, quitting..."
  exit 1
fi

if ! (dpkg -l | grep -iq debsigs); then
  echo "[!] The 'debsigs' package does not appear to be installed, quitting..."
  exit 1
fi

echo "[*] Building packages"
for file in $(ls -1 equivs/*.cfg)
do
  echo "  - $file"
  equivs-build $file > /dev/null
done

if test -n "$(find . -maxdepth 1 -name '*.deb' -print -quit)"; then
  echo "[*] Signing packages"
  for file in $(ls -1 *.deb)
  do
    echo "  - $file"
    debsigs --sign=origin -k $PUBLIC_KEY $file
  done

  echo "[*] Generating Packages and Packages.gz files"
  mkdir -p {i386,amd64}
  apt-ftparchive --arch i386 packages . | tee i386/Packages | gzip > i386/Packages.gz
  apt-ftparchive --arch amd64 packages . | tee i386/Packages | gzip > i386/Packages.gz

  echo "[*] Generating the Release file"
  apt-ftparchive release i386 > i386/Release
  apt-ftparchive release amd64 > amd64/Release

  echo "[*] Sign Release file"
  gpg --yes --armor --local-user $PUBLIC_KEY --output i386/Release.gpg --detach-sig i386/Release
  gpg --yes --armor --local-user $PUBLIC_KEY --output amd64/Release.gpg --detach-sig amd64/Release

  echo "[*] Generate InRelease file"
  gpg --yes --clearsign --local-user $PUBLIC_KEY --output i386/InRelease i386/Release
  gpg --yes --clearsign --local-user $PUBLIC_KEY --output amd64/InRelease amd64/Release

  #echo "[*] Exporting repository gpg public key to file"
  gpg --armor --export CAE172DB > repository.pub

  echo "[*] Add the following line to /etc/apt/sources/list ..."
  echo ""
  echo "deb [trusted=yes] file://$(pwd) i386/"
  echo "  - or -"
  echo "deb [trusted=yes] file://$(pwd) amd64/"
else
  echo "[!] No deb packages found, quitting..."
  exit 1
fi

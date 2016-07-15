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

echo "[*] Building meta packages"
for file in $(ls -1 equivs/*.cfg)
do
  echo "  - $file"
  cd packages
  equivs-build ../$file > /dev/null
  cd ..
done

if test -n "$(find ./packages/ -maxdepth 1 -name '*.deb' -print -quit)"; then
  echo "[*] Signing packages"
  for file in $(ls -1 packages/*.deb)
  do
    echo "  - $file"
    debsigs --sign=origin -k $PUBLIC_KEY $file
  done

  echo "[*] Generating Packages and Packages.gz files"
  mkdir -p {i386,amd64}
  apt-ftparchive --arch i386 packages ./packages/ /dev/null packages | tee i386/Packages | gzip > i386/Packages.gz
  apt-ftparchive --arch amd64 packages ./packages/ /dev/null packages | tee amd64/Packages | gzip > amd64/Packages.gz

  echo "[*] Generating the Release file"
  apt-ftparchive release i386 > i386/Release
  apt-ftparchive release amd64 > amd64/Release

  echo "[*] Signing the Release file"
  gpg --yes --armor --local-user $PUBLIC_KEY --output i386/Release.gpg --detach-sig i386/Release
  gpg --yes --armor --local-user $PUBLIC_KEY --output amd64/Release.gpg --detach-sig amd64/Release

  echo "[*] Generating the InRelease file"
  gpg --yes --clearsign --local-user $PUBLIC_KEY --output i386/InRelease i386/Release
  gpg --yes --clearsign --local-user $PUBLIC_KEY --output amd64/InRelease amd64/Release

  echo "[*] Exporting the gpg public key for the repository to a file"
  gpg --armor --export CAE172DB > repository.key

  echo ""
  echo "[+] Run these commands to add this repostory to your apt source list:"
  echo ""
  echo "echo \"deb file://$(pwd) i386/\" > /etc/apt/sources.list.d/local.list"
  echo ""
  echo "  - or -"
  echo ""
  echo "echo \"deb file://$(pwd) amd64/\" > /etc/apt/sources.list.d/local.list"
  echo ""
  echo "[+] Import the repository public GPG key:"
  echo ""
  echo "apt-key add $(pwd)/repository.key"
  echo ""
  echo "[+] Update apt index to recognise the new repo:"
  echo ""
  echo "apt update"
  echo ""
else
  echo "[!] No deb packages found, quitting..."
  exit 1
fi

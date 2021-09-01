#!/data/data/com.termux/files/usr/bin/bash

export DIALOGOPTS="--clear --colors --no-collapse"
export DIALOG_OK=0
export DIALOG_CANCEL=1
export DIALOG_HELP=2
export DIALOG_ESC=255

if [[ $# -gt 0 ]]; then
  echo "Manjaroid: No arguments required." >&2
  exit 1
elif [[ ${arch:="$(uname -m)"} != "aarch64" ]]; then
  echo "Manjaroid: Incompatible device architecture (${arch})."
  exit 2
elif ! command -v proot pv pulseaudio>/dev/null; then
  if (dialog --title "Manjaroid dependencies" --yesno "Missing required package(s). Do you want to install them?" -1 -1); then
    while true; do
      pkg install -y proot pv pulseaudio 2>&1 | dialog --title "Manjaroid dependencies" --progressbox "Installing missing package(s)..." -1 -1
      status=${PIPESTATUS[0]}
      if [[ ${status} != 0 ]]; then
        if (dialog --title "Manjaroid dependencies" --yesno "An error occurred (${status}). Do you want to try again?" -1 -1); then
          continue
        fi
        exit ${status}
      fi
      break
    done
  else
    exit
  fi
fi

chroot() {
  while true; do
    directory="${1:-$(dialog --stdout --help-button --title "Manjaroid chroot" --dselect "$(pwd)/manjaro" -1 -1)}"
    status=$?
    if [[ ${status} = ${DIALOG_CANCEL} || ${status} = ${DIALOG_ESC} ]]; then
      main_menu
    elif [[ ${status} = ${DIALOG_OK} && -z "${directory}" ]]; then
      dialog --title "Manjaroid chroot" --msgbox "Empty rootfs path. Please try again." -1 -1
      continue
    elif [[ ${status} = ${DIALOG_OK} && ! -d "${directory}" ]]; then
      dialog --title "Manjaroid chroot" --msgbox "Invalid rootfs path. Please try again." -1 -1
      continue
    elif [[ ${status} = ${DIALOG_HELP} ]]; then
      dialog --title "Manjaroid chroot" --msgbox "Specify the path containing a valid rootfs to chroot into." -1 -1
      continue
    fi
    break
  done
  pulseaudio --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 --start
  unset LD_PRELOAD
  exec proot --kill-on-exit -l -0 \
    -r "${directory}" \
    -b /dev \
    -b /proc \
    -b "${directory}/root:/dev/shm" \
    -b /sdcard \
    -w /root \
    /usr/bin/env -i \
    PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/games:/usr/games \
    HOME=/root \
    TERM="${TERM}" \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US \
    LC_ALL=C \
    /bin/bash --login
}

setup() {
chmod -cf 755 $(find "${directory:=$1}" -type d) 2>&1 | dialog --title "Manjaroid setup" --progressbox "Changing default directory permissions..." -1 -1

while true; do
  username="$(dialog --stdout --title "Manjaroid setup" --inputbox "Please specify a new username:" -1 -1)"
  status=$?
  if [[ ${status} = ${DIALOG_CANCEL} || ${status} = ${DIALOG_ESC} ]]; then
    continue 2
  elif [[ ${status} = ${DIALOG_OK} && -z ${username} ]]; then
    dialog --title "Manjaroid setup" --msgbox "Username cannot be empty. Please try again." -1 -1
    continue
  fi
  password="$(dialog --stdout --insecure --title "Manjaroid setup" --passwordbox "Please specify a password for '${username}':" -1 -1)"
  status=$?
  if [[ ${status} = ${DIALOG_CANCEL} || ${status} = ${DIALOG_ESC} ]]; then
    continue
  elif [[ ${status} = ${DIALOG_OK} && -z ${password} ]]; then
    dialog --title "Manjaroid setup" --msgbox "Password cannot be empty. Please try again." -1 -1
    continue
  fi
  break 2
done

cat >"${directory}/root/.bash_profile" <<- .
## Fix common directory permissions
chmod -cf 750 /root /usr/share/polkit-1/rules.d
chmod -cf 775 /var/games
chmod -cf 555 /srv/ftp /sys
chmod -cf 1777 /tmp /var/spool/mail /var/tmp
chmod -cf 2755 /var/log/journal
.
if [[ ! -z ${edition} ]]; then
  manjaro_packages="https://gitlab.manjaro.org/manjaro-arm/applications/arm-profiles/-/raw/master/editions/${edition}?inline=false"
  manjaro_services="https://gitlab.manjaro.org/manjaro-arm/applications/arm-profiles/-/raw/master/services/${edition}?inline=false"
  manjaro_overlays="https://gitlab.manjaro.org/manjaro-arm/applications/arm-profiles/-/archive/master/arm-profiles-master.tar?path=overlays/${edition}"
  cat >>"${directory}/root/.bash_profile" <<- .
## Install profile packages
## Already installed
#packages=(\$(curl -sL "${manjaro_packages}" | sed -e 's/\\s*#.*//;/^\\s*$/d;s/\\s*$//'))
#for package in \$(pacman -Sp "\${packages[@]}" 2>&1 | grep -Po '[^\\s]*$'); do
#  packages=(\${packages[@]/\${package}})
#done
#pacman -S --needed --noconfirm \${packages[@]}

## Enable profile services (optional)
for service in \$(curl -sL "${manjaro_services}"); do
  systemctl enable \${service}
done

## Install profile overlays
curl -sL "${manjaro_overlays}" | \\
  tar -xvf - -C / --wildcards --exclude='overlay.txt' \\
  arm-profiles-master-overlays-${edition}/overlays/${edition}/* --strip 3
.
fi
cat >>"${directory}/root/.bash_profile" <<- .
## Miscellaneous setup
paccache -rk0
chmod -cf 755 /etc /etc/fonts /usr /usr/share /usr/share/icons
mkdir -p /etc/skel/.config
echo "--no-sandbox" >"/etc/skel/.config/chromium-flags.conf"
.
cat >>"${directory}/root/.bash_profile" <<- .
## Add new user account
useradd -m -G wheel -s /bin/bash ${username}
echo "${username}:${password}" | chpasswd
sed -i -e "/root ALL=(ALL) ALL/a ${username} ALL=(ALL) ALL" \\
  -e "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers
chown ${username}:${password} /usr/bin/sudo && chmod 4755 /usr/bin/sudo

## ARM profiles
cp -r /etc/skel/.config $HOME

echo "exec su - ${username}" >/root/.bash_profile
bash /root/.bash_profile
.
}

install() {
  while true; do
    directory="$(dialog --stdout --help-button --title "Manjaroid install" --dselect "$(pwd)/manjaro" -1 -1)"
    status=$?
    if [[ ${status} = ${DIALOG_CANCEL} || ${status} = ${DIALOG_ESC} ]]; then
      main_menu
    elif [[ ${status} = ${DIALOG_OK} && -d "${directory}" ]]; then
      if (dialog --title "Manjaroid install" --yesno "Path '${directory}' already exist. Do you want to remove it first?" -1 -1); then
        chmod -Rcf 777 "${directory}" 2>&1 | dialog --title "Manjaroid install" --progressbox "Changing permissions of '${directory}'..." -1 -1
        rm -rvf ${directory} 2>&1 | dialog --title "Manjaroid install" --progressbox "Removing '${directory}'..." -1 -1
      fi
    elif [[ ${status} = ${DIALOG_OK} && -z "${directory}" ]]; then
      dialog --title "Manjaroid install" --msgbox "Empy installation path. Please try again." -1 -1
      continue
    elif [[ ${status} = ${DIALOG_HELP} ]]; then
      dialog --title "Manjaroid install" --msgbox "Specify the Manjaro rootfs installation path." -1 -1
      continue
    fi
    mkdir -p "${directory}" 2>&1 >/dev/null
    manjaro_rootfs="https://github.com/infinyte7/manjaro-fs-arm64/releases/download/v0.0.6-manjaro-rootfs/manjaro-rootfs-latest.tar.gz"
    size=$(curl -sLI "${manjaro_rootfs}" | awk '/content-length/ {printf "%i", ($2/1024)/1024}')
    (curl -sL "${manjaro_rootfs}" | pv -ns "${size}m" - | proot -l tar -xzf - -C "${directory}") 2>&1 | \
      dialog --title "Manjaroid install" --gauge "Installing Manjaro (${size}MB)..." -1 -1
    status=${PIPESTATUS[0]}
    if [[ ${status} != 0 ]]; then
      dialog --title "Manjaroid install" --msgbox "An error occurred (${status}). Please try again." -1 -1
      continue
    fi
    echo nameserver 8.8.8.8 > "${directory}/etc/resolv.conf"
    setup "${directory}"
    chroot "${directory}"
  done
}

remove() {
  while true; do
    directory="$(dialog --stdout --help-button --title "Manjaroid remove" --dselect "$(pwd)/manjaro" -1 -1)"
    status=$?
    if [[ ${status} = ${DIALOG_CANCEL} || ${status} = ${DIALOG_ESC} ]]; then
      main_menu
    elif [[ ${status} = ${DIALOG_OK} && -z "${directory}" ]]; then
      dialog --title "Manjaroid remove" --msgbox "Empty rootfs path. Please try again." -1 -1
      continue
    elif [[ ${status} = ${DIALOG_HELP} ]]; then
      dialog --title "Manjaroid remove" --msgbox "Specify the path containing a valid rootfs to remove." -1 -1
      continue
    fi
    if (dialog --title "Manjaroid remove" --yesno "Are you sure you want to remove '${directory}'?" -1 -1); then
      chmod -Rcf 777 "${directory}" 2>&1 | dialog --title "Manjaroid remove" --progressbox "Changing permissions of '${directory}'..." -1 -1
      rm -rvf ${directory} 2>&1 | dialog --title "Manjaroid remove" --progressbox "Removing '${directory}'..." -1 -1
    fi
  done
}

main_menu() {
  while true; do
    menu="$(dialog --stdout --help-button --title "Manjaroid main menu" \
      --menu "Please select an action to perform:" -1 -1 0 \
      1 "Chroot into an existing rootfs" \
      2 "Install the latest rootfs" \
      3 "Remove an existing rootfs")"
    status=$?
    if [[ ${status} = ${DIALOG_CANCEL} || ${status} = ${DIALOG_ESC} ]]; then
      exit ${status}
    elif [[ ${status} = ${DIALOG_OK} && ${menu} = 1 ]]; then
      chroot
    elif [[ ${status} = ${DIALOG_OK} && ${menu} = 2 ]]; then
      install
    elif [[ ${status} = ${DIALOG_OK} && ${menu} = 3 ]]; then
      remove
    elif [[ ${status} = ${DIALOG_HELP} && ${menu} = "HELP 1" ]]; then
      dialog --title "Manjaroid main menu" --msgbox "Performs a chroot into the target directory containing a valid rootfs." -1 -1
      continue
    elif [[ ${status} = ${DIALOG_HELP} && ${menu} = "HELP 2" ]]; then
      dialog --title "Manjaroid main menu" --msgbox "Performs an installation of the latest Manjaro rootfs." -1 -1
      continue
    elif [[ ${status} = ${DIALOG_HELP} && ${menu} = "HELP 3" ]]; then
      dialog --title "Manjaroid main menu" --msgbox "Performs a full \Zb777\Zn permission change to the target directory and completely remove it." -1 -1
      continue
    fi
  done
}

main_menu

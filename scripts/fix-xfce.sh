edition="xfce"

manjaro_packages="https://gitlab.manjaro.org/manjaro-arm/applications/arm-profiles/-/raw/master/editions/${edition}?inline=false"
manjaro_services="https://gitlab.manjaro.org/manjaro-arm/applications/arm-profiles/-/raw/master/services/${edition}?inline=false"
manjaro_overlays="https://gitlab.manjaro.org/manjaro-arm/applications/arm-profiles/-/archive/master/arm-profiles-master.tar?path=overlays/${edition}"

## Install profile packages
packages=($(curl -sL "${manjaro_packages}" | sed -e 's/\s*#.*//;/^\s*$/d;s/\s*$//'))
for package in $(pacman -Sp "${packages[@]}" 2>&1 | grep -Po '[^\s]*$'); do
  packages=(${packages[@]/${package}})
done
pacman -S --needed --noconfirm ${packages[@]}

## Enable profile services (optional)
for service in $(curl -sL "${manjaro_services}"); do
  systemctl enable ${service}
done

## Install profile overlays
curl -sL "${manjaro_overlays}" | \
  tar -xvf - -C / --wildcards --exclude='overlay.txt' \
  arm-profiles-master-overlays-${edition}/overlays/${edition}/* --strip 3

## Copy ARM profiles
cp -r /etc/skel/.config $HOME
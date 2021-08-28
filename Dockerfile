## Create rootfs from scratch
FROM scratch
ADD . /
RUN uname -a

## Update and install the base and sudo packages
## RUN pacman-mirrors -gf
RUN pacman-mirrors --country Germany,France,Austria
RUN pacman-key --init
RUN pacman-key --populate
RUN pacman -Syyuu --noconfirm base sudo manjaro-release

## Setup xfce4
RUN manjaro_packages="https://gitlab.manjaro.org/manjaro-arm/applications/arm-profiles/-/raw/master/editions/Xfce?inline=false"
RUN manjaro_services="https://gitlab.manjaro.org/manjaro-arm/applications/arm-profiles/-/raw/master/services/Xfce?inline=false"
RUN manjaro_overlays="https://gitlab.manjaro.org/manjaro-arm/applications/arm-profiles/-/archive/master/arm-profiles-master.tar?path=overlays/Xfce"

RUN packages=(\$(curl -sL "${manjaro_packages}" | sed -e 's/\\s*#.*//;/^\\s*$/d;s/\\s*$//')) \
    for package in \$(pacman -Sp "\${packages[@]}" 2>&1 | grep -Po '[^\\s]*$'); do \
    packages=(\${packages[@]/\${package}}) \
    done \
    pacman -S --needed --noconfirm \${packages[@]} \
    ## Enable profile services (optional) \
    for service in \$(curl -sL "${manjaro_services}"); do \
      systemctl enable \${service} \
    done \
    ## Install profile overlays \
    curl -sL "${manjaro_overlays}" | \\\
    tar -xvf - -C / --wildcards --exclude='overlay.txt' \\\
    arm-profiles-master-overlays-${edition}/overlays/${edition}/* --strip 3

## Install TigerVNC 10.1.1
RUN pacman -S tar wget sed --noconfirm

COPY ../tigervnc/tigervnc-1.10.1-1-aarch64.pkg.tar.xz /
COPY ../tigervnc/lib.tar.xz /usr/lib/a.tar.xz

RUN pacman -U /tigervnc-1.10.1-1-aarch64.pkg.tar.xz --noconfirm
RUN tar xf /usr/lib/a.tar.xz -C /usr/lib
RUN sed -i '27i IgnorePkg = tigervnc' /etc/pacman.conf

RUN rm /tigervnc-1.10.1-1-aarch64.pkg.tar.xz

## Setup TigerVNC
RUN mkdir -p /etc/skel/.vnc
RUN echo "#!/bin/sh\n" >> /etc/skel/.vnc/xstartup
RUN echo "unset SESSION_MANAGER\n" >> /etc/skel/.vnc/xstartup
RUN echo "export DISPLAY=:1" >> /etc/skel/.vnc/xstartup
RUN echo "export PULSE_SERVER=127.0.0.1" >> /etc/skel/.vnc/xstartup
RUN echo "pulseaudio --start\n" >> /etc/skel/.vnc/xstartup
RUN echo "[[ -r \${HOME}/.Xresources ]] && xrdb \${HOME}/.Xresources" >> /etc/skel/.vnc/xstartup
RUN echo "exec dbus-launch startxfce4" >> /etc/skel/.vnc/xstartup
RUN chmod -cf +x /etc/skel/.vnc/xstartup

RUN echo "Desktop=manjaro\n" >> /etc/skel/.vnc/config
RUN echo "Geometry=1024x768\n" >> /etc/skel/.vnc/config
RUN echo "SecurityTypes=VncAuth,TLSVnc\n" >> /etc/skel/.vnc/config
RUN echo "Localhost" >> /etc/skel/.vnc/config

COPY ../tigervnc/vncserver-start /usr/local/bin/vncserver-start
COPY ../tigervnc/vncserver-stop /usr/local/bin/vncserver-stop
RUN chmod +x /usr/local/bin/vncserver-start
RUN chmod +x /usr/local/bin/vncserver-stop

RUN echo password | vncpasswd > $HOME/.vnc/passwd
RUN chmod 400 $HOME/.vnc/passwd

## Add new user account
RUN useradd -m -G wheel -s /bin/bash manjaro
RUN echo "manjaro:manjaro" | chpasswd
RUN sed -i -e "/root ALL=(ALL) ALL/a manjaro ALL=(ALL) ALL" -e "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers
RUN bash /root/.bash_profile
RUN echo "exec su - manjaro" > /root/.bash_profile
RUN bash /root/.bash_profile
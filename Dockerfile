## Create rootfs from scratch
FROM scratch
ADD . /
RUN uname -a

## Update and install the base and sudo packages
## RUN pacman-mirrors -gf
RUN pacman-mirrors --country Germany,France,Austria \
    && pacman-key --init \
    && pacman-key --populate \
    && pacman -Syyuu --noconfirm base sudo manjaro-release

## Setup xfce4
RUN pacman -S tar wget sed --noconfirm
RUN bash /setup.sh

## Install TigerVNC 10.1.1
RUN pacman -U /tigervnc-1.10.1-1-aarch64.pkg.tar.xz --noconfirm
RUN tar xf /usr/lib/a.tar.xz -C /usr/lib
RUN sed -i '27i IgnorePkg = tigervnc' /etc/pacman.conf

## Setup TigerVNC
RUN mkdir -p /etc/skel/.vnc \
    && echo "#!/bin/sh\n" >> /etc/skel/.vnc/xstartup \
    && echo "unset SESSION_MANAGER\n" >> /etc/skel/.vnc/xstartup \
    && echo "export DISPLAY=:1" >> /etc/skel/.vnc/xstartup \
    && echo "export PULSE_SERVER=127.0.0.1" >> /etc/skel/.vnc/xstartup \
    && echo "pulseaudio --start\n" >> /etc/skel/.vnc/xstartup \
    && echo "[[ -r \${HOME}/.Xresources ]] && xrdb \${HOME}/.Xresources" >> /etc/skel/.vnc/xstartup \
    && echo "exec dbus-launch startxfce4" >> /etc/skel/.vnc/xstartup \
    && chmod -cf +x /etc/skel/.vnc/xstartup

RUN echo "Desktop=manjaro\n" >> /etc/skel/.vnc/config \
    && echo "Geometry=1024x768\n" >> /etc/skel/.vnc/config \
    && echo "SecurityTypes=VncAuth,TLSVnc\n" >> /etc/skel/.vnc/config \
    && echo "Localhost" >> /etc/skel/.vnc/config \

    && chmod +x /usr/local/bin/vncserver-start \
    && chmod +x /usr/local/bin/vncserver-stop \

## Add new user account
RUN useradd -m -G wheel -s /bin/bash manjaro \
    && echo "manjaro:manjaro" | chpasswd \
    && sed -i -e "/root ALL=(ALL) ALL/a manjaro ALL=(ALL) ALL" -e "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers \
    && echo "exec su - manjaro" > /root/.bash_profile

## Setup vnc password
RUN mkdir $HOME/.vnc \
    && echo password | vncpasswd -f > $HOME/.vnc/passwd \
    && chown -R manjaro:manjaro  $HOME/.vnc \
    && chmod 400 $HOME/.vnc/passwd
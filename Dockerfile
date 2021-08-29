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
RUN pacman -S tar wget sed --noconfirm
COPY ../setup/setup.sh .
RUN bash setup.sh

## Install TigerVNC 10.1.1
RUN pacman -U /tigervnc-1.10.1-1-aarch64.pkg.tar.xz --noconfirm
RUN tar xf /usr/lib/a.tar.xz -C /usr/lib
RUN sed -i '27i IgnorePkg = tigervnc' /etc/pacman.conf

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

RUN chmod +x /usr/local/bin/vncserver-start
RUN chmod +x /usr/local/bin/vncserver-stop

## Add new user account
RUN useradd -m -G wheel -s /bin/bash manjaro
RUN echo "manjaro:manjaro" | chpasswd
RUN sed -i -e "/root ALL=(ALL) ALL/a manjaro ALL=(ALL) ALL" -e "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers
RUN echo "exec su - manjaro" > /root/.bash_profile

## Setup vnc password
RUN mkdir $HOME/.vnc
RUN echo password | vncpasswd -f > $HOME/.vnc/passwd
RUN chown -R manjaro:manjaro  $HOME/.vnc
RUN chmod 400 $HOME/.vnc/passwd
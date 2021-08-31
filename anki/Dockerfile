## Create rootfs from scratch
FROM scratch
ADD . /
RUN uname -a

## Update and install the base and sudo packages
## RUN pacman-mirrors -gf
RUN pacman-mirrors --country Germany,France,Austria \
&& pacman-key --init \
&& pacman-key --populate

## Fix common directory permissions
RUN chmod -cf 775 /var/games 2>/dev/null \
&& chmod -cf 1777 /tmp /var/spool/mail /var/tmp 2>/dev/null \
&& chmod -cf 2755 /var/log/journal 2>/dev/null

RUN pacman -Syyuu --noconfirm base sudo manjaro-release

## Install DE and vnc
RUN pacman -Sy --noconfirm --needed xfce4

## Install TigerVNC 1.10.1
RUN pacman -S tar wget sed --noconfirm \
&& pacman -U /tigervnc-1.10.1-1-aarch64.pkg.tar.xz --noconfirm \
&& tar xf /usr/lib/a.tar.xz -C /usr/lib \
&& sed -i '27i IgnorePkg = tigervnc' /etc/pacman.conf \
&& rm /tigervnc-1.10.1-1-aarch64.pkg.tar.xz

## Setup TigerVNC
RUN mkdir -p /etc/skel/.vnc \
&& echo "#!/bin/sh" >> /etc/skel/.vnc/xstartup \
&& echo "unset SESSION_MANAGER" >> /etc/skel/.vnc/xstartup \
&& echo "export DISPLAY=:1" >> /etc/skel/.vnc/xstartup \
&& echo "export PULSE_SERVER=127.0.0.1" >> /etc/skel/.vnc/xstartup \
&& echo "pulseaudio --start" >> /etc/skel/.vnc/xstartup \
&& echo "[[ -r \${HOME}/.Xresources ]] && xrdb \${HOME}/.Xresources" >> /etc/skel/.vnc/xstartup \
&& echo "startxfce4 &" >> /etc/skel/.vnc/xstartup \
&& chmod -cf +x /etc/skel/.vnc/xstartup \

&& echo "Desktop=manjaro" >> /etc/skel/.vnc/config \
&& echo "Geometry=1024x768" >> /etc/skel/.vnc/config \
&& echo "SecurityTypes=VncAuth,TLSVnc" >> /etc/skel/.vnc/config \
&& echo "Localhost" >> /etc/skel/.vnc/config \

&& chmod +x /usr/local/bin/vncserver-start \
&& chmod +x /usr/local/bin/vncserver-stop

## Install Packages required by Anki
RUN pacman -Sy --noconfirm --needed python-pyqt5 python-pyqtwebengine python-pip

## Install Anki
RUN pip install https://github.com/infinyte7/anki-arm64/releases/download/v0.0.1-archarm/anki-2.1.47-cp38-abi3-manylinux2014_aarch64.whl
RUN pip install https://github.com/infinyte7/anki-arm64/releases/download/v0.0.1-archarm/aqt-2.1.47-py3-none-any.whl

RUN mv anki.desktop /usr/share/applications/anki.desktop \
&& mv anki.png /usr/share/pixmaps/anki.png
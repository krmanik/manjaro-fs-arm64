# manjaro-fs

Manjaro rootfs with `xfce4` and `vncserver` preinstalled. Just setup username, password and vnc password.

# QuickStart

## Manjaro arm64 with xfce4, xfce4-goodies and tigervnc
```
pkg install wget && wget https://raw.githubusercontent.com/infinyte7/manjaro-fs-arm64/main/manjaro.sh && chmod +x manjaro.sh && ./manjaro.sh
```

## Install Anki with Manjaro (xfce4 only, latest Anki and tigervnc)
```
pkg install wget && wget https://raw.githubusercontent.com/infinyte7/manjaro-fs-arm64/main/install_anki.sh && chmod +x install_anki.sh && ./install_anki.sh
```

# How to setup manually it in termux?
1. Download the manjaro rootfs from release page
```
wget <tar.gz url from relese>
```

2. Extract the `manjaro-rootfs-latest.tar.gz` into `manjaro` folder. Note: folder name must be `manjaro`
```
mkdir manjaro
proot -l tar -xzf manjaro-rootfs-latest.tar.gz -C manjaro
```
3. Use `manjaro.sh` to proot into manjaro rootfs
```
wget 
chmod +x manjaro.sh
./manjaro.sh
```

## In Manjaro proot
1. Setup username and password

2. Setup vnc password
```
vncpasswd
```

3. Run vncserver
```
vncserver-start
```

4. Stop vncserver
```
vncserver-stop
```


# Faq ?
1. Manjaro theme is not applied?

Run following commands to reset to default Manjaro look.
```
cp -r /etc/skel/.config/xfce4/panel $HOME/.config/xfce4/panel
cp /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
```

# License and Credits
- [AndronixOrigin](https://github.com/AndronixApp/AndronixOrigin)<br>
    MIT License
- ItsMeKuroro<br>
[https://forum.manjaro.org](https://archived.forum.manjaro.org/t/how-to-run-the-official-manjaro-arm-edition-on-android-with-chroot-environment/151429)
- [undocker](http://github.com/larsks/undocker)<br>
    GPL v3
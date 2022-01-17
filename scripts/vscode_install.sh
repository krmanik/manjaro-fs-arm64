mkdir /opt/vscode
cd /opt
wget https://az764295.vo.msecnd.net/stable/899d46d82c4c95423fb7e10e68eba52050e30ba3/code-stable-arm64-1639561407.tar.gz
tar xf /opt/code-stable-arm64-1639561407.tar.gz -C /opt/vscode/ --strip-components=1
rm -rf code-stable-arm64-1639561407.tar.gz
echo -e "alias code='/opt/vscode/code --no-sandbox'" >> ~/.bashrc
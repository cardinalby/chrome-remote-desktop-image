FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

# INSTALL SOURCES FOR CHROME REMOTE DESKTOP AND VSCODE
RUN apt-get update && apt-get upgrade --assume-yes
RUN apt-get --assume-yes install curl gpg wget
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | \
   tee /etc/apt/sources.list.d/vs-code.list
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
# INSTALL XFCE DESKTOP AND DEPENDENCIES
RUN apt-get update && apt-get upgrade --assume-yes
RUN apt-get install --assume-yes --fix-missing sudo wget apt-utils xvfb xfce4 xbase-clients \
    desktop-base vim xscreensaver google-chrome-stable python-psutil psmisc python3-psutil xserver-xorg-video-dummy ffmpeg
RUN apt-get install --assume-yes python3-packaging python3-xdg
RUN apt-get install libutempter0
RUN wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
RUN dpkg --install chrome-remote-desktop_current_amd64.deb
RUN apt-get install --assume-yes --fix-broken
RUN bash -c 'echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session'

RUN apt-get install --assume-yes firefox
# ---------------------------------------------------------- 
# SPECIFY VARIABLES FOR SETTING UP CHROME REMOTE DESKTOP
ARG USER=myuser
# use 6 digits at least
ENV PIN=123456
ENV CODE=4/xxx
ENV HOSTNAME=myvirtualdesktop
# ---------------------------------------------------------- 
# ADD USER TO THE SPECIFIED GROUPS
RUN adduser --disabled-password --gecos '' $USER
RUN mkhomedir_helper $USER
RUN adduser $USER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN usermod -aG chrome-remote-desktop $USER
USER $USER
WORKDIR /home/$USER
RUN mkdir -p .config/chrome-remote-desktop
RUN chown "$USER:$USER" .config/chrome-remote-desktop
RUN chmod a+rx .config/chrome-remote-desktop
RUN touch .config/chrome-remote-desktop/host.json
RUN echo "/usr/bin/pulseaudio --start" > .chrome-remote-desktop-session
RUN echo "startxfce4 :1030" >> .chrome-remote-desktop-session
CMD \
   DISPLAY= /opt/google/chrome-remote-desktop/start-host --code=$CODE --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$HOSTNAME --pin=$PIN ; \
   HOST_HASH=$(echo -n $HOSTNAME | md5sum | cut -c -32) && \
   FILENAME=.config/chrome-remote-desktop/host#${HOST_HASH}.json && echo $FILENAME && \
   cp .config/chrome-remote-desktop/host#*.json $FILENAME ; \
   sudo service chrome-remote-desktop stop && \
   sudo service chrome-remote-desktop start && \
   echo $HOSTNAME && \
   sleep infinity & wait

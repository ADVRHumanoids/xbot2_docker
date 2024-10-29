FROM ros:noetic-robot-focal

# install all dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \ 
    bash-completion \
    build-essential \ 
    cmake \ 
    file \ 
    git \ 
    python3-pip  \
    sudo \ 
    libboost-dev \ 
    libyaml-cpp-dev \ 
    cmake-curses-gui \
    wget \
    terminator \
    vim \
    mercurial \
    libmatio-dev \
    imagemagick \ 
    libtinyxml-dev \ 
    qt5-default \ 
    qttools5-dev \ 
    qtquickcontrols2-5-dev \ 
    qtdeclarative5-dev

# add xbot2 experimental source and keys
RUN sh -c 'echo "deb http://xbot.cloud/xbot2/ubuntu/focal /" > /etc/apt/sources.list.d/xbot.list'
RUN wget -q -O - http://xbot.cloud/xbot2/ubuntu/KEY.gpg | apt-key add -

# install dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \ 
    gazebo11 \ 
    libgazebo11-dev \ 
    ros-${ROS_DISTRO}-interactive-markers \ 
    ros-${ROS_DISTRO}-tf2-eigen \ 
    ros-${ROS_DISTRO}-rviz \ 
    ros-${ROS_DISTRO}-moveit-core \ 
    ros-${ROS_DISTRO}-rosmon \ 
    ros-${ROS_DISTRO}-gazebo-ros-pkgs \ 
    xbot2_desktop_full

# install python modules for backtrace pretty printer
RUN pip3 install parse ansicolors notebook hhcm-forest

# create a regular user
RUN useradd -ms /bin/bash user
RUN adduser user sudo
RUN echo 'user:user' | chpasswd

WORKDIR /home/user

# bashrc
RUN cp /etc/skel/.bashrc .
RUN bash -c "echo source /opt/ros/noetic/setup.bash >> /home/user/.bashrc"
RUN bash -c "echo source /opt/xbot/setup.sh >> /home/user/.bashrc"
RUN bash -c "echo alias notebook_docker=\'jupyter notebook --no-browser --ip=0.0.0.0\' >> /home/user/.bashrc"

# set ownership to user for the whole home folder
RUN chown -R user .

# change user
USER user

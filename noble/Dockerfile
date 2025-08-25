FROM ros:jazzy-perception-noble 

ARG USER_ID=1000

# delete ubuntu user
RUN sudo userdel ubuntu

# create a regular user, switch to it, cd to its home
RUN useradd -u ${USER_ID} -ms /bin/bash user
RUN adduser user sudo
RUN echo 'user:user' | chpasswd
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER user

ENV DEBIAN_FRONTEND=noninteractive

# otherwise autocompletion is broken with apt
RUN sudo rm /etc/apt/apt.conf.d/docker-clean



# go full ros2
RUN sudo apt-get update && sudo apt-get install -y \
    ros-$ROS_DISTRO-desktop-full \
    ros-$ROS_DISTRO-moveit \
    ros-$ROS_DISTRO-velodyne \ 
    ros-$ROS_DISTRO-velodyne-description \
    ros-$ROS_DISTRO-realsense2-description \
    ros-$ROS_DISTRO-tf-transformations \
    ros-$ROS_DISTRO-rmw-cyclonedds-cpp \
    && sudo apt-get clean

# install useful sw
RUN sudo apt-get update && sudo apt-get install -y \
    vim  \ 
    wget \
    bash-completion \
    terminator \
    libxcb-cursor-dev \
    python3-venv python3-pip \
    openssh-client \
    gedit \
    libboost-test-dev libboost-filesystem-dev libboost-timer-dev libboost-tools-dev  \
    cmake-curses-gui \
    gitg git-gui \
    clang \
    locate \
    gdb \
    kmod \
    file \
    && sudo apt-get clean

# add xbot2 source and keys
RUN sudo sh -c 'echo "deb http://xbot.cloud/xbot2-nightly/ubuntu/noble /" > /etc/apt/sources.list.d/xbot.list'
RUN wget -q -O - http://xbot.cloud/xbot2/ubuntu/KEY.gpg | sudo apt-key add -

RUN sudo apt-get update && sudo apt-get install -y xbot2_desktop_full

WORKDIR /home/user

SHELL [ "/bin/bash", "-ic" ]

# source ros
RUN echo source /opt/ros/$ROS_DISTRO/setup.bash >> .bashrc

# venv for python
RUN python3 -m venv --system-site-packages env 
RUN echo source ~/env/bin/activate >> .bashrc

# pip deps
RUN pip install setuptools
RUN pip install hhcm-forest

# ros2 configuration (cyclonedds, custom sysctl rules, ...)
RUN echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> /home/user/.bashrc

CMD ["/bin/bash"]

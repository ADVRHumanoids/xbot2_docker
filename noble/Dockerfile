FROM ros:jazzy-perception-noble 

ARG USER_ID

# delete ubuntu user
RUN sudo userdel ubuntu

# create a regular user, switch to it, cd to its home
RUN useradd -u ${USER_ID} -ms /bin/bash user
RUN adduser user sudo
RUN echo 'user:user' | chpasswd
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER user

# tty, video, from regular user
RUN sudo usermod -a -G dialout,video,plugdev user

# set non interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# otherwise autocompletion is broken with apt
RUN sudo rm /etc/apt/apt.conf.d/docker-clean

# add xbot2 source and keys
RUN sudo apt-get update && sudo apt-get install -y wget gnupg && \
    sudo sh -c 'echo "deb http://xbot.cloud/xbot2-nightly/ubuntu/noble /" > /etc/apt/sources.list.d/xbot.list' && \
    wget -q -O - http://xbot.cloud/xbot2/ubuntu/KEY.gpg | sudo apt-key add - && \
    sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*

# go full ros2
RUN sudo apt-get update && sudo apt-get install -y \
    ros-$ROS_DISTRO-desktop-full \
    ros-$ROS_DISTRO-moveit \
    ros-$ROS_DISTRO-velodyne \ 
    ros-$ROS_DISTRO-velodyne-description \
    ros-$ROS_DISTRO-realsense2-description \
    ros-$ROS_DISTRO-tf-transformations \
    ros-$ROS_DISTRO-rmw-cyclonedds-cpp \
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
    xbot2_desktop_full \
    && sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*

# switch to interactive shell for sourcing ros and venv
WORKDIR /home/user
SHELL [ "/bin/bash", "-ic" ]

# source ros
RUN echo source /opt/ros/$ROS_DISTRO/setup.bash >> .bashrc

# venv for python
RUN python3 -m venv --system-site-packages env 
RUN echo source ~/env/bin/activate >> .bashrc

# pip deps (check forest version to be 1.1.23 or higher)
RUN pip install setuptools hhcm-forest && \
    python3 -c "from importlib.metadata import version; from packaging.version import Version; v = version('hhcm-forest'); assert Version(v) >= Version('1.1.23'), f'hhcm-forest {v} < 1.1.23'"


# ros2 configuration (cyclonedds, custom sysctl rules, ...)
RUN echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> /home/user/.bashrc

CMD ["/bin/bash"]

FROM ros:iron


# install all dependencies
ENV rosdistro iron
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y \ 
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
    libtinyxml-dev 

RUN apt-get update && apt-get install -y \ 
    libgazebo11 

# install python modules for backtrace pretty printer
RUN pip3 install parse ansicolors notebook hhcm-forest

# create a regular user
RUN useradd -ms /bin/bash user
RUN adduser user sudo
RUN echo 'user:user' | chpasswd

WORKDIR /home/user

# bashrc
RUN bash -c "echo source /opt/ros/noetic/setup.bash >> /home/user/.bashrc"
RUN bash -c "echo source /opt/xbot/setup.sh >> /home/user/.bashrc"
RUN bash -c "echo alias notebook_docker=\'jupyter notebook --no-browser --ip=0.0.0.0\' >> /home/user/.bashrc"

# set ownership to user for the whole home folder
# RUN chown -R user .

# change user
USER user

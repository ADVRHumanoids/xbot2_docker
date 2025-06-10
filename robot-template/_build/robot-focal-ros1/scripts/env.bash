export PATH=~/.local/bin:$PATH

# ROS setup - determine version automatically
if [ -d "/opt/ros/noetic" ]; then
    source /opt/ros/noetic/setup.bash
elif [ -d "/opt/ros/jazzy" ]; then
    source /opt/ros/jazzy/setup.bash
elif [ -d "/opt/ros/humble" ]; then
    source /opt/ros/humble/setup.bash
fi

# XBot setup
source /opt/xbot/setup.sh
source ~/xbot2_ws/setup.bash

# Robot-specific setup - can be overridden by robot configs
ROBOT_CONFIG_PATH=${ROBOT_CONFIG_PATH:-"~/xbot2_ws/src/robot_config/setup.sh"}
if [ -f "$ROBOT_CONFIG_PATH" ]; then
    source $ROBOT_CONFIG_PATH
fi

# Autocompletion for common tools
eval "$(register-python-argcomplete ecat)"
eval "$(register-python-argcomplete forest)"
eval "$(register-python-argcomplete concert_launcher)"

export PS1="${CUSTOM_PS}${PS1}"
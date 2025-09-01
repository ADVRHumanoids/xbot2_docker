#!/bin/bash
set -e 

# Get configuration from environment variables
ROBOT_NAME=${ROBOT_NAME:-robot}
RECIPES_TAG=${RECIPES_TAG:-main}
RECIPES_REPO=${RECIPES_REPO:-git@github.com:advrhumanoids/multidof_recipes.git}

# Additional packages can be specified via environment variable
ADDITIONAL_PACKAGES=${ADDITIONAL_PACKAGES:-""}
ROBOT_PACKAGES=${ROBOT_PACKAGES:-""}
echo "Installing robot-specific packages: $ROBOT_PACKAGES"

# refresh apt registry
sudo apt update

source ~/venv/bin/activate

# install forest
pip install hhcm-forest

# do the forest magic
mkdir xbot2_ws && cd xbot2_ws
forest init

# Activate venv first

source setup.bash

# Add recipes with configurable tag
forest add-recipes $RECIPES_REPO -t $RECIPES_TAG

# Core packages that should be available for most robots
forest grow xbot2_gui_server
forest grow xbot2_tools -j8
forest grow cartesio_collision_support -j8
forest grow xbot2_cli

# Install additional packages if specified
if [ ! -z "$ADDITIONAL_PACKAGES" ]; then
    echo "Installing additional packages: $ADDITIONAL_PACKAGES"
    for package in $ADDITIONAL_PACKAGES; do
        forest grow $package -j8 -v
    done
fi

# Robot-specific packages should be installed via environment variable
# Example: ROBOT_PACKAGES="robot_description robot_config robot_drivers"
if [ ! -z "$ROBOT_PACKAGES" ]; then
    echo "Installing robot-specific packages: $ROBOT_PACKAGES"
    for package in $ROBOT_PACKAGES; do
        forest grow $package -j8 -v
    done
fi

# rm build to save space
rm -rf build
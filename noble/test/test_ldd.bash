set -e 

source /opt/xbot/setup.sh
source /opt/ros/jazzy/setup.bash

# for each .so in /opt/xbot sub-tree check dependencies are correctly found via ldd
for so_file in /opt/xbot/lib/*.so; do
    # echo "Checking dependencies for $so_file"
    ldd "$so_file" | grep "not found" && echo "Error: Missing dependencies for $so_file" && exit 1
done

for so_file in /opt/ros/jazzy/lib/*.so; do
    # echo "Checking dependencies for $so_file"
    ldd "$so_file" | grep "not found" && echo "Error: Missing dependencies for $so_file" && exit 1
done

exit 0
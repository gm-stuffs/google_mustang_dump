#!/system/bin/sh

# Enable the water intrusion detection fuse as needed

# get the path to the driver (sensor not available on all products)
path=$(echo /sys/bus/i2c/drivers/h2omg/??-007?)
if [ -z "$path" ]; then
    return 0
fi

# enable the fuse if appropriate
bootmode=$(getprop ro.bootmode)
if [ "$bootmode" == "factory" ]; then
    echo 0 > $path/fuse/enable
    return $?
else
    echo 1 > $path/fuse/enable
    return $?
fi

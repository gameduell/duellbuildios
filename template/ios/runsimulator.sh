#!/usr/bin/env bash

xcrun_version=$( xcrun --version | grep -o '[0-9]\+' )

# Xcode 7
if [ "$xcrun_version" -lt 30 ]
then
    # For Xcode 7 we can't terminate app so we restart the simulator

    if xcrun simctl list | grep "(Booted)" ;
    then
        echo -n "Stopping simulator..."
        killall "Simulator"

        while true ; do
            if xcrun simctl list | grep "(Booted)" ;
            then
                echo -n "."
                sleep 1
            else
                break;
            fi
        done

        echo "...done"
    fi
fi

if pgrep "CoreSimulatorBridge" > /dev/null ; then
    echo "Simulator already running"
    # setting simulator in focus
    open -a Simulator
else

    device_UDID=$( xcrun simctl list devices |
                   awk '/^\-\- .* ::PLATFORM.SIM_OS:: \-\-/{flag=1;next}/^\-\- */{flag=0}flag' |
                   grep " ::PLATFORM.SIM_DEVICE:: (" |
                   grep -v "(unavailable," |
                   cut -d "(" -f2 | cut -d ")" -f1 )

    if [ -z ${device_UDID} ]
    then
       echo "ERROR. Unable to start simulator device '::PLATFORM.SIM_DEVICE::' with OS '::PLATFORM.SIM_OS::'"
       exit 1
    fi

    echo -n "Starting simulator ::PLATFORM.SIM_DEVICE:: ::PLATFORM.SIM_OS:: ($device_UDID)..."

    # runs the simulator

    xcode_path=$( xcode-select -p )
    open ${xcode_path}/Applications/Simulator.app --args -CurrentDeviceUDID $device_UDID

    # waits for the simulator to be booted
    while true ; do
        if xcrun simctl list | grep "(Booted)" | grep -q "($device_UDID)" ;
        then
            break;
        else
            echo -n "."
            sleep 1
        fi
    done

    echo "...done"

fi

# Xcode 8
if [ "$xcrun_version" -ge 30 ]
then
    # terminates old app process
    echo "Terminating '::APP.PACKAGE::'..."
    xcrun simctl terminate booted ::APP.PACKAGE::
fi

# installs the app
echo "Installing '::PLATFORM.OUTPUT_FILE::'..."
xcrun simctl install booted "::PLATFORM.OUTPUT_FILE::"

# runs the app
echo -n "Starting '::APP.PACKAGE::'..."
xcrun simctl launch booted ::APP.PACKAGE::

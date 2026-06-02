#!/usr/bin/env bash

launch_bar(){
    if [[ ! $(pidof polybar) ]]; then
        polybar -q bar &
    else
        polybar-msg cmd restart
    fi
}

launch_bar

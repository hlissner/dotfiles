#!/usr/bin/env bash

date_icon="\ue267"
clock_icon="\ue016"

clock -sf "T${date_icon} %A, %b %d::${clock_icon} %I:%M %p"

#!/usr/bin/env bash

ffmpeg -r 24 -i %d.jpg -b 16000k $1

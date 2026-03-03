#!/usr/bin/env bash

for sel in primary secondary clipboard; do
    echo "=== ${sel} `xclip -selection ${sel} -o`"
done

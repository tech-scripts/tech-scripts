#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$(pwd)

source $USER_DIR/etc/tech-scripts/localization.sh
source $USER_DIR/etc/tech-scripts/variables.sh
source $USER_DIR/etc/tech-scripts/functions.sh

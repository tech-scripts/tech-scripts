#!/bin/bash

for script in /tmp/tech-scripts/misc/tech/{tech,lang,access,editor}.sh; do
    chmod +x "$script" && "$script"
done

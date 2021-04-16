#!/usr/bin/env bash
xargs -a <(find $1 -type f -name "*.pdf") -I {} ~/bab-dub/bab-dub.rb {}

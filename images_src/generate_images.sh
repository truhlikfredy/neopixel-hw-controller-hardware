#!/bin/bash

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function wavedrom-generate {
  phantomjs $SCRIPT_PATH/../node_modules/wavedrom-cli/bin/wavedrom-cli.js -i $SCRIPT_PATH/$1.json -s $SCRIPT_PATH/../images/$1.svg
}

mkdir -p $SCRIPT_PATH/../images

wavedrom-generate sequence
wavedrom-generate data-chunk
wavedrom-generate refresh-cycle

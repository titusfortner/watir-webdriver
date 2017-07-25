#!/bin/bash

set -e
set -x

sh -e /etc/init.d/xvfb start

if [[ "$RAKE_TASK" = "yard:doctest" ]]; then
  mkdir ~/.yard
  bundle exec yard config -a autoload_plugins yard-doctest
fi

if [[ "$RAKE_TASK" = "spec:remote_chrome" ]] || [[ "$RAKE_TASK" = "spec:remote_firefox" ]] || [[ "$RAKE_TASK" = "spec:remote_ff_legacy" ]]; then
  curl -L -O "https://goo.gl/s4o9Vx"
  echo $PWD
fi

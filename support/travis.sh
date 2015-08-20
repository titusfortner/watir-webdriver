#/bin/sh

set -e
set -x

if [[ "$BROWSER_VERSION" = "43" ]]; then
# July 13, 2015
export CHROME_REVISION=323860
elif [[ "$BROWSER_VERSION" = "42" ]]; then
# June 1, 2015
export CHROME_REVISION=317475
elif [[ "$BROWSER_VERSION" = "A" ]]; then
export CHROME_REVISION=325000
elif [[ "$BROWSER_VERSION" = "B" ]]; then
export CHROME_REVISION=330000
elif [[ "$BROWSER_VERSION" = "C" ]]; then
export CHROME_REVISION=335000
elif [[ "$BROWSER_VERSION" = "D" ]]; then
export CHROME_REVISION=340007
else
export CHROME_REVISION=`curl -s http://commondatastorage.googleapis.com/chromium-browser-snapshots/Linux_x64/LAST_CHANGE`
fi

export CHROMEDRIVER_VERSION=`curl -s http://chromedriver.storage.googleapis.com/LATEST_RELEASE`

sh -e /etc/init.d/xvfb start
git submodule update --init

mkdir ~/.yard
bundle exec yard config -a autoload_plugins yard-doctest

if [[ "$WATIR_WEBDRIVER_BROWSER" = "chrome" ]]; then
  sudo chmod 1777 /dev/shm

  sudo apt-get update
  sudo apt-get install -y unzip libxss1

  curl -L -O "http://commondatastorage.googleapis.com/chromium-browser-snapshots/Linux_x64/${CHROME_REVISION}/chrome-linux.zip"
  unzip chrome-linux.zip

  # chrome sandbox doesn't currently work on travis: https://github.com/travis-ci/travis-ci/issues/938
  sudo chown root:root chrome-linux/chrome_sandbox
  sudo chmod 4755 chrome-linux/chrome_sandbox
  export CHROME_DEVEL_SANDBOX="$PWD/chrome-linux/chrome_sandbox"

  curl -L -O "http://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip"
  unzip chromedriver_linux64.zip

  mv chromedriver chrome-linux/chromedriver
  chmod +x chrome-linux/chromedriver
fi

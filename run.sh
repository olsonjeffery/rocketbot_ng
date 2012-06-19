#/bin/sh
coffee -c ./scripts/*.coffee &&
coffee -c ./*.coffee &&
&& node rocketbot.js

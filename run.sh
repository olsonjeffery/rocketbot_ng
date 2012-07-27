#/bin/sh
npm install
coffee -c ./scripts/*.coffee &&
coffee -c ./*.coffee && node rocketbot.js

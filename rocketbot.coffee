#!/usr/bin/env coffee
hookio = require 'hook.io'
irc = (require 'hook.io-irc').IRC
options = require 'options'

console.log 'rocketbot_ng'

hook = hookio.createHook(options)
hook.start()

#!/usr/bin/env coffee
_ = require 'underscore'
irc = require 'irc'
require 'sugar'

options = require "options"
parse_msg = require 'parse_msg'

Hook = (require 'hook').Hook
sandbox = require 'sandbox'

console.log "rocketbot_ng #{options.version} startuping up"

console.log "setting up db connection..."

sandbox.init(options)

rocketbot = new irc.Client options['irc-server'], options.nick,
  channels: options.channels
  userName: options.userName
  realName: options.realName
  port: options.port
  secure: options.secure

rocketbot.addListener "message", (sending_nick, dest_nick, text) ->
  console.log "message received!"
  if sending_nick != options.nick
    is_channel_msg = dest_nick != options.nick
    reply_to_nick = if is_channel_msg then dest_nick else sending_nick
    parsed_msg = parse_msg sending_nick, reply_to_nick, options.cmd_prefix,
                           text
    sandbox.process rocketbot, 'message', parsed_msg
rocketbot.addListener "topic", (channel, topic, nick, message) ->
  console.log "topic change!"
  parsed_msg =
    topic: topic
    chan: channel
    nick: nick
    text: topic
  sandbox.process rocketbot, 'topic', parsed_msg
rocketbot.addListener "motd", (motd) ->
  console.log "received MOTD from server"
rocketbot.addListener "join", (chan, nick, msg) ->
  console.log "rocketbot has joined #{chan}"
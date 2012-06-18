#!/usr/bin/env coffee
_ = require 'underscore'
irc = require 'irc'
require 'sugar'

options = require './options'
parse_msg = require './parse_msg'

Hook = (require 'tinyhook/hook').Hook

console.log "rocketbot_ng #{options.version} startuping up"
master = new Hook
  name: 'master'
  port: options.hook_port
  silent: false
master.start()

master.on 'hook::ready', ->
  # this should become a spawn...
  master.spawn([{
        src:__dirname+"/sandbox.js"
        name:'sandbox'
        port:options.hook_port
      }
    ]
  )
  #sandbox = new SandboxHook
  #  name: 'sandbox'
  #  silent: false
  #sandbox.connect
  #  'hook-port': options.hook_port
  master.on 'children::ready', ->
    master.emit 'init_sandbox', options

  console.log "MASTER: opening IRC connection..."
  rocketbot = new irc.Client options['irc-server'], options.nick,
    channels: options.channels
    userName: options.userName
    realName: options.realName
    port: options.port
    secure: options.secure

  rocketbot.addListener "message", (sending_nick, dest_nick, text) ->
    console.log "MASTER: message received!"
    if sending_nick != options.nick
      is_channel_msg = dest_nick != options.nick
      reply_to_nick = if is_channel_msg then dest_nick else sending_nick
      parsed_msg = parse_msg sending_nick, reply_to_nick,
                             options.cmd_prefix, text
    master.emit 'process_msg',
      msg_type: 'message'
      parsed_msg: parsed_msg
  rocketbot.addListener "topic", (channel, topic, nick, message) ->
    console.log "MASTER: topic change!"
    parsed_msg =
      topic: topic
      chan: channel
      nick: nick
      text: topic
    master.emit 'process_msg',
      msg_type: 'topic'
      parsed_msg: parsed_msg
  rocketbot.addListener "motd", (motd) ->
    console.log "MASTER: received MOTD from server"
  rocketbot.addListener "join", (chan, nick, msg) ->
    console.log "MASTER: rocketbot has joined #{chan}"

  master.on 'sandbox::bot_say', (data) ->
    rocketbot.say data.chan, data.msg
  master.on 'sandbox::bot_send', (data) ->
    rocketbot.say data.cmd, data.chan, data.msg

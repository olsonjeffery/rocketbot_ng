#!/usr/bin/env coffee
child_process = require 'child_process'
_ = require 'underscore'
irc = require 'irc'
require 'sugar'

options = require './options'
parse_msg = require './parse_msg'
special_cmds = require './special_cmds'

Hook = (require 'tinyhook/hook').Hook

console.log "rocketbot_ng #{options.version} startuping up"
master = new Hook
  name: 'master'
  port: options.hook_port
  silent: false
master.start()

sandbox_spawned = false

sandbox_active = false
msg_queue = []

process_message = (master, parsed_msg) ->
  console.log "in process_message"
  spc = _.detect special_cmds, (c) -> c.name == parsed_msg.command
  if spc?
    spc.process master, options, parsed_msg
  else
    master.emit 'process_msg',
      msg_type: 'message'
      parsed_msg: parsed_msg

master.on 'hook::ready', ->
  # spinip the sandbox for the first time
  master.emit 'cycle_sandbox', {chan: null}

  # connect to IRC
  console.log "MASTER: opening IRC connection..."
  rocketbot = new irc.Client options['irc-server'], options.nick,
    channels: options.channels
    userName: options.userName
    realName: options.realName
    port: options.port
    secure: options.secure

  # node-irc listeners
  rocketbot.addListener "message", (sending_nick, dest_nick, text) ->
    console.log "MASTER: message received!"
    if sending_nick != options.nick
      is_channel_msg = dest_nick != options.nick
      reply_to_nick = if is_channel_msg then dest_nick else sending_nick
      parsed_msg = parse_msg sending_nick, reply_to_nick,
                             options.cmd_prefix, text
      if not sandbox_active
        console.log 'enqueueing message'
        msg_queue.push
          msg_type: 'message'
          parsed_msg: parsed_msg
      else
        console.log 'emitting process_msg for message'
        process_message master, parsed_msg
  rocketbot.addListener "topic", (channel, topic, nick, message) ->
    console.log "MASTER: topic change!"
    parsed_msg =
      topic: topic
      chan: channel
      nick: nick
      text: topic
    if not sandbox_active
      msg_queue.push
        msg_type: 'topic'
        parsed_msg: parsed_msg
    else
      console.log 'emitting process_topic'
      master.emit 'process_msg',
        msg_type: 'topic'
        parsed_msg: parsed_msg
  rocketbot.addListener "motd", (motd) ->
    console.log "MASTER: received MOTD from server"
  rocketbot.addListener "join", (chan, nick, msg) ->
    console.log "MASTER: rocketbot has joined #{chan}"

  # outbound msgs (to IRC)
  master.on 'bot_say', (data) ->
    rocketbot.say data.chan, data.msg
  master.on 'bot_send', (data) ->
    rocketbot.say data.cmd, data.chan, data.msg
  master.on '*::bot_say', (data) ->
    rocketbot.say data.chan, data.msg
  master.on '*::bot_send', (data) ->
    rocketbot.say data.cmd, data.chan, data.msg

# this is an idempotent listener that'll start a sandbox
# if one hasn't been spawned, or recycle/restart it, otherwise
master.on 'cycle_sandbox', (data) ->
    console.log "cycling sandbox. running CS compile.."
    coffee_cmd = "coffee -c ./*.coffee"
    compile = child_process.exec coffee_cmd,
      (err, stdout, stderr) ->
         console.log "#{new Date().toString()} -- #{coffee_cmd}"
         console.log "STDOUT: #{stdout.toString('utf8').truncate(300)}"
         console.log "STDERR: #{stderr.toString('utf8').truncate(300)}"
    compile.on 'exit', (exit_code) ->
      console.log "CS compile complete.."
      if exit_code != 0
        console.log "ERROR during CS compile"
        if data.chan?
          master.emit 'bot_say',
            chan: data.chan
            msg: "ERROR during CS compile, exit code #{exit_code}. "+
                "Recycle aborted."
      else
        console.log "CS compile successful"
        if data.chan?
          console.log 'valid data.chan for post-CS compile success'
          master.emit 'bot_say',
            chan: data.chan
            msg: "CS compiled successfully"
        if sandbox_spawned
          console.log "recycling sandbox"
          master.emit 'recycle_sandbox', {}
        else
          sandbox_spawned = true
          console.log "spawning sandbox"
          master.sandbox_hook = master.spawn([{
                src:__dirname+"/sandbox.js"
                name:'sandbox'
                port:options.hook_port
              }
            ]
          )
        start_type = if sandbox_spawned then 'recycled' else 'started'
        master.once 'sandbox::sandbox_started', ->
          console.log "sandbox #{start_type}, calling init.."
          master.emit 'init_sandbox', options
          master.once 'sandbox::sandbox_active', ->
            console.log "sandbox is active!"
            if data.chan?
              master.emit 'bot_say',
                chan: data.chan
                msg: "Sandbox recycled successfully"
            sandbox_active = true
            while msg_queue.length > 0
              a_msg = msg_queue.pop()
              console.log "replaying enqueue'd msg"
              if a_msg.msg_type == 'message'
                process_message master, parsed_msg
              else
                master.emit 'process_msg', a_msg

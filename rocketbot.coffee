#!/usr/bin/env coffee
_ = require 'underscore'
irc = require 'irc'
require 'sugar'

options = require "options"
plugin_loader = require 'plugin_loader'
parse_msg = require 'parse_msg'

console.log "rocketbot_ng"

plugin_loader.init options

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
    result = _.detect plugin_loader.plugins, (plg) ->
      if parsed_msg.has_command
        console.log "incoming msg has_command #{parsed_msg.command}"
        _.detect plg.commands, (cmd) ->
          cmd == parsed_msg.command
      else if plg.match_regex().test parsed_msg.text
        console.log "regex match!"
        true
      else
        console.log "no cmd/matching cmd or match regex..."
        false
    if result?
      result.process rocketbot, parsed_msg
    else
      console.log "no match for provided text '#{text}'"
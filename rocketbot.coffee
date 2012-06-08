#!/usr/bin/env coffee
_ = require 'underscore'
irc = require 'irc'
require 'sugar'
Sequelize = require 'sequelize'

options = require "options"
plugin_loader = require 'plugin_loader'
parse_msg = require 'parse_msg'

console.log "rocketbot_ng #{options.version} startuping up"

console.log "setting up db connection..."
# set up the db
sequelize = new Sequelize(
  options.db.database, options.db.username,
  options.db.password, {
    dialect: 'sqlite'
    storage: options.db.storage
  }
)

plugin_loader.init(options, {sequelize: sequelize, Sql: Sequelize})

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
    _.each plugin_loader.plugins, (plg) ->
      match_regex = plg.match_regex()
      if parsed_msg.has_command and plg.commands.length > 0
        console.log "incoming msg has_command #{parsed_msg.command}"
        match_cmd = _.detect plg.commands, (cmd) ->
          cmd == parsed_msg.command
        if match_cmd
          console.log "cmd match"
          plg.process rocketbot, parsed_msg
      else if match_regex? and match_regex.test parsed_msg.text
        console.log "regex match!"
        plg.process rocketbot, parsed_msg
      else
        console.log "no matching-cmd or match regex..."
rocketbot.addListener "motd", (motd) ->
  console.log "received MOTD from server"
rocketbot.addListener "join", (chan, nick, msg) ->
  console.log "rocketbot has joined #{chan}"
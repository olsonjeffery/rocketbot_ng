_ = require 'underscore'

weather = require './weather'
web_summary = require './web_summary'
wikipedia = require './wikipedia'
etym = require './etym'
logging = require './logging'
user_data = require './user_data'
webdip = require './webdip'
topic = require './topic'
ronpaul = require './ronpaul'

Sequelize = require 'sequelize'

Hook = (require 'tinyhook/hook').Hook
util = require 'util'

console.log "Running through sandbox.coffee"

SandboxHook = exports.SandboxHook = (hook_options) ->
  Hook.call this, hook_options
  @on 'hook::ready', =>
    console.log "SANDBOX: sandbox hook ready"
  @on '*::init_sandbox', (bot_options) =>
    console.log "SANDBOX: initializing db..."
    # set up the db
    sequelize = new Sequelize(
      bot_options.db.database, bot_options.db.username,
      bot_options.db.password, {
        dialect: 'sqlite'
        storage: bot_options.db.storage
      }
    )
    db = {sequelize: sequelize, Sql: Sequelize}

    console.log "SANDBOX: initializing plugins..."
    # get list of plugins
    plugins = _.flatten([
      web_summary.plugins,
      weather.plugins,
      wikipedia.plugins,
      etym.plugins,
      logging.plugins,
      user_data.plugins,
      webdip.plugins,
      topic.plugins,
      ronpaul.plugins
    ])
    # initialize them all..
    @plugins = _.map plugins, (plg) =>
      new plg(this, bot_options, db)
  @on '*::process_msg', (data) ->
    { msg_type, parsed_msg } = data
    client =
      say: (chan, msg) =>
        @emit 'bot_say',
          chan: chan
          msg: msg
      send: (cmd, chan, msg) =>
        @emit 'bot_send',
          cmd: cmd
          chan: chan
          msg: msg
    _.each @plugins, (plg) ->
      if plg.msg_type == msg_type
        match_regex = plg.match_regex()
        if parsed_msg.has_command and plg.commands.length > 0
          console.log "incoming msg has_command #{parsed_msg.command}"
          match_cmd = _.detect plg.commands, (cmd) ->
            cmd == parsed_msg.command
          if match_cmd
            console.log "cmd match"
            plg.process client, parsed_msg
        else if match_regex? and match_regex.test parsed_msg.text
          console.log "regex match!"
          plg.process client, parsed_msg
        else
          console.log "no matching-cmd or match regex..."

util.inherits SandboxHook, Hook

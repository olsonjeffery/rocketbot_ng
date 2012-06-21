util = require 'util'
fs = require 'fs'
require 'sugar'

_ = require 'underscore'

Sequelize = require 'sequelize'
Hook = (require 'tinyhook/hook').Hook

rb_util = require './rb_util'

SandboxHook = exports.SandboxHook = (hook_options) ->
  Hook.call this, hook_options
  @on 'hook::ready', =>
    console.log "SANDBOX: sandbox hook ready"
    @emit "sandbox_started", {}
  @on '*::init_sandbox', (bot_options) =>
    @bot_options = bot_options
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
    plugins = []
    scripts_path = __dirname+"/scripts"
    console.log "about to read scripts dir.. '#{scripts_path}'"
    _.each(fs.readdirSync(scripts_path), (f) ->
      f_path = "#{scripts_path}/#{f.toString()}"
      if f_path.endsWith ".js"
        console.log "found script file: #{f_path}"
        mod = require(f_path)
        if mod.plugins?
          _.each mod.plugins, (plg) ->
            plugins.push plg
    )
    # initialize them all..
    @plugins = _.map plugins, (plg) =>
      new plg(@bot_options, db)
    @emit 'sandbox_active', {}
  @on '*::process_msg', (data) =>
    { msg_type, parsed_msg } = data
    client = rb_util.hook_client this
    _.each @plugins, (plg) =>
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
  @on '*::recycle_sandbox', =>
    console.log "recycling sandbox!"
    @stop()
  @on '*::process_docs', (msg) =>
    client = rb_util.hook_client this
    topic = msg.msg.compact()
    if topic == ''
      topics = _.map((_.filter @plugins, (plg) -> plg.docs?), (plg) ->
        "'#{plg.doc_name}'"
      ).join(', ')
      if topics == ''
        client.say msg.sending_nick, "I don't have any docs, sorry."
      else
        client.say msg.sending_nick, "I have documentation on the "+
        "following topics: #{topics}"
        client.say msg.sending_nick, "Type `#{@bot_options.cmd_prefix}"+
          "help <TOPIC>` to learn about a specific topic."
    else
      plg = _.detect(@plugins, (plg) ->
        plg.doc_name? and plg.doc_name == topic)
      if plg?
        client.say msg.sending_nick, "Documentation for #{topic}:"
        _.each plg.docs().split('\n'), (line) ->
          client.say msg.reply, line.compact()
      else
        client.say msg.reply, "Sorry, no docs for '#{topic}'"




util.inherits SandboxHook, Hook

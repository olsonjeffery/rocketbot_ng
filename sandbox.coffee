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
      nPlg = new plg(@bot_options, db, this)
      nPlg.active = true
      nPlg
    listeners = _.filter @plugins, (plg) ->
      plg.msg_type == 'listener'
    _.each listeners, (plg) =>
      self = this
      @on plg.hook_name, (data) ->
        client = rb_util.hook_client self
        plg.process.apply(plg, [client, data])
    @emit 'sandbox_active', {}
  @on '*::process_msg', (data) =>
    { msg_type, parsed_msg } = data
    client = rb_util.hook_client this
    _.each @plugins, (plg) =>
      if plg.msg_type == msg_type and plg.active
        match_regex = plg.match_regex()
        if parsed_msg.has_command and plg.commands.length > 0
          match_cmd = _.detect plg.commands, (cmd) ->
            cmd == parsed_msg.command
          if match_cmd
            plg.process client, parsed_msg
        else if match_regex? and match_regex.test parsed_msg.text
          plg.process client, parsed_msg
  @on '*::recycle_sandbox', =>
    console.log "recycling sandbox!"
    @stop()
  @on '*::process_docs', (msg) =>
    client = rb_util.hook_client this
    topic = msg.msg.compact()
    if topic == ''
      topics = _.map((_.filter @plugins, (plg) -> plg.active and plg.docs?),
        (plg) ->
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
  @on '*::process_plugins_list', (msg) =>
    client = rb_util.hook_client this
    _.each @plugins, (plg) ->
      activity = if plg.active then '' else " ##DISABLED##"
      version = if plg.version? then plg.version else 0
      client.say msg.reply, "#{plg.name} (#{version})#{activity}"
  @on '*::process_plugin_enable', (msg) =>
    console.log "plugin enable.."
    client = rb_util.hook_client this
    target_name = msg.msg.compact()
    target_plg = _.detect(@plugins, (plg) -> plg.name == target_name)
    if target_plg?
      if target_plg.active
        client.say msg.reply, "#{target_name} is already enabled."
      else
        target_plg.active = true
        client.say msg.reply, "#{target_name} enabled."
    else
      client.say msg.reply, "I don't have a plugin loaded named "+
         "'#{target_name}'."
  @on '*::process_plugin_disable', (msg) =>
    console.log "plugin disable.."
    client = rb_util.hook_client this
    target_name = msg.msg.compact()
    target_plg = _.detect(@plugins, (plg) -> plg.name == target_name)
    if target_plg?
      if not target_plg.active
        client.say msg.reply, "#{target_name} is already disabled."
      else
        target_plg.active = false
        client.say msg.reply, "#{target_name} disabled."
    else
      client.say msg.reply, "I don't have a plugin loaded named "+
         "'#{target_name}'."

util.inherits SandboxHook, Hook

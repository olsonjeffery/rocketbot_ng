_ = require 'underscore'
models = {}

euphemism_initialized = false
euphemism_init = (db) ->
  euphemism_initialized = true
  models.euphemism =
    db.sequelize.define('euphemism', {
      id: { type: db.Sql.INTEGER, autoIncrement: true, allowNull: false},
      chan: db.Sql.STRING,
      nick: db.Sql.STRING,
      desc: db.Sql.TEXT
    },
    {
      classMethods: {
        recent_for: (nick, cb) ->
          @findAll({
            order: 'createdAt DESC',
            limit: 5,
            where: {nick: nick}
          }).success (entries) ->
            cb entries
        recent: (cb) ->
          @findAll({
            order: 'createdAt DESC',
            limit: 5
          }).success (entries) ->
            cb entries
        by_desc: (desc, cb) ->
          @find({
            where: {desc: desc}
          }).success (entry) ->
            cb entry
      }
    })
  models.euphemism.sync()

class cacophemism_plugin
  constructor: (plg_ldr, options, @db) ->
    if not euphemism_initialized
      euphemism_init @db
  name: 'euphemism'
  msg_type: 'message'
  version: '1'
  commands: ['cacophemism', 'caco']
  match_regex: () ->
    null
  process: (client, msg) ->
    euph = msg.msg.compact()
    if euph == ''
      client.say msg.reply, "Sorry, you gotta actually give me something "+
        "to remove."
    else
      models.euphemism.by_desc euph, (e) ->
        if e?
          e.destroy()
          client.say msg.reply, "Ok, \"#{euph}\" removed"
        else
          client.say msg.reply, "Sorry, I don't have any euphemisms "+
            "matching \"#{euph}\""
class euphemism_plugin
  constructor: (plg_ldr, options, @db) ->
    if not euphemism_initialized
      euphemism_init @db
  name: 'euphemism'
  msg_type: 'message'
  version: '1'
  commands: ['euphemism', 'euph']
  match_regex: () ->
    null
  process: (client, msg) ->
    euph = msg.msg.compact().replace(/^"/g,'').replace(/"$/,'')
    if euph == ''
      client.say msg.reply, "Sorry, you gotta actually give me something "+
        "to store."
    else
      models.euphemism.create
        chan: msg.reply
        nick: msg.sending_nick
        desc: euph
      client.say msg.reply, "Euphemism \"#{euph}\" added."
class recent_euphemisms_plugin
  constructor: (plg_ldr, options, @db) ->
    if not euphemism_initialized
      euphemism_init @db
  name: 'recent euphemisms'
  msg_type: 'message'
  version: '1'
  commands: ['euphemisms', 'euphs']
  match_regex: () ->
    null
  process: (client, msg) ->
    name = msg.msg.compact()
    if name == ''
      client.say msg.reply, "Recent euphemisms:"
      models.euphemism.recent (entries) ->
        _.each entries, (e) ->
          client.say msg.reply, "<#{e.nick}> \"#{e.desc}\" "+
           "#{e.createdAt.relative()}."
    else
      models.euphemism.recent_for name, (entries) ->
        if not entries?
          client.say msg.replay, "Sorry, I haven't recorded any "+
            "euphemisms from #{name}."
          return null
        client.say msg.reply, "Recent euphemisms for #{name}:"
        _.each entries, (e) ->
          client.say msg.reply, "\"#{e.desc}\" "+
           "#{e.createdAt.relative()}."

module.exports =
  plugins: [euphemism_plugin, recent_euphemisms_plugin, cacophemism_plugin]
  models: models

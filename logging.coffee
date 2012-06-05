models = {}
_ = require 'underscore'

log_entry_init = (db) ->
  models.log_entry =
    db.sequelize.define('log_entry', {
      id: { type: db.Sql.INTEGER, autoIncrement: true, allowNull: false},
      chan: db.Sql.STRING,
      nick: db.Sql.STRING,
      msg: db.Sql.TEXT,
    },
    {
      classMethods: {
        latest_entry_for: (nick, cb) ->
          @findAll({
            order: 'createdAt DESC',
            limit: 1,
            where: {nick: nick}
          }).success (entries) ->
            cb _.first(entries)
      }
    })
  models.log_entry.sync()

class seen
  constructor: (plg_ldr, options, @db) ->
  name: 'seen'
  version: '1'
  commands: ['seen']
  match_regex: ->
    null
  process: (client, msg) ->
    latest = models.log_entry.latest_entry_for msg.msg, (entry) ->
      if entry?
        client.say msg.reply, "#{entry.nick} was last seen on "+
          "#{entry.createdAt} saying '#{entry.msg}'."
      else
        client.say msg.reply, "I haven't heard anything from #{msg.msg}"

class logging
  constructor: (plg_ldr, options, @db) ->
    log_entry_init @db
  name: 'seen'
  version: '1'
  commands: []
  match_regex: ->
    /^.*$/
  process: (client, msg) ->
    models.log_entry.create
      chan: msg.reply
      nick: msg.sending_nick
      msg: msg.text

module.exports =
  plugins: [logging, seen]
  models: models
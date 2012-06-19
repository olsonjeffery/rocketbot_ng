models = {}
_ = require 'underscore'

log_entry_init = (db) ->
  models.log_entry =
    db.sequelize.define('log_entry', {
      id: { type: db.Sql.INTEGER, autoIncrement: true, allowNull: false},
      chan: db.Sql.STRING,
      nick: db.Sql.STRING,
      msg: db.Sql.TEXT,
      is_pun: db.Sql.BOOLEAN
    },
    {
      classMethods: {
        latest_entry_for: (nick, cb) ->
          @find({
            order: 'createdAt DESC',
            where: {nick: nick}
          }).success (entry) ->
            cb entry
        entries_for_nick_after: (nick, cutoff, cb) ->
          @findAll({
            order: 'createdAt DESC',
            where: ['datetime(createdAt) > datetime(?)',
                    cutoff.format('{yyyy}-{MM}-{dd} {HH}:{mm}:{ss}')],
          }).success (entries) ->
            console.log "# if entries since cuttoff: #{entries.length}"
            entries = _.filter entries, (e) ->
              e.nick == nick
            console.log "# if entries by nick since c/o: #{entries.length}"
            cb entries
         recent_puns: (cb) ->
          @findAll({
            order: 'createdAt DESC',
            limit: 5,
            where: {is_pun: 1}
          }).success (entries) ->
            cb entries
         recent_puns_from: (nick, cb) ->
          @findAll({
            order: 'createdAt DESC',
            limit: 5,
            where: {is_pun: 1, nick: nick}
          }).success (entries) ->
            cb entries
      }
    })
  models.log_entry.sync()

class seen_plugin
  constructor: (plg_ldr, options, @db) ->
  name: 'seen'
  msg_type: 'message'
  version: '1'
  commands: ['seen']
  match_regex: ->
    null
  process: (client, msg) ->
    latest = models.log_entry.latest_entry_for msg.msg, (entry) ->
      if entry?
        client.say msg.reply, "#{entry.nick} was last seen "+
          "#{entry.createdAt.relative()} saying '#{entry.msg}'."
      else
        client.say msg.reply, "I haven't heard anything from #{msg.msg}"

class logging_plugin
  constructor: (plg_ldr, options, @db) ->
    log_entry_init @db
  name: 'logging'
  msg_type: 'message'
  version: '1'
  commands: []
  match_regex: ->
    /^.*$/
  process: (client, msg) ->
    console.log "LOGGING: <#{msg.sending_nick}> #{msg.text}"
    models.log_entry.create
      chan: msg.reply
      nick: msg.sending_nick
      msg: msg.text

module.exports =
  plugins: [logging_plugin, seen_plugin]
  models: models
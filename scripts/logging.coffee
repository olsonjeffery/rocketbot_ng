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
          nick = nick.toLowerCase()
          @find({
            order: 'createdAt DESC',
            where: {nick: nick}
          }).success (entry) ->
            cb entry
        entries_for_nick_after: (nick, cutoff, cb) ->
          nick = nick.toLowerCase()
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
            nick = nick.toLowerCase()
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
  constructor: (@options, @db) ->
  name: 'seen'
  msg_type: 'message'
  version: '1'
  commands: ['seen']
  match_regex: ->
    null
  doc_name: 'seen'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}seen <NICK>
    INFO: Show when/where <NICK> last spoke and what they said,
          if the bot has heard them at all.
    """
  process: (client, msg) ->
    input_nick = msg.msg.compact()
    seen_nick = input_nick.toLowerCase()
    latest = models.log_entry.latest_entry_for seen_nick, (entry) ->
      if entry?
        client.say msg.reply, "#{input_nick} was last seen "+
          "#{entry.createdAt.relative()} saying '#{entry.msg}'."
      else
        client.say msg.reply, "I haven't heard anything from #{msg.msg}"

class logging_plugin
  constructor: (@options, @db, @hook) ->
    log_entry_init @db
  name: 'logging'
  msg_type: 'message'
  version: '1'
  commands: []
  match_regex: ->
    /^.*$/
  process: (client, in_msg) ->
    chan = in_msg.reply.toLowerCase()
    nick = in_msg.sending_nick.toLowerCase()
    msg = in_msg.text
    console.log "LOGGING: <#{nick}> #{msg}"
    models.log_entry.create
      chan: chan
      nick: nick
      msg: msg
    @hook.emit "logging::new_msg",
      chan: chan
      nick: nick
      msg: msg

module.exports =
  plugins: [logging_plugin, seen_plugin]
  models: models
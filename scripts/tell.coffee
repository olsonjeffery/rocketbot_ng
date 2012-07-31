_ = require 'underscore'
models = {}

tell_message_initialized = false
tell_message_init = (db) ->
  tell_message_initialized = true
  models.tell_message =
    db.sequelize.define('tell_message', {
      id: { type: db.Sql.INTEGER, autoIncrement: true, allowNull: false},
      target: db.Sql.STRING,
      sender: db.Sql.STRING,
      msg: db.Sql.TEXT,
      read: db.Sql.BOOLEAN
    },
    {
      classMethods: {
        for_target: (nick, cb) ->
          @findAll({
            order: 'createdAt ASC',
            where: {target: nick, read: 0}
          }).success (entries) ->
            cb entries
      }
    })
  models.tell_message.sync()

new_tell = (target, tell_msg, sender, cb) ->
  models.tell_message.create
    target: target
    sender: sender
    msg: tell_msg
    read: false
  cb()

class tell_plugin
  constructor: (@options, @db) ->
    if not tell_message_initialized
      tell_message_init @db
  name: 'tell'
  msg_type: 'message'
  version: '1'
  commands: [ 'tell' ]
  match_regex: ->
    null
  doc_name: 'tell'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}tell <NICK> <MESSAGE>
    INFO: Have the bot tell <NICK> the provided <MESSAGE> next
    time the user is in active in a channel monitored by the bot (the
    next time they say something, pretty much).
    """
  process: (client, msg) ->
    parts = msg.msg.compact().split(' ')
    target = _.first parts
    tell_msg = _.rest(parts).join(' ')
    sender = msg.sending_nick
    new_tell target, tell_msg, sender, ->
      client.say msg.reply, "Ok, I'll tell #{target} '#{tell_msg}' next "+
        "time I see them."


class tell_monitor_plugin
  constructor: (@options, @db) ->
    if not tell_message_initialized
      tell_message_init @db
  name: 'tell_monitor'
  msg_type: 'listener'
  hook_name: 'logging::new_msg'
  version: '1'
  process: (client, data) ->
    console.log "TELL MONITOR HIT! blah from #{data.nick}"
    models.tell_message.for_target data.nick, (tell_msgs) ->
      if tell_msgs? and tell_msgs.length > 0
        console.log "we have messages for #{data.nick}"
        timer_delay = 1500
        client.say data.nick, "I have #{tell_msgs.length} message(s) "+
          "for you:"
        idx = 0
        message_teller = ->
          curr_msg = tell_msgs[idx]
          idx += 1
          client.say data.nick, "#{curr_msg.sender} asked me to tell you '"+
            "#{curr_msg.msg}' #{curr_msg.createdAt.relative()}."
          curr_msg.read = true
          curr_msg.save()
          if idx < tell_msgs.length
            setTimeout message_teller, timer_delay
        setTimeout message_teller, timer_delay

module.exports =
  plugins: [tell_plugin, tell_monitor_plugin]
  new_tell: new_tell
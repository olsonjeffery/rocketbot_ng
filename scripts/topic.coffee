_ = require 'underscore'

models = {}
topic_info_initialized = false
topic_info_init = (db) ->
  topic_info_initialized = true
  models.topic_info =
    db.sequelize.define('topic_info', {
      id: { type: db.Sql.INTEGER, autoIncrement: true, allowNull: false},
      nick: db.Sql.STRING,
      chan: db.Sql.STRING,
      topic: db.Sql.STRING
    },
    {
      classMethods: {
        recent_by_nick: (chan, nick, cb) ->
          @findAll({
            limit: 5
            order: 'createdAt DESC'
            where: {nick: nick, chan: chan}
          }).success (entries) ->
            cb entries
        recent: (chan, cb) ->
          @findAll({
            limit: 5
            order: 'createdAt DESC'
            where: {chan: chan}
          }).success (entries) ->
            cb entries
        by_topic: (topic, cb) ->
          @find({
            where: {topic: topic}
          }).success (entry) ->
            cb entry
      }
    })
  models.topic_info.sync()

class topic_logger_plugin
  constructor: (plg_ldr, @options, @db) ->
    if not topic_info_initialized
      topic_info_init @db
  name: 'topic_logger'
  msg_type: 'topic'
  version: '1'
  commands: []
  match_regex: () ->
    /^.*$/
  process: (client, msg) ->
    console.log "topic_logger process..."
    new_topic = msg.topic
    topic_nick = msg.nick.split('!')[0].compact()
    models.topic_info.by_topic new_topic, (t) =>
      if (t? and t.nick == topic_nick) or topic_nick == @options.nick
        console.log "topic already exists or bot topic..."
      else
        models.topic_info.create
          nick: topic_nick
          chan: msg.chan
          topic: new_topic


class topic_plugin
  constructor: (@options, @db) ->
    if not topic_info_initialized
      topic_info_init @db
  name: 'topic'
  msg_type: 'message'
  version: '1'
  commands: ['topic']
  doc_name: 'topic'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}topic <TOPIC>
    INFO: Sets the current channel topic to the one provided and records
          it for future generations.
    """
  match_regex: () ->
    null
  process: (client, msg) ->
    if msg.reply == msg.sending_nick
      client.say msg.reply, "Sorry, dude. You can only change the topic "+
                            "in channel."
      return null
    new_topic = msg.msg.compact()
    if new_topic == ''
      client.say msg.reply, "Sorry, I need a valid message to change the "+
        "topic to."
      return null
    models.topic_info.create({
      nick: msg.sending_nick.compact()
      chan: msg.reply
      topic: new_topic
    }).success ->
      client.send "TOPIC", msg.reply, new_topic

class recent_topics_plugin
  constructor: (@options, @db) ->
    if not topic_info_initialized
      topic_info_init @db
  name: 'recent_topics'
  msg_type: 'message'
  version: '1'
  commands: ['topics']
  match_regex: () ->
    null
  doc_name: 'topics'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}topics <TOPIC>
    INFO: Sets the current channel topic to the one provided and records
          it for future generations.
    """
  process: (client, msg) ->
    if msg.reply == msg.sending_nick
      client.say msg.reply, "Sorry, only works in chan."
      return null
    if msg.msg == ''
      models.topic_info.recent msg.reply, (topics) ->
        if topics?
          client.say msg.reply, "Recent topics:"
          _.each topics, (t) ->
            client.say msg.reply, "<#{t.nick}> #{t.createdAt.relative()} "+
                                  "- \"#{t.topic}\""
        else
          client.say msg.reply, "No topics logged."
    else
      nick = msg.msg.compact()
      models.topic_info.recent_by_nick msg.reply, nick, (topics) ->
        if topics?
          client.say msg.reply, "Recent topics from #{nick}:"
          _.each topics, (t) ->
            client.say msg.reply, "#{t.createdAt.relative()} - "+
                                  "\"#{t.topic}\""
        else
          client.say msg.reply, "Sorry, no topic changes from #{nick}."

module.exports =
  models: models
  plugins: [topic_plugin, topic_logger_plugin, recent_topics_plugin]

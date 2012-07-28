_ = require 'underscore'
models = {}

queue_contents_initialized = false
queue_contents_init = (db) ->
  queue_contents_initialized = true
  models.queue_contents =
    db.sequelize.define('queue_contents', {
      id: { type: db.Sql.INTEGER, autoIncrement: true, allowNull: false},
      chan: db.Sql.STRING,
      nick: db.Sql.STRING,
      contents: db.Sql.TEXT
    },
    {
      classMethods: {
        create_or_find: (nick, chan, cb) ->
          @find({
            order: 'createdAt ASC',
            where: {nick: nick, chan: chan}
          }).success (entry) ->
            if entry?
              cb entry
            else
              models.queue_contents.create({chan:chan,nick:nick,contents:"[]"}).success (entry) ->
                cb entry
      }
    })
  models.queue_contents.sync()

class qpush_plugin
  constructor: (@options, @db) ->
    if not queue_contents_initialized
      queue_contents_init @db
  name: 'qpush'
  msg_type: 'message'
  version: '1'
  commands: ['qpush']
  match_regex: () ->
    null
  doc_name: 'qpush'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}qpush <PHRASE>
    INFO: Push <PHRASE> onto the top of your work stack
    """
  process: (client, msg) ->
    item = msg.msg.compact()
    if item == ''
      client.say msg.reply, "I need something to put onto the queue."
    else
      models.queue_contents.create_or_find msg.sending_nick,
        msg.reply, (contents) ->
          queue = JSON.parse contents.contents
          queue.push item
          contents.contents = JSON.stringify queue
          contents.save().success ->
            client.say msg.reply, "#{msg.sending_nick}: gotcha."
class qpop_plugin
  constructor: (@options, @db) ->
    if not queue_contents_initialized
      queue_contents_init @db
  name: 'qpop'
  msg_type: 'message'
  version: '1'
  commands: ['qpop']
  match_regex: () ->
    null
  doc_name: 'qpop'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}qpop
    INFO: Pop and return the item atop your work stack
    """
  process: (client, msg) ->
    models.queue_contents.create_or_find msg.sending_nick, msg.reply,
        (contents) ->
          results = JSON.parse contents.contents
          desc = results.pop()
          contents.contents = JSON.stringify results
          contents.save().success ->
            client.say msg.reply, "Removed \"#{desc}\" from stack."
class queue_plugin
  constructor: (@options, @db) ->
    if not queue_contents_initialized
      queue_contents_init @db
  name: 'queue'
  msg_type: 'message'
  version: '1'
  commands: ['queue', 'stack']
  match_regex: () ->
    null
  doc_name: 'queue'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}queue <NICK>
    SYNONYMS: queue, stack
    INFO: Show current work queue for <NICK>, which is represent as
          a LIFO queue (aka stack)
    """
  process: (client, msg) ->
    nick = msg.msg.compact()
    if nick == ''
      nick = msg.sending_nick
    models.queue_contents.create_or_find nick, msg.reply, (contents) ->
      results = JSON.parse contents.contents
      comb = results.join(', ')
      comb = if comb == '' then '<empty>' else comb
      client.say msg.reply, "#{nick}'s current stack: #{comb}"

module.exports =
  plugins: [queue_plugin, qpush_plugin, qpop_plugin]
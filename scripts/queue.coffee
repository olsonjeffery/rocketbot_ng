_ = require 'underscore'
models = {}

queue_item_initialized = false
queue_item_init = (db) ->
  queue_item_initialized = true
  models.queue_item =
    db.sequelize.define('queue_item', {
      id: { type: db.Sql.INTEGER, autoIncrement: true, allowNull: false},
      chan: db.Sql.STRING,
      nick: db.Sql.STRING,
      desc: db.Sql.TEXT
    },
    {
      classMethods: {
        for: (nick, chan, cb) ->
          @findAll({
            order: 'createdAt ASC',
            where: {nick: nick, chan: chan}
          }).success (entries) ->
            cb entries
      }
    })
  models.queue_item.sync()

class qpush_plugin
  constructor: (@options, @db) ->
    if not queue_item_initialized
      queue_item_init @db
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
      models.queue_item.create
        nick: msg.sending_nick
        chan: msg.reply
        desc: item
      client.say msg.reply, "#{msg.sending_nick}: gotcha."
class qpop_plugin
  constructor: (@options, @db) ->
    if not queue_item_initialized
      queue_item_init @db
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
    models.queue_item.for msg.sending_nick, msg.reply, (results) ->
      l = _.last(results);
      desc = l.desc
      l.destroy().success ->
        client.say msg.reply, "Removed \"#{desc}\" from stack."
class queue_plugin
  constructor: (@options, @db) ->
    if not queue_item_initialized
      queue_item_init @db
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
    models.queue_item.for nick, msg.reply, (results) ->
      comb = (_.map results, (r) -> r.desc).join(', ')
      comb = if comb == '' then '<empty>' else comb
      client.say msg.reply, "#{nick}'s current stack: #{comb}"

module.exports =
  plugins: [queue_plugin, qpush_plugin, qpop_plugin]
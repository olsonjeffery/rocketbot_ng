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
      tmp: db.Sql.TEXT
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
              models.queue_contents.create({chan:chan,nick:nick,contents:"[]", tmp:"[]"}).success (entry) ->
                cb entry
        work_on_queue: (nick, chan, cb) ->
          @create_or_find nick, chan, (contents) ->
            queue = JSON.parse contents.contents
            tmp = JSON.parse contents.tmp
            [ new_queue, new_tmp ] = cb(queue, _.first(tmp))
            if not new_tmp?
              new_tmp = ""
            contents.contents = JSON.stringify new_queue
            contents.tmp = JSON.stringify [new_tmp]
            contents.save()
      }
    })
  models.queue_contents.sync()

class qpush_plugin
  constructor: (@options, @db) ->
    if not queue_contents_initialized
      queue_contents_init @db
  name: 'qpush'
  msg_type: 'message'
  version: '2'
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
      models.queue_contents.work_on_queue msg.sending_nick,
        msg.reply, (queue, tmp) ->
          if item == "@"
            item = tmp
            tmp = ""
          queue.push item
          client.say msg.reply, "#{msg.sending_nick}: gotcha."
          [ queue, tmp ]
class qunshift_plugin
  constructor: (@options, @db) ->
    if not queue_contents_initialized
      queue_contents_init @db
  name: 'qunshift'
  msg_type: 'message'
  version: '2'
  commands: ['qunshift']
  match_regex: () ->
    null
  doc_name: 'qunshift'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}qunshift <PHRASE>
    INFO: Unshift <PHRASE> into the beginning of your work stack
    """
  process: (client, msg) ->
    item = msg.msg.compact()
    if item == ''
      client.say msg.reply, "I need something to put into the queue."
    else
      models.queue_contents.work_on_queue msg.sending_nick,
        msg.reply, (queue, tmp) ->
          if item == "@"
            item = tmp
            tmp = ""
          queue.unshift item
          client.say msg.reply, "#{msg.sending_nick}: gotcha."
          [ queue, tmp ]
class qpop_plugin
  constructor: (@options, @db) ->
    if not queue_contents_initialized
      queue_contents_init @db
  name: 'qpop'
  msg_type: 'message'
  version: '2'
  commands: ['qpop']
  match_regex: () ->
    null
  doc_name: 'qpop'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}qpop
    INFO: Pop and return the last item atop your work stack
    """
  process: (client, msg) ->
    models.queue_contents.work_on_queue msg.sending_nick, msg.reply,
        (queue) ->
          desc = queue.pop()
          client.say msg.reply, "Removed \"#{desc}\" from stack."
          [ queue, desc ]
class qshift_plugin
  constructor: (@options, @db) ->
    if not queue_contents_initialized
      queue_contents_init @db
  name: 'qshift'
  msg_type: 'message'
  version: '2'
  commands: ['qshift']
  match_regex: () ->
    null
  doc_name: 'qshift'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}qshift
    INFO: Shift and return the first item on your work stack
    """
  process: (client, msg) ->
    models.queue_contents.work_on_queue msg.sending_nick, msg.reply,
        (queue) ->
          desc = queue.shift()
          client.say msg.reply, "Removed \"#{desc}\" from stack."
          [ queue, desc ]
class qremove_plugin
  constructor: (@options, @db) ->
    if not queue_contents_initialized
      queue_contents_init @db
  name: 'qremove'
  msg_type: 'message'
  version: '2'
  commands: ['qremove']
  match_regex: () ->
    null
  doc_name: 'qremove'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}qremove <INDEX>
    INFO: Remove item from your work stack according to its <INDEX> (as
          shown in the results of #{@options.cmd_prefix}queue).
    """
  process: (client, msg) ->
    idx = parseInt msg.msg.compact()
    models.queue_contents.work_on_queue msg.sending_nick, msg.reply,
        (queue, tmp) ->
          if idx < 0
            client.say msg.reply, "The value of the index must be greater "+
              "than or equal to zero."
            [ queue, tmp ]
          else if idx > queue.length - 1
            client.say msg.reply "The value of the index must be within "+
              "the bounds of the list"
            [ queue, tmp ]
          else
            desc = queue[idx]
            queue.splice(idx,1)
            client.say msg.reply, "Removed \"#{desc}\" from list."
            [ queue, desc ]
class qtmp_plugin
  constructor: (@options, @db) ->
    if not queue_contents_initialized
      queue_contents_init @db
  name: 'qtmp'
  msg_type: 'message'
  version: '2'
  commands: ['qtmp']
  match_regex: () ->
    null
  doc_name: 'qtmp'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}qtmp
    INFO: show contents of tmp buffer in stack (a single value stored
          after qpop or qshift operations).
    """
  process: (client, msg) ->
    models.queue_contents.create_or_find msg.sending_nick,
      msg.reply, (contents) ->
        tmp = _.first(JSON.parse contents.tmp)
        tmp = if not tmp? or tmp == "" then "<empty>" else tmp
        client.say msg.reply, "Contents of tmp buffer: #{tmp}"
class queue_plugin
  constructor: (@options, @db) ->
    if not queue_contents_initialized
      queue_contents_init @db
  name: 'queue'
  msg_type: 'message'
  version: '2'
  commands: ['queue', 'stack', 'list']
  match_regex: () ->
    null
  doc_name: 'queue'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}queue <NICK>
    SYNONYMS: queue, stack, list
    RELATED COMMANDS: qpush, qunshift, qpop, qshift, qremove
    INFO: Show current work queue for <NICK>, which is represented as
    an array with a full range of operations, accessed via the qpop, qpush
    qshift, qunshift and qremove commands
    """
  process: (client, msg) ->
    nick = msg.msg.compact()
    if nick == ''
      nick = msg.sending_nick
    models.queue_contents.create_or_find nick, msg.reply, (contents) ->
      results = JSON.parse contents.contents
      idx = 0
      results = _.map results, (i) ->
        n = "#{idx}: #{i}"
        idx += 1
        n
      comb = results.join(', ')
      comb = if comb == '' then '<empty>' else comb
      client.say msg.reply, "#{nick}'s current stack: #{comb}"

module.exports =
  plugins: [queue_plugin, qpush_plugin, qpop_plugin, qshift_plugin,
            qunshift_plugin, qremove_plugin, qtmp_plugin]
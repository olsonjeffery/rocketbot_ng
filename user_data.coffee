logging = require 'logging'
_ = require 'underscore'

models = {}

user_data_initialized = false
user_data_init = (db) ->
  user_data_initialized = true
  models.user_data =
    db.sequelize.define('user_data', {
      id: { type: db.Sql.INTEGER, autoIncrement: true, allowNull: false},
      nick: db.Sql.STRING,
      puns: db.Sql.INTEGER,
      swears: db.Sql.INTEGER
    },
    {
      classMethods: {
        by_nick: (nick, cb) ->
          @find({
            where: {nick: nick}
          }).success (entry) ->
            cb entry
        top_puns: (cb) ->
          @findAll({
            limit: 5
            order: 'puns DESC'
          }).success (entries) ->
            cb entries
        top_swears: (cb) ->
          @findAll({
            limit: 5
            order: 'swears DESC'
          }).success (entries) ->
            cb entries
      }
    })
  models.user_data.sync()
punish_nick = (pun_nick, client, reply, frag, is_punish) ->
  console.log "in punish_nick()"
  models.user_data.by_nick pun_nick, (ud) ->
    console.log "in put by_nick() cb"
    frag_msg = ""
    if frag?
      frag_msg = "for saying '#{frag}'."
    if ud?
    else
      ud = models.user_data.build
        nick: pun_nick
        puns: 0
        swears: 0
    if is_punish
      ud.puns += 1
    else if ud.puns > 0
      ud.puns -= 1
    ud.save()
    client.say reply, "#{pun_nick} now owes the pun jar "+
      "$#{(ud.puns * 0.25).format(2)} #{frag_msg}."

punshe_common = (client, msg, is_punish) ->
  pun_nick = _.first(msg.msg.compact().split(' '))
  if pun_nick == msg.sending_nick
    plbl = if is_punish then "punish" else "un-punish"
    client.say msg.reply, "Sorry, you can't #{plbl} yourself (as much as "+
      "you probably deserve it)."
    return null
  latest_msg = logging.models.log_entry.latest_entry_for pun_nick, (e) ->
    if e?
      sentence_frag =
        _.rest(msg.msg.compact().split(' ')).join(' ').compact()
      if sentence_frag != null and sentence_frag.length > 0
          cutoff_time = Date.create('2 hours ago')
          console.log "doing frag check for #{pun_nick} with "+
                "'#{sentence_frag}'"
          logging.models.log_entry.entries_for_nick_after(
            pun_nick, cutoff_time, (entries) ->
              console.log "# of entries for user in past 2 hrs: "+
                "#{entries.length}"
              entries = _.filter entries, (e) ->
                e.msg.indexOf(sentence_frag) != -1
              console.log "# of frag-match entries: "+
                "#{entries.length}"
              if entries? and entries.length > 0
                if entries.length == 1
                  entry = _.first(entries)
                  if entry.is_pun and is_punish
                    client.say msg.reply, "Sorry, this comment by "+
                      "#{pun_nick} has already been marked as a pun."
                  else if not entry.is_pun and not is_punish
                    client.say msg.reply, "Sorry, this comment by "+
                      "#{pun_nick} isn't marked as a pun."
                  else
                    entry.is_pun = if is_punish then 1 else 0
                    entry.save()
                    punish_nick pun_nick, client, msg.reply, entry.msg,
                      is_punish
                else
                  client.say msg.reply, "Sorry, #{pun_nick} has said "+
                    "more than one "+
                    "thing matching '#{sentence_frag}' in the past two "+
                    " hours. Try being more specific."
              else
                client.say msg.reply, "#{pun_nick} hasn't said anything"+
                  " matching "+
                  "'#{sentence_frag}' in the past two hours."
          )
      else
          cutoff_time = Date.create('10 minutes ago')
          if e.createdAt > cutoff_time
            punish_nick pun_nick, client, msg.reply, null, is_punish
          else
            client.say msg.reply, "Sorry, I can't give an unattributed "+
              (if is_punish then "punishment " else "un-punishment")+
              "to someone who hasn't spoken in the last ten minutes."
    else
      client.say msg.reply, "I don't even know who #{pun_nick} is, sorry."

class punjar_plugin
  constructor: (plg_ldr, options, @db) ->
    if not user_data_initialized
      user_data_init @db
  name: 'punjar'
  version: '1'
  commands: ['punjar']
  match_regex: () ->
    null
  process: (client, msg) ->
    if msg.msg? and msg.msg.length > 0
      models.user_data.by_nick msg.msg, (ud) ->
        if ud?
          client.say msg.reply, "#{ud.nick} owes the pun jar "+
               "$#{(ud.puns * .25).format(2)}."
        else
          client.say msg.reply, "Sorry, I got nuthin' for #{msg.msg}"
    else
      models.user_data.top_puns (entries) ->
        client.say msg.reply, "Top punsters:"
        ctr = 1
        _.each entries, (e) ->
          client.say msg.reply, "#{ctr}. #{e.nick} - "+
               "$#{(e.puns *.25).format(2)}"
          ctr+=2
class shenanigans_plugin
  constructor: (plg_ldr, options, @db) ->
    if not user_data_initialized
      user_data_init @db
  name: 'shenanigans'
  version: '1'
  commands: ['shenanigans']
  match_regex: () ->
    null
  process: (client, msg) ->
    punshe_common client, msg, false

class puns_plugin
  constructor: (plg_ldr, options, @db) ->
    if not user_data_initialized
      user_data_init @db
  name: 'recent puns'
  version: '1'
  commands: ['puns']
  match_regex: () ->
    null
  process: (client, msg) ->
    if msg.msg? and msg.msg.length > 0
      logging.models.log_entry.recent_puns_from msg.msg, (entries) ->
        if entries? and entries.length > 0
          client.say msg.reply, "Recent puns from #{msg.msg}:"
          _.each entries, (e) ->
            client.say msg.reply, "#{e.createdAt.relative()} "+
               "\"#{e.msg}\""
        else
          client.say msg.reply, "No recorded puns logged from #{msg.msg},"+
            " sorry."
    else
      logging.models.log_entry.recent_puns (entries) ->
        if entries? and entries.length > 0
          client.say msg.reply, "Recent puns:"
          _.each entries, (e) ->
            client.say msg.reply, "#{e.createdAt.relative()} <#{e.nick}> "+
               "#{e.msg}"
        else
          client.say msg.reply, "No recorded puns logged, sorry."

class punish_plugin
  constructor: (plg_ldr, options, @db) ->
    if not user_data_initialized
      user_data_init @db
  name: 'punish'
  version: '1'
  commands: ['pun', 'punish']
  match_regex: () ->
    null
  process: (client, msg) ->
    punshe_common client, msg, true

module.exports =
  models: models
  plugins: [punish_plugin, puns_plugin, shenanigans_plugin, punjar_plugin]
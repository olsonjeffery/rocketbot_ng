_ = require 'underscore'
jsdom = require 'jsdom'
require 'sugar'

scrape = require '../scrape'

models = {}

web_link_initialized = false
web_link_init = (db) ->
  web_link_initialized = true
  models.web_link =
    db.sequelize.define('web_link', {
      id: { type: db.Sql.INTEGER, autoIncrement: true, allowNull: false},
      chan: db.Sql.STRING,
      nick: db.Sql.STRING,
      url: db.Sql.STRING,
      title: db.Sql.TEXT,
      desc: db.Sql.TEXT
    },
    {
      classMethods: {
        latest_links_for: (nick, cb) ->
          @findAll({
            order: 'createdAt DESC',
            limit: 5,
            where: {nick: nick}
          }).success (entries) ->
            cb entries
        latest_links: (cb) ->
          @findAll({
            order: 'createdAt DESC',
            limit: 5
          }).success (entries) ->
            cb entries
      }
    })
  models.web_link.sync()

url_god_regex =
  /((https?:\/\/)?[\w-]+(\.[\w-]+)+\.?(:\d+)?(\/\S*)?)/i

class links_plugin
  constructor: (@options, @db) ->
    if not web_link_initialized
      web_link_init @db
  name: 'links'
  msg_type: 'message'
  version: '1'
  commands: ['links', 'urls']
  match_regex: () ->
    null
  doc_name: 'urls'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}urls <NICK>
    SYNONYMS: urls, links
    INFO: Show recent links that the bot has recorded. Optionally provide
          a <NICK> to narrow the list.
    """
  process: (client, msg) ->
    console.log "msg.msg : #{msg.msg}"
    if msg.msg != ''
      console.log "links for '#{msg.msg}'"
      models.web_link.latest_links_for msg.msg, (links) ->
        if links? and links.length > 0
          client.say msg.reply, "Most recent links from #{msg.msg}:"
          _.each links, (l) ->
            display = if l.desc.indexOf(l.url) == -1
              "#{l.url} - \"#{l.title.unescapeHTML()}\""
            else
              "\"#{l.desc.unescapeHTML()}\""
            client.say msg.reply, "#{display} #{l.createdAt.relative()}"
        else
          client.say msg.reply, "I haven't seen any links from #{msg.msg}"
    else
      console.log "all recent links.."
      models.web_link.latest_links (links) ->
        if links?
          client.say msg.reply, "Recent links:"
          _.each links, (l) ->
            display = if l.desc.indexOf(l.url) == -1
              "#{l.url} - \"#{l.title.unescapeHTML()}\""
            else
              "\"#{l.desc.unescapeHTML()}\""
            client.say msg.reply, "<#{l.nick}> " +
              "#{display} #{l.createdAt.relative()}"
        else
          console.log "Huh. I don't have any saved links. Sorry, dude."

class web_summary_plugin
  constructor: (@options, @db) ->
    if not web_link_initialized
      web_link_init @db
  name: 'web_summary'
  msg_type: 'message'
  version: '1'
  commands: []
  match_regex: () ->
    url_god_regex
  process: (client, msg) ->
    console.log "try to parse url for msg.text '#{msg.text}'"
    url = _.first(msg.text.match(url_god_regex))
    console.log "found url '#{url}'"
    scrape.jq url, ($) ->
      page_title = $('title').text().replace("\n",'') \
                     .replace("\t",'').compact().unescapeHTML()
      client.say msg.reply_to_nick, "\"#{page_title}\""
      desc = $('meta[name="description"]');

      if desc.length > 0
        console.log 'has meta'
        client.say msg.reply_to_nick, "\"#{$(desc[0]).attr('content').unescapeHTML()}\""

      models.web_link.create
        chan: msg.reply
        nick: msg.sending_nick
        url: url
        title: page_title
        desc: msg.text

module.exports =
  plugins: [web_summary_plugin, links_plugin]
  models: models
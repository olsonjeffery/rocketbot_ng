_ = require 'underscore'
jsdom = require 'jsdom'
scrape = require 'scrape'
require 'sugar'

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
  constructor: (plg_ldr, options, @db) ->
    if not web_link_initialized
      web_link_init @db
  name: 'links'
  msg_type: 'message'
  version: '1'
  commands: ['links']
  match_regex: () ->
    null
  process: (client, msg) ->
    console.log "msg.msg : #{msg.msg}"
    if msg.msg != ''
      console.log "links for '#{msg.msg}'"
      models.web_link.latest_links_for msg.msg, (links) ->
        if links? and links.length > 0
          client.say msg.reply, "Most recent links from #{msg.msg}:"
          _.each links, (l) ->
            client.say msg.reply, "#{l.createdAt.relative()} #{l.url} -- "+
              "\"#{l.title}\""
        else
          client.say msg.reply, "I haven't seen any links from #{msg.msg}"
    else
      console.log "all recent links.."
      models.web_link.latest_links (links) ->
        if links?
          client.say msg.reply, "Recent links:"
          _.each links, (l) ->
            client.say msg.reply, "#{l.createdAt.relative()} from " +
              "#{l.nick}: #{l.url} -- \"#{l.title}\""
        else
          console.log "Huh. I don't have any saved links. Sorry, dude."

class web_summary_plugin
  constructor: (plg_ldr, options, @db) ->
    if not web_link_initialized
      web_link_init @db
  name: 'url summary'
  msg_type: 'message'
  version: '1'
  commands: []
  match_regex: () ->
    url_god_regex
  process: (client, msg) ->
    console.log "try to parse url for msg.text '#{msg.text}'"
    url = _.first(msg.text.match(url_god_regex))
    console.log "found url '#{url}'"
    scrape.single url, (body, window) ->
      $ = require('jquery').create(window)
      page_title = $('title').text().replace("\n",'') \
                     .replace("\t",'').compact()
      client.say msg.reply_to_nick, "\"#{page_title}\""
      desc = $('meta[name="description"]');
      desc_txt = ''

      if desc.length > 0
        console.log 'has meta'
        desc_txt = desc.attr('content') \
          .truncate(250)
        client.say msg.reply_to_nick, "\"#{desc_txt}\""
      else
        console.log 'no meta..'

      models.web_link.create
        chan: msg.reply
        nick: msg.sending_nick
        url: url
        title: page_title
        desc: desc_txt

module.exports =
  plugins: [web_summary_plugin, links_plugin]
  models: models
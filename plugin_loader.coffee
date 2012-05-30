_ = require 'underscore'
jsdom = require 'jsdom'
fs = require 'fs'
scrape = require 'scrape'

class name_check_plugin
  constructor: (plg_ldr, options) ->
    @bot_nick = options.nick
    console.log "stored bot nick #{@bot_nick}"
  name: 'name check'
  version: '1'
  commands: []
  match_regex: ->
    console.log 'returning match_regex w/ bot_nick of "'+@bot_nick+'"'
    ///#{@bot_nick}///
  process: (client, msg) ->
    console.log "SOMEONE SAID MY NAME"
    client.say msg.reply_to_nick, "#{msg.sending_nick}: hello"

url_god_regex =
  /((https?:\/\/)?[\w-]+(\.[\w-]+)+\.?(:\d+)?(\/\S*)?)/i

class url_summary_plugin
  constructor: (plg_ldr, options) ->
  name: 'url summary'
  version: '1'
  commands: []
  match_regex: () ->
    url_god_regex
  process: (client, msg) ->
    console.log "try to parse url for msg.text '#{msg.text}'"
    url = _.first(msg.text.match(url_god_regex))
    console.log "found url '#{url}'"
    scrape.single url, (window, $) ->
      client.say msg.reply_to_nick,
                 '"'+$('title').text().replace("\n",'') \
                     .replace("\t",'').compact()+'"'
      desc = $('meta[name="description"]');
      if desc.length > 0
        console.log 'has meta'
        client.say msg.reply_to_nick, '"'+desc.attr('content') \
          .truncate(250)+'"';
      else
        console.log 'no meta..'

plugin_loader =
  init: (options) ->
    # get list of plugins
    plugins = [name_check_plugin, url_summary_plugin]
    # initialize them all..
    @plugins = _.map plugins, (plg) =>
      new plg(this, options)

module.exports = plugin_loader

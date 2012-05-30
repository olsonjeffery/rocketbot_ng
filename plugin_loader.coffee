_ = require 'underscore'
jsdom = require 'jsdom'
fs = require 'fs'
plugin_loader = {}

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

jq_src = fs.readFileSync("jquery-min.js").toString();
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
    jsdom.env(
      html: url, src: [ jq_src ],
      done: (err, window) ->
        console.log 'in done callback for url summary web req'
        if err
          console.log "failed loading url of '#{url}'"
        else
          console.log 'valid response'
          $ = window.$
          console.log "has jquery object #{$}"
          title = $('title').val()
          console.log 'about to send irc chan msg...'
          client.say msg.reply_to_nick, "#{title}"
    )

plugin_loader.init = (options) ->
  # get list of plugins
  plugins = [name_check_plugin, url_summary_plugin]
  # initialize them all..
  @plugins = _.map plugins, (plg) =>
    new plg(this, options)

module.exports = plugin_loader

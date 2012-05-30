_ = require 'underscore'
jsdom = require 'jsdom'
scrape = require 'scrape'

url_god_regex =
  /((https?:\/\/)?[\w-]+(\.[\w-]+)+\.?(:\d+)?(\/\S*)?)/i

class web_summary
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
    scrape.single url, (body, window) ->
      $ = require('jquery').create(window)
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

module.exports = web_summary
scrape = require '../scrape'


class ud_plugin
  constructor: (plg_ldr, @options, @db) ->
  name: 'ud'
  msg_type: 'message'
  version: '1'
  commands: ['ud']
  match_regex: () ->
    null
  process: (client, msg) ->
    raw_term = msg.msg.compact()
    term = raw_term.replace(" ", "+")
    if term == ''
      client.say msg.reply, "I need something to look up, dude."
    else
      ud_search_url =
        "http://www.urbandictionary.com/define.php?term=#{term}"
      scrape.single ud_search_url, (body, window) ->
        $ = require('jquery').create(window)
        console.log "checking if exists"
        if $('.definition').length == 0
          console.log "no matching ud term found"
          client.say msg.reply, "Sorry, '#{raw_term}' isn't defined yet."
          return null
        raw_stuff = $($('.definition')[0]).text()
        stuff = raw_stuff.replace('\r', '. ').truncate(400)
        console.log "match found, about to say: #{stuff}"
        if raw_stuff.length >= 400
          client.say msg.reply, "You can, um, \"learn\" more at: "+
            "#{ud_search_url}"
        client.say msg.reply,
          "\""+stuff+"\""

module.exports =
  plugins: [ud_plugin]
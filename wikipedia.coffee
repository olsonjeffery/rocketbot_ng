scrape = require 'scrape'
jsdom = require('jsdom').jsdom

class wikipedia
  constructor: (plg_ldr, options) ->
  name: 'wikipedia'
  version: '1'
  commands: [ 'wiki' ]
  match_regex: ->
    null
  process: (client, msg) ->
    page = msg.msg.replace(' ', '%20')
    url = "http://en.wikipedia.org/w/api.php?format=json&action=parse"+
            "&prop=text&page=#{page}&redirects"
    scrape.single url, (body) ->
      wiki = JSON.parse(body)
      if wiki.error?
        client.say msg.reply,
          "Error doing wikipedia search: #{wiki.error.info}"
      else
        wiki_body = """
        <html>
        <head><title>wiki</title></head>
        <body><div>#{wiki.parse.text['*']}</div></body>
        </html>
        """
        window = jsdom(wiki_body).createWindow()
        $ = require('jquery').create(window)
        first_graf = $('p:first').text()
        if first_graf?
          client.say msg.reply, "\"#{first_graf}\"".truncate(499)
        else
          client.say msg.reply, "no data found. hm."

module.exports = wikipedia

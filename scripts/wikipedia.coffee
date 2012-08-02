jsdom = require('jsdom').jsdom

scrape = require '../scrape'

wikimedia_search = (url, client, msg, page_url) ->
  scrape.json url, (wiki) ->
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
        client.say msg.reply, "\"#{first_graf.truncate(400)}\""
        client.say msg.reply, "Learn more at: #{page_url}"
      else
        client.say msg.reply, "no data found. hm."

class conservapedia_plugin
  constructor: (@options) ->
  name: 'wikipedia'
  msg_type: 'message'
  version: '1'
  commands: [ 'cp' ]
  match_regex: ->
    null
  doc_name: 'conservapedia'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}cp <TERM>
    INFO: Search conservapedia.com for the provided <TERM>.
          It's rather finnicky.
    """
  process: (client, msg) ->
    page = msg.msg.replace(' ', '%20')
    url = "http://conservapedia.com/api.php?format=json&action="+
      "parse&prop=text&redirects&page=#{page}"
    page_url = "http://conservapedia.com/#{page}"
    wikimedia_search url, client, msg, page_url
class wikipedia_plugin
  constructor: (@options) ->
  name: 'wikipedia'
  msg_type: 'message'
  version: '1'
  commands: [ 'wiki' ]
  match_regex: ->
    null
  doc_name: 'wikipedia'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}wiki <TERM>
    INFO: Search en.wikipedia.org for the provided <TERM>.
          It's rather finnicky.
    """
  process: (client, msg) ->
    page = msg.msg.replace(' ', '%20')
    url = "http://en.wikipedia.org/w/api.php?format=json&action=parse"+
            "&prop=text&page=#{page}&redirects"
    page_url = "http://en.wikipedia.org/wiki/#{page}"
    wikimedia_search url, client, msg, page_url
module.exports =
  plugins: [wikipedia_plugin, conservapedia_plugin]

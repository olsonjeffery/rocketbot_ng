scrape = require '../scrape'

class spell_plugin
  constructor: (@options) ->
  name: 'spell'
  msg_type: 'message'
  version: '1'
  commands: [ 'spell', 'speel' ]
  match_regex: ->
    null
  doc_name: 'spell'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}spell <TERM>
    SYNONUMS: spell, speel
    INFO: Check duckduckgo to see if a word is spelled right
    """
  process: (client, msg) ->
    word = msg.msg.compact()
    if word == ''
      client.say msg.reply, "Yo. Need a word to check, brah."
    else
      search_url = "https://www.duckduckgo.com/?q=!spell+#{word}"
      scrape.jq search_url, ($) ->
        e = $('.zero_click_answer')
        if e.length == 1
          result_text = e.text().compact()
          client.say msg.reply, result_text
        else
          client.say msg.reply, "That word is spelled so wrong that "+
            "I have no clue where to even start."

module.exports =
  plugins: [spell_plugin]
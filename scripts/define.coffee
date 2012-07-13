scrape = require '../scrape'
_ = require 'underscore'

class define_plugin
  constructor: (@options) ->
  name: 'define'
  msg_type: 'message'
  version: '1'
  commands: [ 'd', 'define' ]
  match_regex: ->
    null
  doc_name: 'define'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}define <TERM>
    SYNONYMS: define, d
    INFO: Search freedictionary.com for the definition of a term
    """
  process: (client, msg) ->
    word = msg.msg.compact()
    if word == ''
      client.say msg.reply, "Dude, I need a word to search for."
      return null
    search_url = "http://dictionary.reference.com/browse/#{word}"
    scrape.jq search_url, ($) ->
      if $('body').text().indexOf('no dictionary results') != -1
        client.say msg.reply, "Sorry, couldn't find the spelling "+
          "for '#{word}' on dictionary.reference.com"
      else
        results = _.map $('.results_content .pbk:first .luna-Ent'),
          (item) ->
            $(item).text()
        output = results.sort().join(', ').truncate(400)
        client.say msg.reply, "Definition(s) for #{word}: #{output}"
        client.say msg.reply, "You can learn more at: #{search_url}"

module.exports =
  plugins: [define_plugin]
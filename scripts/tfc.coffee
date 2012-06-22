scrape = require '../scrape'

class tfc_plugin
  constructor: (@options) ->
  name: 'github'
  msg_type: 'message'
  version: '1'
  commands: [ 'tfc', 'theyfightcrime', 'pr0n', 'theymakeporn']
  match_regex: ->
    null
  doc_name: 'theyfightcrime'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}theyfightcrime
    SYNONYMS: theyfightcrime, tfc
    INFO: a WAAACCKY message from theyfightcrime.org
    """
  process: (client, msg) ->
    scrape.single 'http://www.theyfightcrime.org', (body, window) ->
      $ = require('jquery').create (window)
      content = $($('table p')[0]).text().compact()
      if msg.command == 'theymakeporn' or msg.command == 'pr0n'
        console.log 'porn!'
        content = content.replace(/fight crime/, 'make porn')
      client.say msg.reply, content

module.exports =
  plugins: [tfc_plugin]

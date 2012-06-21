scrape = require '../scrape'

class etym_plugin
  constructor: (@options) ->
  name: 'etym'
  msg_type: 'message'
  version: '1'
  commands: [ 'etym' ]
  match_regex: ->
    null
  doc_name: 'etym'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}etym <TERM>
    INFO: Search etymologyonline.com for the provided <TERM>.
    """
  process: (client, msg) ->
    url = "http://www.etymonline.com/index.php?allowed_in_frame=0&search=#{msg.msg.compact().replace(' ', '%20')}&searchmode=none"
    scrape.single url, (body, window) ->
      $ = require('jquery').create(window)
      definition = $('dd:first').text().compact()
      console.log "definition from #{url}: #{definition}"
      if definition.length > 0
        client.say msg.reply, "\"#{definition.truncate(400)}\""
      else
        client.say msg.reply, "No matching search results on etymonline.com for \"#{msg.msg.compact()}\""
      if definition.length > 450
        client.say msg.reply, "Read more at: #{url}"

module.exports =
  plugins: [etym_plugin]

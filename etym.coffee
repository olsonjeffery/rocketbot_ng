scrape = require 'scrape'


class etym
  constructor: (plg_ldr, options) ->
  name: 'etym'
  version: '1'
  commands: [ 'etym' ]
  match_regex: ->
    null
  process: (client, msg) ->
    url = "http://www.etymonline.com/index.php?allowed_in_frame=0&search=#{msg.msg.replace(' ', '%20')}&searchmode=none"
    scrape.single url, (body, window) ->
      $ = require('jquery').create(window)
      definition = $('dd:first').text()
      console.log "definition from #{url}: #{definition}"
      client.say msg.reply, "\"#{definition.truncate(499)}\""
      if definition.length > 499
        client.say msg.reply, "Learn more at: #{url}"

module.exports = etym

scrape = require '../scrape'

class btc_plugin
  constructor: (@options) ->
  name: 'btc'
  msg_type: 'message'
  version: '1'
  commands: ['btc']
  match_regex: () ->
    null
  doc_name: 'btc'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}btc
    INFO: Get the weighted average value of BTC in USD from Mt. Gox
    """
  process: (client, msg) ->
    scrape.jq "http://www.mtgox.com", ($) ->
      #console.log "body: "+$('body').html()
      lines = $('div.ticker').html().split('\n')
      data = {}
      for l in lines
        l = l.compact()
        if l.startsWith('<li id="')
          node = $(l)
          data[node.attr('id')] = node.text()
      client.say msg.reply, "Mt Gox: #{data.lastPrice} | #{data.highPrice} | #{data.lowPrice} | #{data.volume} | #{data.weightedAverage}"


module.exports =
  plugins: [btc_plugin]
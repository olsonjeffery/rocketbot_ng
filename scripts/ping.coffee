ping = require 'ping'

class ping_plugin
  constructor: (@options) ->
  name: 'ping'
  msg_type: 'message'
  version: '1'
  commands: [ 'ping' ]
  match_regex: ->
    null
  doc_name: 'ping'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}ping <HOSTNAME>
    INFO: check is the provided <HOSTNAME> is up
    """
  process: (client, msg) ->
    host = msg.msg.replace(' ', '')
    ping.sys.probe host, (isAlive) ->
      if isAlive
        client.say msg.reply, "#{host} is up."
      else
        client.say msg.reply, "#{host} is not responding."

module.exports =
  plugins: [ping_plugin]
class iching_plugin
  constructor: (@options) ->
  name: 'dice'
  msg_type: 'message'
  version: '1'
  commands: ['iching']
  match_regex: () ->
    null
  doc_name: 'iching'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}iching <QUESTION>
    INFO: Let rocketbot whip up some hexagrams to interpret the
          provided <QUESTION>.
    """
  process: (client, msg) ->
    client.say msg.reply, "\u4dc0 \u4dff"

module.exports =
  plugins: [iching_plugin]
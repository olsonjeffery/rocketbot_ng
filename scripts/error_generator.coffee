rbu = require '../rb_util'
class error_generator_plugin
  constructor: (@options) ->
  name: 'error_gen'
  msg_type: 'message'
  version: '1'
  commands: ['error_gen']
  match_regex: () ->
    null
  doc_name: 'error_gen'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}error_gen
    INFO: throws an exception. used to test error catching subsystems.
    """
  process: (client, msg) ->
    rbu.admin_only msg.sending_nick, client, @options, ->
      error_token = rbu.rand 1000
      console.log "ERROR_GEN: going to genereate an error with token of #{error_token}"
      client.say msg.reply, "GENERATING NEW ERROR #{error_token}"
      throw "GENERATED NEW ERROR #{error_token}"

module.exports =
  plugins: [error_generator_plugin]
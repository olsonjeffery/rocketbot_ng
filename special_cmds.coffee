_ = require 'underscore'
child_process = require 'child_process'
rb_util = require './rb_util'

recycle =
  names: ['recycle']
  process: (client, master, options, msg) ->
    console.log 'about to send WHOIS..'
    rb_util.is_admin msg.sending_nick,
      client,
      options,
      (user_is_admin) ->
        if user_is_admin
          master.emit 'cycle_sandbox', {chan: msg.reply}
        else
          client.say msg.reply, "Only admins can recycle the sandbox."
docs =
  names: ['help', 'docs']
  process: (client, master, options, msg) ->
    master.emit 'process_docs', msg

module.exports = [
  recycle, docs
]
_ = require 'underscore'
require 'sugar'

module.exports = (sending_nick, reply_to_nick, cmd_prefix, text) ->
  has_command = text.startsWith(cmd_prefix)
  msg_parts = text.split(' ')
  first_part = _.first msg_parts
  cmd_val = if has_command
    first_part.from(1)
  else
    ''
  msg = _.rest(msg_parts).join(' ').compact()
  return {
    text: text
    sending_nick: sending_nick
    reply_to_nick: reply_to_nick
    reply: reply_to_nick
    has_command: has_command
    command: cmd_val
    msg: msg
  }
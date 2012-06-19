_ = require 'underscore'
child_process = require 'child_process'

recycle =
  name: 'recycle'
  process: (master, options, parsed_msg) ->
    master.emit 'cycle_sandbox', {chan: parsed_msg.reply}

module.exports = [
  recycle
]
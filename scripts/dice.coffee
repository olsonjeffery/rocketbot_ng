_ = require 'underscore'
rbu = require '../rb_util'

class dice_plugin
  constructor: (@options) ->
  name: 'dice'
  msg_type: 'message'
  version: '1'
  commands: ['dice', 'roll']
  match_regex: () ->
    null
  doc_name: 'dice'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}dice <DICENUM>d<DICESIDES>
    SYNONYMS: roll, dice
    INFO: Roll a <DICESIDES>-sided die <DICENUM> times
    """
  process: (client, msg) ->
    out = msg.msg.compact().toLowerCase().split('d')
    nums = _.map(out, (i) -> parseInt(i))
    garbage = false
    if out.length != 2
      client.say msg.reply, "Dice-rolling format is: 1d6 where 1 is the "+
        "number of rolls and 6 is the sidedness of the die"
      garbage = true
    _.each nums, (n) ->
      if isNaN(n) and not garbage
        garbage = true
        client.say msg.reply, "Garbage input. Integers only, please."
      else if n < 1 and not garbage
        garbage = true
        client.say msg.reply, "Garbage input. Numbers greater than zero, "+
          "jerk."
    if not garbage
      results = []
      _.times nums[0], ->
        results.push rbu.rand(nums[1])+1
      output = results.join(", ")
      client.say msg.reply, "Results: #{output}"

module.exports =
  plugins: [dice_plugin]
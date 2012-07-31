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
    die_rolls = nums[0]
    die_sides = nums[1]
    if die_rolls > 20 and not garbage
      client.say msg.reply, "We don't roll more than 20 times, 'round "+
        "these parts"
      garbage = true
    if die_sides > 100 and not garbage
      client.say msg.reply, "Can't roll a die with more than 100 sides, "+
        "sorry"
      garbage = true
    if die_sides == 1 and not garbage
      client.say msg.reply, "Why the hell would you roll a 1-sided die? "+
        "Are you some kind of smartass?"
      garbage = true

    if not garbage
      results = []
      _.times die_rolls, ->
        results.push rbu.rand(die_sides)+1
      output = results.join(", ")
      client.say msg.reply, "Results: #{output}"

module.exports =
  plugins: [dice_plugin]
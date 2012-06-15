
last_truth_telling = null

class paulistine_plugin
  constructor: (plg_ldr, options, @db) ->
  name: 'paulistine'
  msg_type: 'message'
  version: '1'
  commands: ['paulistine']
  match_regex: () ->
    null
  process: (client, msg) ->
    an_hour_ago = Date.create('1 hour ago')
    if last_truth_telling == null or an_hour_ago > last_truth_telling
      last_truth_telling = new Date()
      timer_delay = 3000
      part_one = ->
        client.say msg.reply, "The year is 2031."
        setTimeout part_two, timer_delay
      part_two = ->
        client.say msg.reply, "You've managed to escape from the FEMA camp you were forced into after a false flag dirty bomb attack was used to enact nation wide martial law."
        setTimeout part_three, timer_delay
      part_three = ->
        client.say msg.reply, "As you run desperately toward the horizon you choke on the air full of aluminum oxide. Routine chem trailing ensures that only Monsanto's genetically modified creations grow, preventing criminal dissidents from growing their own food supply."
        setTimeout part_four, timer_delay
      part_four = ->
        client.say msg.reply, "As you reach the top of a small hill you come face to face with the military's latest patrol-bot. In a fraction of a second the machine's sophisticated camera and computer system analyze your face and scan the biometric data in your subdermal implant. Immediately the drone opens fire, cutting you down in a hail of bullets that were manufactured in China."
        setTimeout part_five, timer_delay
      part_five = ->
        client.say msg.reply, "As you sputter out your final breath your one final thought is, \"If only I had voted for Ron Paul…\""
      part_one()
    else
      client.say msg.reply, "Sorry, Dr. Paul says too much TRUTH can be "+
        "dangerous to the health of the uninitiated."
module.exports =
  plugins: [paulistine_plugin]
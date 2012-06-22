_ = require 'underscore'
rbu = require '../rb_util'

fhlh_quotes = [
  "Go, I say go away boy, you bother me.",
  "His muscles are as soggy as a used tea bag.",
  "That boy’s about as sharp as a bowling ball.",
  "I keep pitchin’ ‘em and you keep missin’ ‘em.",
  "That boy’s as timid as a canary at a cat show.",
  "That woman’s as cold as a nudist on an iceberg.",
  "Nice mannered kid, just a little on the dumb side.",
  "That kid’s about as sharp as a pound of wet liver.",
  "Nice girl, but about as sharp as a sack of wet mice.",
  "Nice boy but he’s got more nerve than a bum tooth.",
  "Pay attention, boy, I’m cuttin’ but you ain’t bleedin’!",
  "Smart boy, got a mind like a steel trap – full of mice.",
  "Oh, that woman, got a mouth like an outboard motor.",
  "That dog’s like taxes, he just don’t know when to stop.",
  "That boy’s as strong as an ox, and just about as smart.",
  "Boy’s gotta mouth like a cannon, always shootin’ it off.",
  "This boy’s more mixed up than a feather in a whirlwind.",
  "That dog, I say that dog’s strictly GI – gibberin idiot that is.",
  "That, I say that boy’s just like a tatoo, gets under your skin.",
  "That dog, I say that dog is lower than a snake full of buckshot.",
  "That dog’s as subtle as a hand grenade in a barrrel of oat meal.",
  "Boy, you cover about as much as a flapper’s skirt in a high wind.",
  "Pay attention to me boy! I’m not just talkin’ to hear my head roar.",
  "Now cut that out boy, or I’ll spank you where the feathers are thinnest.",
  "Look sister is any of this filterin’ through that little blue bonnet of yours.",
  "I got, I say I got this boy as fidgety as a bubble dancer with a slow leak.",
  "Stop, I say stop it boy, you’re doin’ alot of choppin’ but no chips are flyin’.",
  "This is going to cause more confusion than a mouse in a burlesque show.",
  "What in the, I say what in the name of Jesse James do you suppose that is.",
  "Gal reminds me of a highway between Forth Worth and Dallas – no curves.",
  "Now what, I say what’s the big idea bashin’ me in the bazooka that-a-way boy!",
  "Now who’s, I say who’s responsible for this unwarranted attack on my person!",
  "This boy’s making more noise than a couple of skeletons throwin’ a fit on a tin roof.",
  "Now that, I say that’s no way for a kid to be wastin’ his time, readin’ that long-haired gobbledegook.",
  "It’s sure, I say it’s sure quiet around here, you could hear a caterpillar sneakin’ across a moss bed in tennis shoes.",
  "The snow, I say the snow’s so deep the farmers have to jack up the cows so they can milk’em."
]


class isay_plugin
  constructor: (@options) ->
  name: 'isay'
  msg_type: 'message'
  version: '1'
  commands: [ 'isay', 'i say', 'foghorn', 'leghorn' ]
  match_regex: ->
    null
  doc_name: 'isay'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}isay
    INFO: provides a witty retort, courtesy of your favorite rooster.
    """
  process: (client, msg) ->
    client.say msg.reply, fhlh_quotes[rbu.rand(fhlh_quotes.length)]

module.exports =
  plugins: [isay_plugin]
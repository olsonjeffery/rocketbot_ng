_ = require 'underscore'
jsdom = require 'jsdom'
scrape = require 'scrape'

models = {}
webdip_game_initialized = false
webdip_game_init = (db) ->
  webdip_game_initialized = true
  models.webdip_game =
    db.sequelize.define('webdip_game', {
      id: { type: db.Sql.INTEGER, autoIncrement: true, allowNull: false},
      game_id: db.Sql.STRING,
      short_name: db.Sql.STRING
    },
    {
      classMethods: {
        by_short_name: (short_name, cb) ->
          @find({
            where: {short_name: short_name}
          }).success (game) ->
            cb game
        by_game_id: (game_id, cb) ->
          @find({
            where: {game_id: game_id}
          }).success (game) ->
            cb game
        all: (cb) ->
          @all().success (entries) ->
            cb entries
      }
    })
  models.webdip_game.sync()

webdip_url = "http://www.webdiplomacy.net/board.php?gameID="
class webdip_newdip_plugin
  constructor: (plg_ldr, @options, @db) ->
    if not webdip_game_initialized
      webdip_game_init @db
  name: 'newdip'
  version: '1'
  commands: ['newdip']
  match_regex: () ->
    null
  process: (client, msg) ->
    inputs = msg.msg.split(' ')
    if inputs.length != 2
      client.say msg.reply, "Sorry, '#{msg.msg}' is not a valid input to "+
       "start watching a web diplomacy game. the 'short name' for the game"+
       " needs to be a single word with no spaces."
    else
      [game_id, short_name] = inputs
      game_url = webdip_url + game_id
      self = this
      models.webdip_game.by_short_name short_name, (g) ->
        if g?
          client.say msg.reply, "Sorry, there's already a game called "+
            "#{short_name}."
        else
          models.webdip_game.by_game_id game_id, (g2) ->
            if g2?
              client.say msg.reply, "Sorry, I'm already following web "+
                "diplomacy game ##{game_id}."
            else
              scrape.single game_url, (body, window) ->
                $ = require('jquery').create(window)
                valid_game = $('span.gameName').length == 1
                if valid_game
                  game_name = $('span.gameName').text()
                  models.webdip_game.create
                    game_id:game_id
                    short_name:short_name
                  console.log "after creating new webdip_game entry for"+
                   " #{game_id}"
                  client.say msg.reply, "Okay! I'm now following "+
                    "#{game_name}. You"+
                    " can check its current status, at any time, by "+
                     "typing '#{self.options.cmd_prefix}webdip "+
                     "#{short_name}'."
                else
                  client.say msg.reply, "Sorry, it appears that there"+
                  " isn't a game at www.webdiplomacy.net with an id "+
                  "matching #{game_id}"

class webdip_rmdip_plugin
  constructor: (plg_ldr, @options, @db) ->
    if not webdip_game_initialized
      webdip_game_init @db
  name: 'rmdip'
  version: '1'
  commands: ['rmdip']
  match_regex: () ->
    null
  process: (client, msg) ->
    short_name = msg.msg
    models.webdip_game.by_short_name short_name, (g) ->
      if g?
        g.destroy()
        client.say msg.reply, "Alright, I'm no longer following "+
          "#{short_name}."
      else
        client.say msg.reply, "Sorry, I'm not tracking any diplomacy games"+
         " named #{short_name}."

class webdip_dip_plugin
  constructor: (plg_ldr, @options, @db) ->
    if not webdip_game_initialized
      webdip_game_init @db
  name: 'dip'
  version: '1'
  commands: ['dip']
  match_regex: () ->
    null
  process: (client, msg) ->
    short_name = msg.msg
    models.webdip_game.by_short_name short_name, (g) ->
      if g?
        game_url = webdip_url + g.game_id
        scrape.single game_url, (body, window) ->
          $ = require('jquery').create(window)
          valid_game = $('span.gameName').length == 1
          if valid_game
            game_name = $('span.gameName').text()
            game_date = $('span.gameDate').text()
            game_phase = $('span.gamePhase').text()
            time_remaining = $('span.timeremaining').text()
            client.say msg.reply, "#{game_name} - #{game_date}, "+
             "#{game_phase} - Next: #{time_remaining} || Player Statuses:"
            iterator = (e) ->
              member_row = $(e)
              status_alt = member_row.find(
                '.memberCountryName img').attr('alt')
              status = if status_alt == 'Ready'
                'Orders Ready'
              else if status_alt == 'Completed'
                'Orders Saved'
              else
                'No Orders'
              country_name = $(member_row.find(
                '.memberCountryName span')[1]).text()
              player_name = member_row.find('span.memberName a').text()
              sc_count = $(member_row.find(
                'span.memberSCCount em')[0]).text()
              unit_count = $(member_row.find(
                'span.memberSCCount em')[1]).text()
              worth = $(member_row.find(
                'span.memberPointsCount em')[1]).text()
              client.say msg.reply,
                "<#{player_name}> #{country_name} -- "+
                "#{status} SC: #{sc_count} U: #{unit_count} "+
                "W: #{worth}"
            _.each($('tr.member'), iterator)
          else
            client.say msg.reply, "It appears that #{short_name} is no "+
             "an active game on www.webdiplomacy.net. Did the game end "+
             "or get deleted?"
      else
        client.say msg.reply, "Sorry, I'm not tracking any diplomacy games"+
         " named #{short_name}."

module.exports =
  plugins: [webdip_newdip_plugin, webdip_rmdip_plugin, webdip_dip_plugin]
  models: models

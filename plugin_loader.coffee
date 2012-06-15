_ = require 'underscore'

weather = require 'weather'
web_summary = require 'web_summary'
wikipedia = require 'wikipedia'
etym = require 'etym'
logging = require 'logging'
user_data = require 'user_data'
webdip = require 'webdip'
topic = require 'topic'

plugin_loader =
  init: (options, db) ->
    console.log "initializing plugins..."
    # get list of plugins
    plugins = _.flatten([
      web_summary.plugins,
      weather.plugins,
      wikipedia.plugins,
      etym.plugins,
      logging.plugins,
      user_data.plugins,
      webdip.plugins,
      topic.plugins
    ])
    # initialize them all..
    @plugins = _.map plugins, (plg) =>
      new plg(this, options, db)
  process: (client, msg_type, parsed_msg) ->
    _.each @plugins, (plg) ->
      if plg.msg_type == msg_type
        match_regex = plg.match_regex()
        if parsed_msg.has_command and plg.commands.length > 0
          console.log "incoming msg has_command #{parsed_msg.command}"
          match_cmd = _.detect plg.commands, (cmd) ->
            cmd == parsed_msg.command
          if match_cmd
            console.log "cmd match"
            plg.process client, parsed_msg
        else if match_regex? and match_regex.test parsed_msg.text
          console.log "regex match!"
          plg.process client, parsed_msg
        else
          console.log "no matching-cmd or match regex..."

module.exports = plugin_loader

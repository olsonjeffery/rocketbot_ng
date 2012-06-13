_ = require 'underscore'

weather = require 'weather'
web_summary = require 'web_summary'
wikipedia = require 'wikipedia'
etym = require 'etym'
logging = require 'logging'
user_data = require 'user_data'
webdip = require 'webdip'

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
      webdip.plugins
    ])
    # initialize them all..
    @plugins = _.map plugins, (plg) =>
      new plg(this, options, db)

module.exports = plugin_loader

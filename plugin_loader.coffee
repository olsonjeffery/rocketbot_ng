_ = require 'underscore'

weather = require 'weather'
web_summary = require 'web_summary'
wikipedia = require 'wikipedia'
etym = require 'etym'

plugin_loader =
  init: (options, sequelize) ->
    console.log "initializing plugins..."
    # get list of plugins
    plugins = _.flatten([
      web_summary.plugins,
      weather.plugins,
      wikipedia.plugins,
      etym.plugins
    ])
    # initialize them all..
    @plugins = _.map plugins, (plg) =>
      new plg(this, options, sequelize)

module.exports = plugin_loader

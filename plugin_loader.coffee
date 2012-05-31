_ = require 'underscore'

weather = require 'weather'
web_summary = require 'web_summary'
wikipedia = require 'wikipedia'

plugin_loader =
  init: (options) ->
    # get list of plugins
    plugins = [web_summary, weather, wikipedia]
    # initialize them all..
    @plugins = _.map plugins, (plg) =>
      new plg(this, options)

module.exports = plugin_loader

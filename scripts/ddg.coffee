scrape = require '../scrape'
_ = require 'underscore'

class duckduckgo_plugin
  constructor: (@options, db, @hook) ->
  name: 'duckduckgo'
  msg_type: 'message'
  version: '1'
  commands: [ 'duckduckgo', 'ddg' ]
  match_regex: ->
    null
  doc_name: 'duckduckgo'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}ddg <TERM>
    INFO: Search duckduckgo for the provided <TERM>, returning the
          link and web summary for the top result.
    """
  process: (client, msg) ->
    url = "https://duckduckgo.com/html/?q=#{msg.msg.compact()}"
    scrape.jq url, ($) =>
      top_url = $('.results_links_deep:first a.large').attr('href');
      client.say msg.reply, "Top result in duckduckgo: #{top_url}"
      @hook.emit 'web_summary::new_link',
        url: top_url
        chan: msg.reply
        nick: msg.sending_nick
        desc: msg.text
        save: false

module.exports =
  plugins: [duckduckgo_plugin]

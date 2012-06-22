scrape = require '../scrape'
_ = require 'underscore'

search_base_url = 'http://search.twitter.com/search.json?q='

class twitter_search_plugin
  constructor: (@options) ->
  name: 'twitter_search'
  msg_type: 'message'
  version: '1'
  commands: [ 'tsearch', 'ts', 'twitter' ]
  match_regex: ->
    null
  doc_name: 'twitter_search'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}tsearch <QUERY>
    SYNONYMS: tsearch, ts, twitter
    INFO: search the Twitter public API for <QUERY>, showing RECENT results.
    NOTE: The twitter public API only returns recent results. So if you
          query against a user who hasn't tweeted in several months, you'll
          get nothing back :/
    You can find more information about the Twitter search API at:
    https://dev.twitter.com/docs/using-search
    Under the 'Search Operators' section.
    """
  process: (client, msg) ->
    query = msg.msg.compact()
    if query == ''
      client.say msg.reply, "You need to provide something for me to "+
        "query against."
      return null
    if query.startsWith('@')
      query = query.replace('@', 'from:')
    t_url = (search_base_url+query).escapeURL().replace('#', '%23')
    console.log "About to search twitter with: '#{t_url}'"
    scrape.json t_url, (resp) ->
      if resp.error?
        client.say msg.reply, "Error received: #{resp.error}"
        return null
      if resp.results.length > 0
        result_set = if resp.results.length < 6
          resp.results
        else
          _.initial(resp.results, resp.results.length - 5)
        _.each result_set, (r) ->
          tweet =
            from_user: r.from_user
            created: new Date(r.created_at)
            text: r.text
            to_user: r.to_user
          to_suffix = if tweet.to_user != null
            " to @#{tweet.to_user}"
          else
            ""
          client.say msg.reply, "@#{tweet.from_user}: \"#{tweet.text}\" "+
            "#{tweet.created.relative()}#{to_suffix}."
      else
        client.say msg.reply, "No results found for '#{query}'."

module.exports =
  plugins: [twitter_search_plugin]

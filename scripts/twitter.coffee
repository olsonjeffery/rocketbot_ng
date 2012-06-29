scrape = require '../scrape'
_ = require 'underscore'

search_base_url = 'http://search.twitter.com/search.json?q='

twitter_search = (query, cb) ->
  if query == ''
    return null
  if query.startsWith('@')
    query = query.replace('@', 'from:')
  t_url = (search_base_url+query).escapeURL().replace('#', '%23')
  console.log "About to search twitter with: '#{t_url}'"
  scrape.json t_url, (resp) ->
    if resp.error?
      cb null
    cb resp.results

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
      client.say msg.reply, "You provide a query to search with"
      return null
    twitter_search query, (results) ->
      if results == null
        client.say msg.reply, "Error with query '#{query}'"
      if results.length > 0
        result_set = if results.length < 6
          results
        else
          _.initial(results, results.length - 5)
        _.each result_set, (r) ->
          tweet =
            from_user: r.from_user
            created: new Date(r.created_at)
            text: r.text
            to_user: r.to_user
          to_suffix = if tweet.to_user?
            " to @#{tweet.to_user}"
          else
            ""
          client.say msg.reply, "@#{tweet.from_user}: \"#{tweet.text.unescapeHTML()}\" "+
            "#{tweet.created.relative()}#{to_suffix}."
      else
        client.say msg.reply, "No results found for '#{query}'."

class twitter_trending_plugin
  constructor: (@options) ->
  name: 'twitter_trending'
  msg_type: 'message'
  version: '1'
  commands: [ 'trending']
  match_regex: ->
    null
  doc_name: 'trending'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}trending
    SYNONYMs: latest, lt
    INFO: Show trending topics for the United States
    """
  process: (client, msg) ->
    us_trending_url = "http://api.twitter.com/1/trends/23424977.json"
    scrape.json us_trending_url, (resp) ->
      if resp.errors?
        client.say msg.reply, "There was an error looking up trending topics, sorry."
      trends = _.map(resp[0].trends, (t) ->
        t.name + if t.promoted? then " (PROMOTED)" else ""
      ).join(", ")
      as_of = new Date(resp[0].as_of);
      client.say msg.reply, "Trending twitter topics in the USA, as of #{as_of.relative()}: #{trends}"

class latest_tweet_plugin
  constructor: (@options) ->
  name: 'latest_tweet'
  msg_type: 'message'
  version: '1'
  commands: [ 'lt', 'latest']
  match_regex: ->
    null
  doc_name: 'latest_tweet'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}latest <QUERY>
    SYNONYMs: latest, lt
    INFO: Syntax the same as #{@options.cmd_prefix}tweet, but only returns
          the newest tweet that matches the provided <QUERY>.
    """
  process: (client, msg) ->
    query = msg.msg.compact()
    if query == ''
      client.say msg.reply, "You provide a query to search with"
      return null
    twitter_search query, (results) ->
      if results == null
        client.say msg.reply, "Error with query '#{query}'"
      if results.length > 0
        to_suffix = ''
        r = _.first(results)
        tweet =
          from_user: r.from_user
          created: new Date(r.created_at)
          text: r.text
          to_user: r.to_user
        to_suffix = if tweet.to_user?
          " to @#{tweet.to_user}"
        else
          ""
        client.say msg.reply, "@#{tweet.from_user}: \"#{tweet.text.unescapeHTML()}\" "+
          "#{tweet.created.relative()}#{to_suffix}."
      else
        client.say msg.reply, "No results found for '#{query}'."

module.exports =
  plugins: [twitter_search_plugin, latest_tweet_plugin, twitter_trending_plugin]
  search: twitter_search

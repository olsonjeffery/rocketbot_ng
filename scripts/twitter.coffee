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

available_locs = null
get_available_locs = (cb) ->
  if not available_locs?
    scrape.json 'https://api.twitter.com/1/trends/available.json', (resp) ->
      available_locs = resp
      cb available_locs
  else
    cb available_locs

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
    INFO: Show trending topics for the United States
    """
  process: (client, msg) ->
    get_available_locs (available_locs) ->
      desired_loc = '23424977'
      desired_loc_name = 'USA'
      query_loc = msg.msg.compact().toLowerCase()
      if query_loc != ''
        hits = _.filter(available_locs, (loc) ->
          if query_loc.length != 2 and loc.placeType.code == 7 # town
            name = ("#{loc.name}, #{loc.country}").toLowerCase()
            name.indexOf(query_loc) != -1
          else if loc.placeType.code == 12 # country
            name = ("#{loc.name}").toLowerCase()
            if query_loc.length == 2
              loc.countryCode.toLowerCase() == query_loc
            else
              name.indexOf(query_loc) != -1
          else
            false
        )
        if hits.length == 0
          client.say msg.reply, "No locations matching '#{msg.msg.compact()}'"
          return null
        if hits.length > 1
          result = _.map(hits, (loc) ->
            if loc.placeType.code == 7 # town
              "#{loc.name} - #{loc.country} (Town)"
            else if loc.placeType.code == 12 # country
              "#{loc.name} (use country code '#{loc.countryCode}')"
            else
              ''
          ).join(', ')
          client.say msg.reply, "Multiple locations matching "+
            "'#{msg.msg.compact()}': #{result}"
          return null
        else
          hits = _.first(hits)
          loc_info = if hits.placeType.code == 7 # town
              {name: "#{hits.name} - #{hits.country} (Town)", id: hits.woeid}
            else if hits.placeType.code == 12 # country
              {name: "#{hits.name} (Country)", id: hits.woeid }
            else
              null
          if loc_info == null
            client.say msg.reply, "Unknown location type "+
             "'#{hits.placeType.code}' for '#{hits.name}'"
            return null
          desired_loc = loc_info.id
          desired_loc_name = loc_info.name
          console.log "FOUND MATCH: #{desired_loc} #{desired_loc_name}"
      trending_url = "http://api.twitter.com/1/trends/#{desired_loc}.json"
      scrape.json trending_url, (resp) ->
        if resp.errors?
          client.say msg.reply, "There was an error looking up trending "+
            "topics, sorry."
        trends = _.map(resp[0].trends, (t) ->
          t.name + if t.promoted? then " (PROMOTED)" else ""
        ).join(", ")
        as_of = new Date(resp[0].as_of);
        client.say msg.reply,
          "Trending twitter topics for #{desired_loc_name},"+
          " as of #{as_of.relative()}: #{trends}"

class latest_tweet_plugin
  constructor: (@options) ->
  name: 'latest_tweet'
  msg_type: 'message'
  version: '1'
  commands: [ 'lt', 'latest', 'recent']
  match_regex: ->
    null
  doc_name: 'latest_tweet'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}latest <QUERY>
    SYNONYMs: latest, lt, recent
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
        client.say msg.reply,
          "@#{tweet.from_user}: \"#{tweet.text.unescapeHTML()}\" "+
          "#{tweet.created.relative()}#{to_suffix}."
      else
        client.say msg.reply, "No results found for '#{query}'."

module.exports =
  plugins: [twitter_search_plugin, latest_tweet_plugin,
            twitter_trending_plugin]
  search: twitter_search

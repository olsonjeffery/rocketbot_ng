scrape = require '../scrape'
_ = require 'underscore'
options = require '../options'

Twit = require 'twit'

T = new Twit({
  consumer_key:         options.twitter.consumer_key,
  consumer_secret:      options.twitter.consumer_secret,
  access_token:         options.twitter.access_token,
  access_token_secret:  options.twitter.access_token_secret
})

twitter_search_full = (query, page, rpp, cb) ->
  if query.startsWith('@')
    query = query.replace('@', 'from:')
  T.get 'search/tweets', {count: rpp, q: query}, (err, reply) ->
    if err?
      console.log "TWIT ERR"
      console.log err
      throw err
    else
      console.log "TWIT GOT REPLY"
      cb reply.statuses

twitter_search = (query, cb) ->
  twitter_search_full query, 1, 15, cb

display_tweet_common = (r, client, msg)->
  tweet =
    from_user: r.user.screen_name
    created: new Date(r.created_at)
    text: r.text
  #conolse.log "TWIT STATUS"
  #console.log r
  #console.log "TWIT USER"
  #console.log r.user
  #console.log "TWIT RETWEETED_STATUS"
  #console.log r.retweeted_status
  client.say msg.reply, "@#{tweet.from_user}: \"#{tweet.text.unescapeHTML()}\" "+
    "#{tweet.created.relative()}."

articles = [
  'rt', '0', '1', '2', '3', '4', '5', '6',
  '7', '8', '9', 'http', '//', '/', '', '//t',
  "don't",
  "it's"
  "doesnt", "doesn't"
  'via', '&amp;', '&gt', '--&gt', "we're",
  'the',
  'be',
  'to',
  'of',
  'and',
  'a',
  'in',
  'that',
  'have',
  'I',
  'it',
  'for',
  'not',
  'on',
  'with',
  'he',
  'as',
  'you',
  'do',
  'at',
  'this',
  'but',
  'his',
  'by',
  'from',
  'they',
  'we',
  'say',
  'her',
  'she',
  'or',
  'an',
  'will',
  'my',
  'one',
  'all',
  'would',
  'there',
  'their',
  'what',
  'so',
  'up',
  'out',
  'if',
  'about',
  'who',
  'get',
  'which',
  'go',
  'me',
  'when',
  'make',
  'can',
  'like',
  'time',
  'no',
  'just',
  'him',
  'know',
  'take',
  'people',
  'into',
  'year',
  'your',
  'good',
  'some',
  'could',
  'them',
  'see',
  'other',
  'than',
  'then',
  'now',
  'look',
  'only',
  'come',
  'its',
  'over',
  'think',
  'also',
  'back',
  'after',
  'use',
  'two',
  'how',
  'our',
  'work',
  'first',
  'well',
  'way',
  'even',
  'new',
  'want',
  'because',
  'any',
  'these',
  'give',
  'day',
  'most',
  'us',
  'are',
  'was',
  'more',
  'has',
  'best',
  'worst',
  'off',
  'does',
  'got',
  'get',
  'say',
  'says',
  'still',
  'gets',
  'tells',
  'tell'
]
articles_by_speech_part = [
  'time',
  'person',
  'year',
  'way',
  'day',
  'thing',
  'man',
  'world',
  'life',
  'hand',
  'part',
  'child',
  'eye',
  'woman',
  'place',
  'work',
  'week',
  'case',
  'point',
  'government',
  'company',
  'number',
  'group',
  'problem',
  'fact',
  'be',
  'have',
  'do',
  'say',
  'get',
  'make',
  'go',
  'know',
  'take',
  'see',
  'come',
  'think',
  'look',
  'want',
  'give',
  'use',
  'find',
  'tell',
  'ask',
  'work',
  'seem',
  'feel',
  'try',
  'leave',
  'call',
  'good',
  'new',
  'first',
  'last',
  'long',
  'great',
  'little',
  'own',
  'other',
  'old',
  'right',
  'big',
  'high',
  'different',
  'small',
  'large',
  'next',
  'early',
  'young',
  'important',
  'few',
  'public',
  'bad',
  'same',
  'able',
  'to',
  'of',
  'in',
  'for',
  'on',
  'with',
  'at',
  'by',
  'from',
  'up',
  'about',
  'into',
  'over',
  'after',
  'beneath',
  'under',
  'above',
  'the',
  'and',
  'a',
  'that',
  'I',
  'it',
  'not',
  'he',
  'as',
  'you',
  'this',
  'but',
  'his',
  'they',
  'her',
  'she',
  'or',
  'an',
  'will',
  'my',
  'one',
  'all',
  'would',
  'there',
  'their'
]
class twitgeist_plugin
  constructor: (@options) ->
  name: 'twitgeist'
  msg_type: 'message'
  version: '1'
  commands: [ 'twitgeist' ]
  match_regex: ->
    null
  doc_name: 'twitgeist'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}twitgeist <QUERY>
    INFO: search the Twitter public API for <QUERY>, then show the most frequently
          used terms in the result set.
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
    all_results = []
    total_pages = 5
    curr_page = 1
    final_results_cb = (results) ->
      console.log "total number of results: #{results.length}"
      if results == null
        client.say msg.reply, "Error with query '#{query}'"
      else
        just_the_tweets = _.map results, (r) -> r.text
        jtt_as_one = just_the_tweets.join ' '
        jtt_as_one = jtt_as_one.replace /\.|,|:/g, ' '
        all_words = jtt_as_one.split ' '
        word_counts = {}
        _.each all_words, (word) ->
          word = word.toLowerCase()
          is_article = word.length < 5 or word == query or
            word.startsWith('co/') or _.detect articles, (a) -> a == word
          if not is_article?
            if not word_counts[word]?
              word_counts[word] = 1
            else
              word_counts[word] += 1
        words_as_objs = _.map word_counts, (v, k) -> { word: k, count: v }
        words_as_objs = _.filter words_as_objs, (o) -> o.count > 1
        if not words_as_objs?
          client.say msg.reply, "no unique hits from a query of '#{query}', sorry"
        else
          sorted = _.sortBy words_as_objs, (o) -> o.count
          sorted.reverse()
          top_words = if sorted.length > 20 then sorted.first(20) else sorted
          list = _.reduce top_words, (m, i) ->
            m + "#{i.word} (#{i.count}), "
          , "Top words for '#{query}': "
          list = list.truncate(list.length - 2, true, 'right', '')
          client.say msg.reply, list
    page_result_getter_cb = (results) ->
      curr_page += 1
      _.each results, (r) ->
        all_results.push r
      if curr_page <= total_pages
        twitter_search_full query, curr_page, 100, page_result_getter_cb
      else
        final_results_cb all_results
    twitter_search_full query, curr_page, 100, page_result_getter_cb

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
        results_no_rt = _.filter(results, (x)->not x.retweeted_status?)
        result_set = if results_no_rt.length < 6
          results_no_rt
        else
          _.initial(results_no_rt, results_no_rt.length - 5)
        _.each result_set, (r) ->
          display_tweet_common r, client, msg
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
        display_tweet_common r, client, msg
module.exports =
  plugins: [twitter_search_plugin, latest_tweet_plugin,
            twitter_trending_plugin, twitgeist_plugin]
  search: twitter_search

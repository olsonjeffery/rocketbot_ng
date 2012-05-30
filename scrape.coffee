# Adapted, by Jeff Olson, from:
# https://gist.github.com/790580
#
# Scraping Made Easy with jQuery and SelectorGadget
# (http://blog.dtrejo.com/scraping-made-easy-with-jquery-and-selectorga)
# by David Trejo
#
# Install node.js and npm:
#    http://joyeur.com/2010/12/10/installing-node-and-npm/
# Then run
#    npm install jsdom jquery http-agent
#    node numresults.js
#
util = require 'util'
url = require 'url'
httpAgent = require 'http-agent'
jsdom = require('jsdom').jsdom
_ = require 'underscore'

moz_agent = 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:12.0)' +
            ' Gecko/20100101 Firefox/12.0'

scrape_multiple = (host, urls, cb) ->
  options = _.map urls, (u) ->
    console.log "setting up url '#{host+u}'"
    return { uri: u, method: 'GET', headers: {'User-Agent':moz_agent} }
  agent = httpAgent.create host, options
  console.log 'Scraping', urls.length, 'pages from', agent.host

  agent.addListener 'next', (err, agent) ->
    window = jsdom(agent.body).createWindow()
    jq = require('jquery').create(window)
    cb window, jq
    agent.next()

  agent.addListener 'stop', (err, agent) ->
    if err then console.log(err)
    console.log 'All done!'

  # Start scraping
  agent.start()
  console.log('scrape_multiple exiting...')

scrape_single = (raw_url, cb) ->
  parsed_url = url.parse raw_url
  host = parsed_url.host
  urls = [ parsed_url.path ]
  scrape_multiple host, urls, cb

scrape =
  single: scrape_single
  multiple: scrape_multiple

module.exports = scrape

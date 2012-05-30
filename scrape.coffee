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

scrape_multiple = (host, urls, cb) ->
  agent = httpAgent.create host, urls
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
  scrape_single: scrape_single
  scrape_multiple: scrape_multiple

module.exports = scrape

scrape_single 'http://www.google.com', (window, $) ->
  console.log "page title: '#{$('title').text()}'"
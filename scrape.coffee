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
jquery = require 'jquery'
Parser = require('xml2js').Parser

moz_agent = 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:12.0)' +
            ' Gecko/20100101 Firefox/12.0'

scrape_impl = (parsed_url, cb) ->
  options = [{uri: parsed_url, method: 'GET', headers: {'User-Agent':moz_agent} }]
  agent = httpAgent.create parsed_url.host, options
  console.log 'Scraping 1 page from', agent.host

  agent.addListener 'next', (err, agent) ->
    console.log "in scrape 'next' callback"
    if agent?
      window = jsdom(agent.body).createWindow()
      try
        cb agent.body, window
      catch e
        console.log "error occured while running cb: #{e}"
      agent.next()
    else
      console.log "failure to fetch page, err: '#{err}'"

  agent.addListener 'stop', (err, agent) ->
    if err then console.log(err)
    console.log 'All done!'

  # Start scraping
  agent.start()
  console.log('scrape_impl exiting...')

scrape_single = (raw_url, cb) ->
  parsed_url = url.parse raw_url
  host = parsed_url.host
  urls = [ parsed_url.path ]
  scrape_impl parsed_url, cb

scrape_jq = (raw_url, cb) ->
  scrape_single raw_url, (body, window) ->
    jq = jquery.create(window)
    cb jq

scrape_json = (raw_url, cb) ->
  scrape_single raw_url, (body, window) ->
    payload = JSON.parse body
    cb payload

parser = new Parser()
scrape_xml = (raw_url, cb) ->
  scrape_single raw_url, (body, window) ->
    parser.parseString body, (err, result) ->
      if not err?
        cb result

module.exports =
  jq: scrape_jq
  json: scrape_json
  xml: scrape_xml

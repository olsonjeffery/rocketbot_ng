scrape = require 'scrape'
xml2js = require 'xml2js'
_ = require 'underscore'

parser = new xml2js.Parser();
class weather_plugin
  constructor: (plg_ldr, options) ->
  name: 'weather'
  msg_type: 'message'
  version: '1'
  commands: [ 'weather', 'forecast' ]
  match_regex: ->
    null
  process: (client, msg) ->
    loc = msg.msg.compact()
    if loc == ''
      client.say msg.reply, "Sorry, you need to provide a location"+
                             " to lookup weather for."
    else
      url = "http://www.google.com/ig/api?weather=#{loc}"
      console.log "weather lookup for #{url}"
      scrape.single url, (body, window) ->
        parser.parseString body, (err, result) ->
          found_weather = result.weather.forecast_information?
          if found_weather
            if msg.command == 'weather'
              loc = result.weather.forecast_information.city['@'].data
              condition = result.weather.current_conditions.condition['@'] \
                            .data
              temp = result.weather.current_conditions.temp_f['@'] \
                            .data
              temp_c = result.weather.current_conditions.temp_c['@'] \
                            .data
              humidity = result.weather.current_conditions.humidity['@'] \
                            .data
              wind = result.weather.current_conditions.wind_condition['@'] \
                            .data
              client.say msg.reply, "Weather for #{loc}"
              client.say msg.reply, "Condition: #{condition} "+
                  "Temp: #{temp}F (#{temp_c}C)"
              client.say msg.reply, "#{humidity} #{wind}"
              #console.log "result: #{JSON.stringify(result)}"
            else
              # forecast
              loc = result.weather.forecast_information.city['@'].data
              client.say msg.reply, "Forecast for #{loc}"
              first = true
              forecast = _.map result.weather.forecast_conditions, (fc) ->
                day = if first
                  first = false
                  "Today"
                else
                  fc.day_of_week['@'].data
                high = fc.high['@'].data
                low = fc.low['@'].data
                condition = fc.condition['@'].data
                return "#{day} - Condition: #{condition} High/Low: "+
                  "#{high}F/#{low}F"
              console.log "forecast len #{forecast.length}"
              _.each forecast, (f) ->
                console.log f
                client.say msg.reply, f
          else
            client.say msg.reply, "Unable to find weather information"+
              " for '#{loc}'"

module.exports =
  plugins: [weather_plugin]
xml2js = require 'xml2js'
_ = require 'underscore'

user_data = require './user_data'
scrape = require '../scrape'

parser = new xml2js.Parser();

enabled = false
do_weather_lookup = (client, msg, loc) ->
  if enabled == false
    client.say msg.reply, "weather lookup disabled until further notice."+
      " quit hassling me, cop."
  else
    url = "http://www.google.com/ig/api?weather=#{loc}"
    console.log "weather lookup for #{url}"
    scrape.xml url, (result) ->
      console.log "entering weather xml scrape cb"
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
          client.say msg.reply, "Weather for #{loc}:"
          client.say msg.reply, "Condition: #{condition} "+
              "Temp: #{temp}F (#{temp_c}C)"
          client.say msg.reply, "#{humidity} #{wind}"
          #console.log "result: #{JSON.stringify(result)}"
        else
          # forecast
          loc = result.weather.forecast_information.city['@'].data
          client.say msg.reply, "Forecast for #{loc}:"
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
      console.log "leaving weather xml scrape cb"

after_ud_check = (client, msg, ud, loc) ->
  if loc == ''
    if ud.weather_loc? and ud.weather_loc != ''
      loc = ud.weather_loc
      found_loc = true
  else
    ud.weather_loc = loc
    ud.save()
    found_loc = true
  if found_loc
    do_weather_lookup client, msg, loc
  else
    client.say msg.reply, "Sorry, you need to provide a location"+
                           " to lookup weather for."

class weather_plugin
  constructor: (@options) ->
  name: 'weather'
  msg_type: 'message'
  version: '1'
  commands: [ 'weather', 'forecast' ]
  match_regex: ->
    null
  doc_name: 'weather'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}weather <LOCATION>
    INFO: Lookup current conditions for a specific <LOCATION>. If no
          <LOCATION> is provided, we try to find a saved location for
          your nick. Otherwise, we save the provided <LOCATION> for
          future use.
    SYNTAX: #{@options.cmd_prefix}forecast <LOCATION>
    INFO: Same as above, but provides forecast information instead
          of current conditions.
    """
  process: (client, msg) ->
    loc = msg.msg.compact()
    found_loc = false
    user_data.models.user_data.by_nick msg.sending_nick, (ud) ->
      if not ud?
        ud = user_data.models.user_data.new_ud msg.sending_nick
        ud.save().success ->
          after_ud_check client, msg, ud, loc
      else
        after_ud_check client, msg, ud, loc

module.exports =
  plugins: [weather_plugin]
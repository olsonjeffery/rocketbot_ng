_ = require 'underscore'
mersenne = require 'mersenne'

rand = (upper_limit) ->
  if upper_limit?
    mersenne.rand() % upper_limit
  else
    mersenne.rand()

safe_process = (client, info, cb) ->
  sb = client.raw_hook
  options = sb.bot_options
  try
    cb()
  catch e
    console.log ">>>EXCEPTION CAUGHT WHILE SAFE PROCESSING:"
    console.log e
    console.log ">>>AFTER EXCEPTION MESSAGE"
    console.log "bot nick: #{options.nick}"
    # send a msg to the tell plugin listener..
    # so if it isn't registered, then this just
    # gets shot into space.
    for admin in options.admins
      error_token = rand 10000
      sb.emit "tell::new",
        target: admin
        tell_msg: "ERROR #{error_token}: Occured at #{info.time.toString()} plugin name: #{info.name} invocation path: #{info.type}"
        sender: options.nick
      sb.emit "tell::new",
        target: admin
        tell_msg: "ERROR #{error_token}: #{e.toString().truncate(393)}"
        sender: options.nick

module.exports =
  hook_client: (hook) ->
    return {
      raw_hook: hook
      say: (chan, msg) =>
        hook.emit 'bot_say',
          chan: chan
          msg: msg
      send: (cmd, chan, msg) =>
        hook.emit 'bot_send',
          cmd: cmd
          chan: chan
          msg: msg
      whois: (nick, cb) =>
        hook.emit 'bot_whois', nick
        master_prefix = if hook.is_master? then '' else '*::'
        whois_resp_name = "#{master_prefix}bot_whois_resp"
        console.log "signature for WHOIS resp: '#{whois_resp_name}'"
        hook.once whois_resp_name, (info) ->
          cb info
    }
  is_admin: (nick, client, options, cb) ->
    client.whois nick, (info) ->
      is_identified = info.account?
      info =
        name: 'rb_util.is_admin WHOIS processor'
        type: 'util'
        time: new Date()
      safe_process client, info, ->
        cb (is_identified and (_.detect(options.admins, (n) -> n == nick))?)
  admin_only: (nick, client, options, cb) ->
    @is_admin nick, client, options, (user_is_admin) ->
      if user_is_admin
        cb()
      else
        client.say nick, "Only bot admins can invoke this action."
  rand: rand
  safe_process: safe_process

_ = require 'underscore'
mersenne = require 'mersenne'

rand = (upper_limit) ->
  if upper_limit?
    mersenne.rand() % upper_limit
  else
    mersenne.rand()

error_tell = (hook, options, error_token, error_msg) ->
  # send a msg to the tell plugin listener..
  # so if it isn't registered, then this just
  # gets shot into space.
  for admin in options.admins
    hook.emit "tell::new",
      target: admin
      tell_msg: "ERROR #{error_token}: #{error_msg}"
      sender: options.nick

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
    error_token = rand 10000
    msg1 = "Occured at #{info.time.toString()} plugin name: #{info.name} invocation path: #{info.type}"
    error_tell sb, options, error_token, msg1
    msg2 = "#{e.toString().truncate(393)}"
    error_tell sb, options, error_token, msg2

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
  error_tell: error_tell

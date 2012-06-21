_ = require 'underscore'
module.exports =
  hook_client: (hook) ->
    return {
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
      cb (is_identified and (_.detect(options.admins, (n) -> n == nick))?)
  admin_only: (nick, client, options, cb) ->
    @is_admin nick, client, options, (user_is_admin) ->
      if user_is_admin
        cb()
      else
        client.say nick, "Only bot admins can invoke this action."

_ = require 'underscore'
scrape = require '../scrape'

commit_log = (client, msg) ->
  console.log "github lookup"
  raw_info = msg.msg.compact().split(' ')
  info = {}
  branch = ""
  if raw_info.length > 0
    repo_info = raw_info[0].split('/')
    if repo_info.length != 2
      client.say msg.reply, "info must be in the form of: "+
           "username/repo"
    info = {user:repo_info[0], repo: repo_info[1]}
    url = "https://api.github.com/repos/#{info.user}/#{info.repo}"+
       "/commits"
    console.log "before github response, url: #{url}"
    scrape.single url, (body) ->
      console.log "got github response"
      console.log "body: #{body}"
      resp = JSON.parse(body)
      console.log "after json parse.."
      if resp.message?
        client.say msg.reply, "Failed to get repo info: #{resp.message}"
        return null
      else
        commits = _.map _.initial(resp, resp.length - 5), (c) ->
          return {
            sha: c.sha
            author: "#{c.commit.author.name} (#{c.commit.author.email})"
            message: c.commit.message.split('\n')[0].truncate(80)
            date: c.commit.author.date
          }
        _.each commits, (c) ->
          client.say msg.reply, "#{c.sha.truncate(7, false)} #{c.date} "+
            "#{c.author} - \"#{c.message}\""
  else
    client.say msg.reply, "Must provide repo info to look up"

class github_plugin
  constructor: (@options) ->
  name: 'github'
  msg_type: 'message'
  version: '1'
  commands: [ 'gh', 'github' ]
  match_regex: ->
    null
  doc_name: 'github'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}github <USER>/<REPO>
    INFO: Provide a commit summary of <USER>'s <REPO> on github, listing
       commits for master (the api doesn't appear to list commits to
        non-master branches)
    """
  process: (client, msg) ->
    commit_log client, msg

class changes_plugin
  constructor: (@options) ->
  name: 'changes'
  msg_type: 'message'
  version: '1'
  commands: [ 'changes' ]
  match_regex: ->
    null
  doc_name: 'changes'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}changes
    INFO: provide summary of recent changes to rocketbot, based on commits
      to the olsonjeffery/rocketbot_ng github repo.
    """
  process: (client, msg) ->
    msg.msg = 'olsonjeffery/rocketbot_ng'
    commit_log client, msg
module.exports =
  plugins: [github_plugin, changes_plugin]
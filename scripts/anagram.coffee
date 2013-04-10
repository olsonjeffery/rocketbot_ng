class anagram_plugin
  constructor: (@options) ->
  name: 'anagram'
  msg_type: 'message'
  version: '1'
  commands: ['anagram']
  match_regex: () ->
    null
  doc_name: 'anagram'
  docs: ->
    """
    SYNTAX: #{@options.cmd_prefix}anagram <PHRASE>
    INFO: Try to make some anagrams from the provided input.
	      Can be limited to some arbitrary length by the
		  anagram server, based on load.
    """
  process: (client, msg) ->

module.exports =
  plugins: [anagram_plugin]
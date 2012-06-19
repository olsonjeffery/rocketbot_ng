// Generated by CoffeeScript 1.3.3
(function() {
  var etym_plugin, scrape;

  scrape = require('../scrape');

  etym_plugin = (function() {

    function etym_plugin(plg_ldr, options) {}

    etym_plugin.prototype.name = 'etym';

    etym_plugin.prototype.msg_type = 'message';

    etym_plugin.prototype.version = '1';

    etym_plugin.prototype.commands = ['etym'];

    etym_plugin.prototype.match_regex = function() {
      return null;
    };

    etym_plugin.prototype.process = function(client, msg) {
      var url;
      url = "http://www.etymonline.com/index.php?allowed_in_frame=0&search=" + (msg.msg.compact().replace(' ', '%20')) + "&searchmode=none";
      return scrape.single(url, function(body, window) {
        var $, definition;
        $ = require('jquery').create(window);
        definition = $('dd:first').text().compact();
        console.log("definition from " + url + ": " + definition);
        if (definition.length > 0) {
          client.say(msg.reply, "\"" + (definition.truncate(400)) + "\"");
        } else {
          client.say(msg.reply, "No matching search results on etymonline.com for \"" + (msg.msg.compact()) + "\"");
        }
        if (definition.length > 450) {
          return client.say(msg.reply, "Read more at: " + url);
        }
      });
    };

    return etym_plugin;

  })();

  module.exports = {
    plugins: [etym_plugin]
  };

}).call(this);

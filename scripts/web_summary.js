// Generated by CoffeeScript 1.3.3
(function() {
  var jsdom, links_plugin, models, scrape, url_god_regex, web_link_init, web_link_initialized, web_summary_plugin, _;

  _ = require('underscore');

  jsdom = require('jsdom');

  require('sugar');

  scrape = require('../scrape');

  models = {};

  web_link_initialized = false;

  web_link_init = function(db) {
    web_link_initialized = true;
    models.web_link = db.sequelize.define('web_link', {
      id: {
        type: db.Sql.INTEGER,
        autoIncrement: true,
        allowNull: false
      },
      chan: db.Sql.STRING,
      nick: db.Sql.STRING,
      url: db.Sql.STRING,
      title: db.Sql.TEXT,
      desc: db.Sql.TEXT
    }, {
      classMethods: {
        latest_links_for: function(nick, cb) {
          return this.findAll({
            order: 'createdAt DESC',
            limit: 5,
            where: {
              nick: nick
            }
          }).success(function(entries) {
            return cb(entries);
          });
        },
        latest_links: function(cb) {
          return this.findAll({
            order: 'createdAt DESC',
            limit: 5
          }).success(function(entries) {
            return cb(entries);
          });
        }
      }
    });
    return models.web_link.sync();
  };

  url_god_regex = /((https?:\/\/)?[\w-]+(\.[\w-]+)+\.?(:\d+)?(\/\S*)?)/i;

  links_plugin = (function() {

    function links_plugin(plg_ldr, options, db) {
      this.db = db;
      if (!web_link_initialized) {
        web_link_init(this.db);
      }
    }

    links_plugin.prototype.name = 'links';

    links_plugin.prototype.msg_type = 'message';

    links_plugin.prototype.version = '1';

    links_plugin.prototype.commands = ['links'];

    links_plugin.prototype.match_regex = function() {
      return null;
    };

    links_plugin.prototype.process = function(client, msg) {
      console.log("msg.msg : " + msg.msg);
      if (msg.msg !== '') {
        console.log("links for '" + msg.msg + "'");
        return models.web_link.latest_links_for(msg.msg, function(links) {
          if ((links != null) && links.length > 0) {
            client.say(msg.reply, "Most recent links from " + msg.msg + ":");
            return _.each(links, function(l) {
              var display;
              display = l.desc.indexOf(l.url) === -1 ? "" + l.url + " - \"" + l.title + "\"" : "\"" + l.desc + "\"";
              return client.say(msg.reply, "" + display + " " + (l.createdAt.relative()));
            });
          } else {
            return client.say(msg.reply, "I haven't seen any links from " + msg.msg);
          }
        });
      } else {
        console.log("all recent links..");
        return models.web_link.latest_links(function(links) {
          if (links != null) {
            client.say(msg.reply, "Recent links:");
            return _.each(links, function(l) {
              var display;
              display = l.desc.indexOf(l.url) === -1 ? "" + l.url + " - \"" + l.title + "\"" : "\"" + l.desc + "\"";
              return client.say(msg.reply, ("<" + l.nick + "> ") + ("" + display + " " + (l.createdAt.relative())));
            });
          } else {
            return console.log("Huh. I don't have any saved links. Sorry, dude.");
          }
        });
      }
    };

    return links_plugin;

  })();

  web_summary_plugin = (function() {

    function web_summary_plugin(plg_ldr, options, db) {
      this.db = db;
      if (!web_link_initialized) {
        web_link_init(this.db);
      }
    }

    web_summary_plugin.prototype.name = 'url summary';

    web_summary_plugin.prototype.msg_type = 'message';

    web_summary_plugin.prototype.version = '1';

    web_summary_plugin.prototype.commands = [];

    web_summary_plugin.prototype.match_regex = function() {
      return url_god_regex;
    };

    web_summary_plugin.prototype.process = function(client, msg) {
      var url;
      console.log("try to parse url for msg.text '" + msg.text + "'");
      url = _.first(msg.text.match(url_god_regex));
      console.log("found url '" + url + "'");
      return scrape.single(url, function(body, window) {
        var $, desc, page_title;
        $ = require('jquery').create(window);
        page_title = $('title').text().replace("\n", '').replace("\t", '').compact();
        client.say(msg.reply_to_nick, "\"" + page_title + "\"");
        desc = $('meta[name="description"]');
        if (desc.length > 0) {
          console.log('has meta');
          client.say(msg.reply_to_nick, "\"" + ($(desc[0]).attr('content')) + "\"");
        }
        return models.web_link.create({
          chan: msg.reply,
          nick: msg.sending_nick,
          url: url,
          title: page_title,
          desc: msg.text
        });
      });
    };

    return web_summary_plugin;

  })();

  module.exports = {
    plugins: [web_summary_plugin, links_plugin],
    models: models
  };

}).call(this);

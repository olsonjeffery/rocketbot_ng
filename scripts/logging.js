// Generated by CoffeeScript 1.3.3
(function() {
  var log_entry_init, logging_plugin, models, seen_plugin, _;

  models = {};

  _ = require('underscore');

  log_entry_init = function(db) {
    models.log_entry = db.sequelize.define('log_entry', {
      id: {
        type: db.Sql.INTEGER,
        autoIncrement: true,
        allowNull: false
      },
      chan: db.Sql.STRING,
      nick: db.Sql.STRING,
      msg: db.Sql.TEXT,
      is_pun: db.Sql.BOOLEAN
    }, {
      classMethods: {
        latest_entry_for: function(nick, cb) {
          return this.find({
            order: 'createdAt DESC',
            where: {
              nick: nick
            }
          }).success(function(entry) {
            return cb(entry);
          });
        },
        entries_for_nick_after: function(nick, cutoff, cb) {
          return this.findAll({
            order: 'createdAt DESC',
            where: ['datetime(createdAt) > datetime(?)', cutoff.format('{yyyy}-{MM}-{dd} {HH}:{mm}:{ss}')]
          }).success(function(entries) {
            console.log("# if entries since cuttoff: " + entries.length);
            entries = _.filter(entries, function(e) {
              return e.nick === nick;
            });
            console.log("# if entries by nick since c/o: " + entries.length);
            return cb(entries);
          });
        },
        recent_puns: function(cb) {
          return this.findAll({
            order: 'createdAt DESC',
            limit: 5,
            where: {
              is_pun: 1
            }
          }).success(function(entries) {
            return cb(entries);
          });
        },
        recent_puns_from: function(nick, cb) {
          return this.findAll({
            order: 'createdAt DESC',
            limit: 5,
            where: {
              is_pun: 1,
              nick: nick
            }
          }).success(function(entries) {
            return cb(entries);
          });
        }
      }
    });
    return models.log_entry.sync();
  };

  seen_plugin = (function() {

    function seen_plugin(plg_ldr, options, db) {
      this.db = db;
    }

    seen_plugin.prototype.name = 'seen';

    seen_plugin.prototype.msg_type = 'message';

    seen_plugin.prototype.version = '1';

    seen_plugin.prototype.commands = ['seen'];

    seen_plugin.prototype.match_regex = function() {
      return null;
    };

    seen_plugin.prototype.process = function(client, msg) {
      var latest;
      return latest = models.log_entry.latest_entry_for(msg.msg, function(entry) {
        if (entry != null) {
          return client.say(msg.reply, ("" + entry.nick + " was last seen ") + ("" + (entry.createdAt.relative()) + " saying '" + entry.msg + "'."));
        } else {
          return client.say(msg.reply, "I haven't heard anything from " + msg.msg);
        }
      });
    };

    return seen_plugin;

  })();

  logging_plugin = (function() {

    function logging_plugin(plg_ldr, options, db) {
      this.db = db;
      log_entry_init(this.db);
    }

    logging_plugin.prototype.name = 'logging';

    logging_plugin.prototype.msg_type = 'message';

    logging_plugin.prototype.version = '1';

    logging_plugin.prototype.commands = [];

    logging_plugin.prototype.match_regex = function() {
      return /^.*$/;
    };

    logging_plugin.prototype.process = function(client, msg) {
      console.log("LOGGING: <" + msg.sending_nick + "> " + msg.text);
      return models.log_entry.create({
        chan: msg.reply,
        nick: msg.sending_nick,
        msg: msg.text
      });
    };

    return logging_plugin;

  })();

  module.exports = {
    plugins: [logging_plugin, seen_plugin],
    models: models
  };

}).call(this);

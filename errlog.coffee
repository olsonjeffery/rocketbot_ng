_ = require 'underscore'
models = {}

errlog_initialized = false
errlog_init = (db) ->
  errlog_initialized = true
  models.errlog =
    db.sequelize.define('errlog', {
      id: { type: db.Sql.INTEGER, autoIncrement: true, allowNull: false},
      sender: db.Sql.STRING,
      chan: db.Sql.STRING,
      text: db.Sql.TEXT,
    },
    {
      classMethods: {
        for_target: (nick, cb) ->
          nick = nick.toLowerCase()
          @findAll({
            order: 'createdAt ASC',
            where: {target: nick, read: 0}
          }).success (entries) ->
            cb entries
      }
    })
  models.errlog.sync()
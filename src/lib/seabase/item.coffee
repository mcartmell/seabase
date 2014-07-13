_ = require('underscore')

class Seabase.Item
  constructor: (args = {}) ->
    @type = args['type']
    @attrs = _.clone(args['attrs'])
    @name = @attrs.name
  @fromTemplate: (type, template) ->
    new Seabase.Item(type: type, attrs: template)
  getChar: ->
    @attrs.char || '!'

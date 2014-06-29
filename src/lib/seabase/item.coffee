_ = require('underscore')

class Seabase.Item
  constructor: (args = {}) ->
    @type = args['type']
    @attrs = _.clone(args['attrs'])
    name = @attrs.name

_ = require 'underscore'
Seabase.Util =
  sum: (arr) ->
    _.reduce arr, (memo, num) ->
      memo + num
    , 0

_ = require 'underscore'
Seabase.Util =
  sum: (arr) ->
    _.reduce arr, (memo, num) ->
      memo + num
    , 0
  randInt: (min,max) ->
    Math.floor(Math.random() * (max-min+1)+min)

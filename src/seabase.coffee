window._ = require 'underscore'
window.Seabase =
  randInt: (min,max) ->
    Math.floor(Math.random() * (max-min+1)+min)
require './lib/seabase/config'
require './lib/seabase/main'
require './lib/seabase/map'
require 'underscore'
require 'hammerjs'

sb = new Seabase.Main(24,80,32,21,22)

@game = sb.game = new Phaser.Game(sb.totalWidth(), sb.totalHeight(), Phaser.CANVAS, 'phaser-example', { preload: sb.preload, create: sb.create, update: sb.update })
window.sb = sb
test = new Seabase.Map()

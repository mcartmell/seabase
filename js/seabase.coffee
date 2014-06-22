window.Seabase = {}
require './lib/seabase/main'
require './lib/seabase/map'
require 'underscore'

sb = new Seabase.Main(24,80,32,20,20)

@game = sb.game = new Phaser.Game(sb.displayCols() * sb.font() * 0.6, sb.displayRows() * sb.font(), Phaser.CANVAS, 'phaser-example', { preload: sb.preload, create: sb.create, update: sb.update })
window.sb = sb
test = new Seabase.Map()

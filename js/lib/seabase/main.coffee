class Seabase.Main

  onKeyUp: (event) =>
    dir = null
    dir = switch event.keyCode
      when Phaser.Keyboard.LEFT
        'left' 
      when Phaser.Keyboard.RIGHT
        'right' 
      when Phaser.Keyboard.UP
        'up' 
      when Phaser.Keyboard.DOWN
        'down'
      else
        null
    if dir
      @map.tryPlayerMove(dir)
      @map.redraw()
      @game.camera.follow(@map.playerSquare())

  constructor: (rows,cols,font,drows,dcols) ->
    @map = new Seabase.Map(this,rows,cols,font,drows,dcols)

  rows: ->
    @map.ROWS

  cols: ->
    @map.COLS

  font: ->
    @map.FONT

  displayRows: ->
    @map.DISPLAY_ROWS

  displayCols: ->
    @map.DISPLAY_COLS

  initMap: ->
    @map.init()
    @game.camera.follow(@map.playerSquare())

  create: =>
    @game.world.setBounds(0, 0, @cols() * @font() * 0.6, @rows() * @font())
    @game.input.keyboard.addCallbacks(null, null, @onKeyUp)
    @game.input.keyboard.addKeyCapture [Phaser.Keyboard.UP, Phaser.Keyboard.DOWN, Phaser.Keyboard.LEFT, Phaser.Keyboard.RIGHT]
    @initMap()

  preload: =>
  update: =>


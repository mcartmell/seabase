class Seabase.Main

  onSwipe: (dir) ->
    @map.tryPlayerMove(dir)
    @map.redraw()
    @game.camera.follow(@map.playerSquare())
    
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
    switch event.keyCode
      when 190 # >
        @map.interact()
      when Phaser.Keyboard.SPACEBAR
        @map.interact()

  constructor: (rows,cols,font,drows,dcols) ->
    @levels = {}
    @current_level = 0
    @ROWS = rows
    @COLS = cols
    @FONT = font
    @DROWS = drows
    @DCOLS = dcols

  centerCamera: ->
    @game.camera.follow(@map.playerSquare())

  goToLevel: (level) ->
    @clearScreen()
    if @levels[level]
      @map = @levels[level]
      #TODO: put player on staircase
      @map.reEnter()
    else
      @map = @levels[level] = @newMap(level)
    @current_level = level
    @centerCamera()

  goDown: ->
    @goToLevel(@current_level + 1)

  goUp: ->
    @goToLevel(@current_level - 1)

  newMap: (level) ->
    map = new Seabase.Map(this,@rows(),@cols(),@font(),level)
    if level == 0
      map.init(spawnOn: '>')
    else
      map.init(spawnOn: '<')
    map

  rows: ->
    @ROWS

  cols: ->
    @COLS

  font: ->
    @FONT

  displayRows: ->
    @DROWS

  displayCols: ->
    @DCOLS

  initMap: ->
    @goToLevel(0)
    @game.camera.follow(@map.playerSquare())

  initCell: (chr,x,y) ->
    style = { font: @FONT + "px monospace", fill:"#586e75"}
    @game.add.text(@FONT*0.6*x, @FONT*y, chr, style)

  initScreen: ->
    @screen = []
    for y in [0..@ROWS-1]
      newRow = []
      for x in [0..@COLS-1]
        newRow.push @initCell('', x, y)
      @screen.push newRow

  clearScreen: ->
    @eachCell (x, y) =>
      @screen[y][x].text = ''

  eachCell: (cb) ->
    for y in [0..@ROWS-1]
      for x in [0..@COLS-1]
        cb(x,y)

  create: =>
    # make world bigger than camera
    @game.world.setBounds(0, 0, @cols() * @font() * 0.6, @rows() * @font())
    # add keyboard callbacks
    @game.input.keyboard.addCallbacks(null, null, @onKeyUp)
    @game.input.keyboard.addKeyCapture [Phaser.Keyboard.UP, Phaser.Keyboard.DOWN, Phaser.Keyboard.LEFT, Phaser.Keyboard.RIGHT, Phaser.Keyboard.SPACEBAR]

    # initialize screen
    @initScreen()
    @initMap()
    # scale to fit visible screen
    @game.scale.startFullScreen()
    @game.scale.setShowAll()
    @game.scale.refresh()

    # set up swipe events
    el = document.getElementById('phaser-example') 
    Hammer(el).on 'swipedown', =>
      @onSwipe 'down'
    Hammer(el).on 'swipeup', =>
      @onSwipe 'up'
    Hammer(el).on 'swipeleft', =>
      @onSwipe 'left'
    Hammer(el).on 'swiperight', =>
      @onSwipe 'right'
  preload: =>
    @game.stage.backgroundColor = "#002b36"
  update: =>

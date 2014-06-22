class Seabase.Main

  onSwipe: (dir) ->
    @map.tryPlayerMove(dir)
    @map.redraw()
    @game.camera.follow(@map.playerSquare())
    
  onKeyUp: (event) =>
    dir = null
    unless @gameOver
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

    interactPressed = (event.keyCode == 190 || event.keyCode == Phaser.Keyboard.SPACEBAR)
    if interactPressed
      if @gameOver
        @restartGame()
        return
      else
        @map.interact()

    @map.redraw()
    @game.camera.follow(@map.playerSquare())

  endGame: ->
    @gameOver = true

  restartGame: ->
    @levels = {}
    @current_level = 0
    @gameOver = false
    @map = null
    @initMap()

  constructor: (rows,cols,font,drows,dcols) ->
    @statusBars = {}
    @levels = {}
    @gameOver = false
    @current_level = 0
    @ROWS = rows
    @COLS = cols
    @FONT = font
    @DROWS = drows
    @DCOLS = dcols

  centerCamera: ->
    @game.camera.follow(@map.playerSquare())

  goToLevel: (level, args = {}) ->
    @clearScreen()
    # move the current player if we already have one
    if level == 0
      args['spawnOn'] = '>'
    if @map
      args['player'] = @map.player
    if @levels[level]
      @map = @levels[level]
      @map.reEnter(args)
    else
      @map = @levels[level] = @newMap(level)
      @map.init(args)
    @current_level = level
    @centerCamera()
    @refreshStatus()

  goDown: ->
    @goToLevel(@current_level + 1, spawnOn: '<')

  goUp: ->
    @goToLevel(@current_level - 1, spawnOn: '>')

  newMap: (level) ->
    map = new Seabase.Map(this,@rows(),@cols(),@font(),level)
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

  totalHeight: ->
    @displayRows() * @font()

  totalWidth: ->
    @displayCols() * 0.6 * @font()

  createStatusBars: ->
    @createStatusBar 'top', 0
    @createStatusBar 'bottom', @totalHeight() - (20 * 2)
    @statusBars['top'].text = 'Welcome to Seabase!'

  createStatusBar: (name, sbTop) ->
    g = @game.add.graphics(0,0)
    sbFont = 20
    sbHeight = (sbFont * 2)

    # status bar background
    g.beginFill(0x000000, 0.3)
    g.drawRect(0,0,@totalWidth(), sbHeight)
    g.endFill()
    g.fixedToCamera = true
    g.cameraOffset.setTo(0, sbTop)

    # starus bar text
    t = @game.add.text(0, 0, '', { font: sbFont + 'px monospace', fill: '#fff', align: 'left' })
    t.fixedToCamera = true
    t.cameraOffset.setTo(0, sbTop)
    @statusBars[name] = t

  refreshStatus: ->
    return unless @statusBars['top']
    @statusBars['top'].text = 'Seabase   HP:' + @map.player.hp + ' XP:' + @map.player.xp + ' Lvl:' + @current_level

  create: =>
    # make world bigger than camera
    @game.world.setBounds(0, 0, @cols() * @font() * 0.6, @rows() * @font())
    # add keyboard callbacks
    @game.input.keyboard.addCallbacks(null, null, @onKeyUp)
    @game.input.keyboard.addKeyCapture [Phaser.Keyboard.UP, Phaser.Keyboard.DOWN, Phaser.Keyboard.LEFT, Phaser.Keyboard.RIGHT, Phaser.Keyboard.SPACEBAR]

    # initialize screen
    @initScreen()
    @initMap()

    # create status bar
    @createStatusBars()

    # scale to fit visible screen
    @game.scale.fullScreenScaleMode = Phaser.ScaleManager.SHOW_ALL
    @game.scale.startFullScreen()
    @game.scale.setShowAll()
    @game.scale.refresh()

    # set up swipe events
    el = document.getElementById('phaser-example') 
    ham = Hammer(el, preventDefault: true)
    ham.on 'swipedown', (e) =>
      @onSwipe 'down'
    ham.on 'swipeup', =>
      @onSwipe 'up'
    ham.on 'swipeleft', =>
      @onSwipe 'left'
    ham.on 'swiperight', =>
      @onSwipe 'right'
    ham.on 'tap', =>
      @map.interact()
  preload: =>
    @game.stage.backgroundColor = "#002b36"
  update: =>

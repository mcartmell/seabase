Hammer = require 'hammerjs'
require './log'
require './menu'

class Seabase.Main

  onSwipe: (dir) ->
    @map.tryPlayerMove(dir)
    @map.redraw()
    @game.camera.follow(@map.playerSquare())
    
  onTap: (e) =>
    unless @movementBlocked()
      dirs = []
      if (e.y < (@game.height * 0.35))
        dirs.push 'up'

      if (e.y > (@game.height * 0.65))
        dirs.push 'down'

      if (e.x < (@game.width * 0.35))
        dirs.push 'left'

      if (e.x > (@game.width * 0.65))
        dirs.push 'right'

      if dirs.length == 1
        return @doPlayerMove(dirs[0])

    # if non-directional, interact instead
    @doInteract()

  movementBlocked: ->
    @gameOver || @popupActive || @menuActive()

  doInteract: ->
    if @gameOver
      @restartGame()
      return
    else if @popupActive
      @clearPopup()
    else if @menuActive()
      return @menu.select()
    else
      @map.interact()
      @map.redraw()
      @game.camera.follow(@map.playerSquare())

  doPlayerMove: (dir) ->
    @map.tryPlayerMove(dir)
    @map.redraw()
    @game.camera.follow(@map.playerSquare())

  getDirFromKey: (key)->
    switch key
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

  onKeyUp: (event) =>
    dir = null
    dir = @getDirFromKey(event.keyCode)
    if dir
      if @movementBlocked()
        if @menuActive()
          return @menu.move(dir)
      else
        return @doPlayerMove(dir)

    interactPressed = (event.keyCode == 190 || event.keyCode == Phaser.Keyboard.SPACEBAR)
    if interactPressed
      @doInteract()

    switch event.keyCode
      when Phaser.Keyboard.M
        return @menu.toggle()

  endGame: ->
    @gameOver = true

  restartGame: ->
    @clearPopup()
    @turns = 0
    @levels = {}
    @current_level = 0
    @gameOver = false
    @map = null
    @initMap()

  constructor: (rows,cols,font,drows,dcols) ->
    @statusBars = []
    @ROWS = rows
    @COLS = cols
    @FONT = font
    @DROWS = drows
    @DCOLS = dcols

  incTurns: ->
    @turns += 1
    # regenerate hit points every x number of turns
    if (@turns % (15 - @map.player.rank + 1)) == 0
      @map.player.giveHP(1)
  centerCamera: ->
    @game.camera.follow(@map.playerSquare())

  goToLevel: (level, args = {}) ->
    @clearScreen()
    @current_level = level
    # move the current player if we already have one
    if level == 0
      #XXX debug hack for spawning on an exit
      args['spawnOn'] = '>'
    if @map
      # if the map already exists, remember the player
      args['player'] = @map.player
    if @levels[level]
      # if the level is cached, re-enter the same level
      @map = @levels[level]
      @map.reEnter(args)
    else
      # otherwise, initialize a completely new map
      @map = @levels[level] = @newMap(level)
      @map.init(args)
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

  createPopup: (msg) ->
    @clearPopup() if @popupActive
    @popupActive = true
    popupHeightFactor = 0.3
    top = @game.height * ((1 - popupHeightFactor) / 2)
    @popup = g = @game.add.graphics(20, top)
    g.beginFill(0x000000, 0.3)
    g.drawRect(0,0,@game.width - 40, @game.height * popupHeightFactor)
    g.endFill()
    g.fixedToCamera = true
    @popupText = t = @game.add.text(24, top + 4, msg, { font: 28 + 'px monospace', fill: '#fff', align: 'center', wordWrap: true, wordWrapWidth: @game.width - 40 })
    t.fixedToCamera = true

  pop: @::createPopup
  log: (msg) ->
    @logger.log msg

  clearPopup: ->
    if @popup? && @popupText?
      @popup.destroy()
      @popupText.destroy()
      @popupActive = false

  createMenu: ->
    @menu = new Seabase.Menu(@)

  menuActive: ->
    @menu.isVisible()

  createStatusBars: ->
    @createStatusBar 'top', 0, 2, 16
    @createStatusBar 'bottom', @totalHeight() - (14 * 4.2), 4
    @statusBars['top'].text = 'Welcome to Seabase!'

  createStatusBar: (name, sbTop, lines = 2, font = 12) ->
    g = @game.add.graphics(0,0)
    sbFont = font
    sbHeight = ((sbFont + 2) * lines)

    # status bar background
    g.beginFill(0x000000, 0.6)
    g.drawRect(0,0,@totalWidth(), sbHeight)
    g.endFill()
    g.fixedToCamera = true
    g.cameraOffset.setTo(0, sbTop)

    # starus bar text
    t = @game.add.text(0, 0, '', { font: sbFont + 'px monospace', fill: SBConf.colours['base1'], align: 'left', wordWrap: true, wordWrapWidth: @totalWidth() })
    t.fixedToCamera = true
    t.cameraOffset.setTo(0, sbTop)
    @statusBars[name] = t

  refreshStatus: ->
    return unless @statusBars && @statusBars['top']
    @statusBars['top'].text = 'Seabase   HP:' + @map.player.totalHP() + '(' + @map.player.maxHP() + ') XP:' + @map.player.xp + ' Lvl: ' + @map.player.rank + ' Dlvl:' + @current_level

  create: =>
    # make world bigger than camera
    @game.world.setBounds(0, 0, @cols() * @font() * 0.6, @rows() * @font())
    # add keyboard callbacks
    @game.input.keyboard.addCallbacks(null, null, @onKeyUp)
    @game.input.keyboard.addKeyCapture [Phaser.Keyboard.UP, Phaser.Keyboard.DOWN, Phaser.Keyboard.LEFT, Phaser.Keyboard.RIGHT, Phaser.Keyboard.SPACEBAR]

    # initialize screen
    @initScreen()

    # create status bar
    @createStatusBars()

    # create initial menu
    @createMenu()

    # create logger
    @logger = new Seabase.Log(@statusBars['bottom'])

    # create map etc
    @restartGame()

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
    @game.input.onTap.add @onTap
  preload: =>
    @game.stage.backgroundColor = "#002b36"
  update: =>

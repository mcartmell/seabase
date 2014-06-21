_ = require('underscore')
require './entity'
class Seabase.Map
  MoveType = {
    NO: 0
    OK: 1
    FIGHT: 2
  }

  randInt = (min,max) ->
    Math.floor(Math.random() * (max-min+1)+min)
  eachCell = (cb) ->
    for y in [0..@ROWS-1]
      for x in [0..@COLS-1]
        cb(x,y)

  loc = (x,y) ->
    "#{x},#{y}"

  constructor: (sb,rows, cols, font, drows, dcols) ->
    @map = null
    @screen = null
    @ROWS = rows
    @COLS = cols
    @FONT = font
    @DISPLAY_ROWS = drows
    @DISPLAY_COLS = dcols
    @sb = sb
    @ents = []
    @entMap = {}

  init: ->
    @initMap()
    @rotMap()
    @initScreen()
    @spawnPlayer()
    @drawPlayerVisible()

  redraw: ->
    @drawPlayerVisible()

  initMap: ->
    @map = []
    for y in [0..@ROWS-1]
      @map[y] = []
    
  rotMap: ->
    @rotmap = new ROT.Map.Digger(@COLS, @ROWS)
    @rotmap.create(@drawRot)

  drawRot: (x, y, wall) =>
    @map[y][x] = if wall then '#' else '.'

  initCell: (chr,x,y) ->
    style = { font: @FONT + "px monospace", fill:"#fff"}
    @sb.game.add.text(@FONT*0.6*x, @FONT*y, chr, style)

  drawMap: ->
    eachCell (x,y) =>
      @screen[y][x].text = @map[y][x]

  lightPasses: (x,y) =>
    if !(x? && y? && x < @COLS && y < @ROWS)
      return false
    return false if @map[y][x] == '#'
    return true

  initScreen: ->
    @screen = []
    for y in [0..@ROWS-1]
      newRow = []
      for x in [0..@COLS-1]
        newRow.push @initCell('', x, y)
      @screen.push newRow

  clearScreen: ->
    eachCell (x, y) =>
      @screen[y][x].text = ''

  drawVisible: (px,py,amt) ->
    @clearScreen()
    fov = new ROT.FOV.PreciseShadowcasting(@lightPasses)
    fov.compute px,py,amt, (x, y, r, vis) =>
      if x?
        if vis == 1
          @screen[y][x].text = if r then @map[y][x] else '@'

  findAnyRoom: ->
    _.shuffle(@rotmap.getRooms())[0]

  findSpaceInRoom: ->
    theroom = @findAnyRoom()
    x = randInt(theroom._x1, theroom._x2)
    y = randInt(theroom._y1, theroom._y2)
    [x,y]

  spawnPlayer: ->
    coords = @findSpaceInRoom()
    [x,y] = coords
    @player = new Seabase.Entity(x,y,10)
    @ents.push @player

  drawPlayerVisible: ->
    @drawVisible(@player.x, @player.y, 5)

  placeEntity: (entity,x,y) ->
    @entMap[loc(x,y)] = entity

  removeEntity: (x,y) ->
    @entMap[loc(x,y)] = null

  moveEntity: (entity, x, y) ->
    @removeEntity(entity.x, entity.y)
    entity.x = x
    entity.y = y
    @placeEntity(entity, x,y)

  entityAt: (x,y) ->
    @entMap[loc(x,y)]

  newLoc: (x,y,direction) ->
    switch direction
      when 'up' then [x,y-1]
      when 'down' then [x,y+1]
      when 'right' then [x+1,y]
      when 'left' then [x-1,y]
  
  canMove: (entity, x, y) ->
    # currently, assume every entity has same movement rules
    if target = @entityAt(x,y)
      # FIGHT!
      return MoveType.FIGHT
    else
      square = @map[y][x]
      return switch square
        when '#' then MoveType.NO
        when '.' then MoveType.OK

  tryPlayerMove: (direction) ->
    nl = @newLoc @player.x, @player.y, direction
    [x,y] = nl
    switch @canMove(@player, x, y)
      when MoveType.OK
        @moveEntity(@player, x, y)
      when MoveType.FIGHT
      else

  playerSquare: ->
    @screen[@player.y][@player.x]

_ = require('underscore')
require './entity'
require './entity/monster'
require './entity/player'
require './feature'
class Seabase.Map
  MoveType = {
    NO: 0
    OK: 1
    FIGHT: 2
  }
  @MoveType = MoveType

  randInt = (min,max) ->
    Math.floor(Math.random() * (max-min+1)+min)

  loc = (x,y) ->
    "#{x},#{y}"

  constructor: (sb, rows, cols, font, level) ->
    @map = null
    @ROWS = rows
    @COLS = cols
    @FONT = font
    @sb = sb
    @level = level
    @ents = []
    @entMap = {}
    @exits = {}

  init: (args = {}) ->
    @initMap()
    @rotMap()
    @placeUpExit() unless @level == 0
    @placeDownExit()
    @createMonsters()
    if spawnExit = args['spawnOn']
      @placePlayerOnExit(spawnExit, args['player'])
    else
      @spawnPlayer()
    @redraw()
    @log ''

  placePlayerOnExit: (exit, player = null) ->
    coords = @exits[exit]
    @spawnPlayer(coords, player)

  tick: ->
    @moveMonsters()

  moveMonsters: ->
    for e in @ents
      if e.isMonster
        e.doMove(this)

  interact: ->
    sp = @playerSpace()
    if sp instanceof Seabase.Feature
      if sp.isDownExit()
        @sb.goDown()
      if sp.isUpExit()
        @sb.goUp()
    else
      @tick()

  reEnter: (args = {}) ->
    @placePlayerOnExit(args['spawnOn'], args['player'])
    @redraw()

  redraw: ->
    @drawPlayerVisible()
    @sb.refreshStatus()

  initMap: ->
    @map = []
    for y in [0..@ROWS-1]
      @map[y] = []
    
  rotMap: ->
    @rotmap = new ROT.Map.Digger(@COLS, @ROWS)
    @rotmap.create(@drawRot)

  drawRot: (x, y, wall) =>
    @map[y][x] = if wall then '#' else '.'

  drawMap: ->
    @sb.eachCell (x,y) =>
      @screen()[y][x].text = @map[y][x]

  screen: ->
    @sb.screen

  lightPasses: (x,y) =>
    if !(x? && y? && x >= 0 && y >= 0 && x < @COLS && y < @ROWS)
      return false
    return false if @map[y][x] == '#'
    return true

  # hide monsters that are no longer visible
  clearScreen: ->
    @sb.eachCell (x,y) =>
      if @entityAt(x,y)
        @screen()[y][x].text = ''
  drawVisible: (px,py,amt) ->
    @clearScreen()
    fov = new ROT.FOV.PreciseShadowcasting(@lightPasses)
    fov.compute px,py,amt, (x, y, r, vis) =>
      if x?
        if vis == 1
          @screen()[y][x].text = if r
            if ent = @entityAt(x,y)
              ent.toString()
            else
              @map[y][x].toString()
          else
            '@'

  findAnyRoom: ->
    _.shuffle(@rotmap.getRooms())[0]

  findSpaceForFeature: ->
    @findSpaceInRoom(forFeature: true)

  findSpaceInRoom: (args = {}) ->
    theroom = @findAnyRoom()
    space = null
    loop
      x = randInt(theroom._x1, theroom._x2)
      y = randInt(theroom._y1, theroom._y2)
      space = [x,y]
      if args['forFeature']
        break if @isMapEmpty(x,y)
      else
        break if @isEmpty(x,y)
    space

  placeFeature: (char) ->
    [x,y] = @findSpaceForFeature()
    @map[y][x] = new Seabase.Feature(char)
    [x,y]

  placeDownExit: ->
    @exits['>'] = @placeFeature('>')

  placeUpExit: ->
    @exits['<'] = @placeFeature('<')

  spawnPlayer: (coords = null, player = null) ->
    unless coords
      coords = @findSpaceInRoom()
    [x,y] = coords
    @player = player || new Seabase.Entity.Player(x,y,10,'@',this,name: 'player')
    @player.x = x
    @player.y = y
    @createEntity(@player)

  createEntity: (ent) ->
    @ents.push ent
    @moveEntity(ent,ent.x,ent.y)

  destroyEntity: (ent) ->
    @ents = _.reject @ents, (e) ->
      e == ent
    @removeEntity(ent.x, ent.y)

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

  isEmpty: (x,y) ->
    @canMove(null,x,y) == MoveType.OK

  isMapEmpty: (x,y) ->
    @map[y][x] == '.'
  
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
        else
          MoveType.OK

  tryEntityMove: (ent,x,y) ->
    switch @canMove(ent, x, y)
      when MoveType.OK
        @moveEntity(ent, x, y)
      when MoveType.FIGHT
        @doCombat(ent, @entityAt(x,y)) 

  log: (msg) -> 
    if @sb.statusBars['bottom']
      @sb.statusBars['bottom'].text = msg
  
  doCombat: (agg, tgt) ->
    dmg = randInt(1, agg.power)
    tgt.hp -= dmg
    if tgt.hp <= 0
      if tgt == @player
        @log "Vanquished by a #{agg.name}"
        @sb.endGame()
      else
        @log "#{agg.name} kills #{tgt.name}"
        @destroyEntity(tgt)
    else
      @log "#{agg.name} attacks #{tgt.name}"

  tryPlayerMove: (direction) ->
    @sb.statusBars['bottom'].text = direction
    nl = @newLoc @player.x, @player.y, direction
    [x,y] = nl
    @tryEntityMove(@player, x, y)
    @tick()

  playerSquare: ->
    @screen()[@player.y][@player.x]

  playerSpace: ->
    @map[@player.y][@player.x]

  createMonsters: ->
    for i in [1..10]
      [x,y] = @findSpaceInRoom()
      m = new Seabase.Entity.Monster(x,y,10,'e',this,name: 'monster')
      @createEntity(m)


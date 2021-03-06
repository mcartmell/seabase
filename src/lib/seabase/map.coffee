_ = require('underscore')
require './entity'
require './entity/monster'
require './entity/player'
require './feature'
require './feature/dropped_item'
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
    # initialize a new map
    @initMap()
    @rotMap()

    # place exits
    @placeUpExit() unless @level == 0
    @placeDownExit()

    # create monsters
    @createMonsters()

    # spawn the player
    if spawnExit = args['spawnOn']
      @placePlayerOnExit(spawnExit, args['player'])
    else
      @spawnPlayer()

    # TODO: create items
    @createItems()

    @redraw()
    @log ''

  placePlayerOnExit: (exit, player = null) ->
    coords = @exits[exit]
    @spawnPlayer(coords, player)

  tick: ->
    # do monster moves
    @moveMonsters()
    # increment theturn counter
    @sb.incTurns()

  moveMonsters: ->
    for e in @ents
      if e.isMonster
        e.doMove(this)

  interact: ->
    # default is to interact with the current square
    sp = @playerSpace()
    if sp instanceof Seabase.Feature
      if sp.isDownExit()
        @sb.goDown()
      if sp.isUpExit()
        @sb.goUp()
      if sp.canPickup()
        @pickupItem(sp)
        
      #TODO: pickup items here
    else
      # otherwise, just increment the tick counter
      @tick()

  # picks up the item on the current square
  pickupItem: (droppedItem) ->
    @map[@player.y][@player.x] = '.'
    @player.take(droppedItem.item)
    
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
          cell = @screen()[y][x]
          fillColour = SBConf.colours['base01']
          if r
            if ent = @entityAt(x,y)
              # a non-player entity
              cell.text = ent.toString()
              fillColour = ent.colour() if ent.colour()
            else
              # a map feature
              cell.text = @map[y][x].toString()
          else
            # the player
            cell.text = '@'
            fillColour = '#fff'
          cell.fill = fillColour

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

  placeFeature: (feature) ->
    [x,y] = @findSpaceForFeature()
    # if it's a feature object, place directly
    if feature instanceof Seabase.Feature
      @map[y][x] = feature
    else
    # otherwise, just use the char and create an object
      char = feature
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
    @player = player || new Seabase.Entity.Player(x,y,this,name: 'player',sb: @sb,template: 'human')
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
    # check that move is possible before doing the move
    switch @canMove(ent, x, y)
      when MoveType.OK
        @moveEntity(ent, x, y)
      when MoveType.FIGHT
        # if moving into an enemy square, fight!
        @doAttack(ent, @entityAt(x,y)) 

  log: (msg) -> 
    if @sb.logger
      @sb.logger.log(msg)

  pop: (msg) ->
    @sb.pop(msg)
  
  doAttack: (agg, tgt) ->
    # use all of aggressor's attacks
    for weapon in agg.getAttacks()
      @doCombat(agg, tgt, 'body', weapon)

  doCombat: (agg, tgt, bodyPart = 'body', weapon = null) ->
    # combat is mostly based on http://brogue.wikia.com/wiki/Combat

    # default stats for no weapon
    weaponDamage = 1
    weaponAttackBonus = 0
    if weapon?
      weaponDamage = agg.getWeaponDamage(weapon)
      weaponAttackBonus = agg.getWeaponAttackBonus(weapon)
    dmg = weaponDamage

    # calculate hit probability
    accuracy = 100 * 1.065 + weaponAttackBonus
    hitProbability = accuracy * (0.98 ** tgt.defence())
    console.log "to hit = #{hitProbability}"

    # generate a detailed log message
    logmsg =  "#{agg.name} attacks #{tgt.name} in the #{bodyPart}"
    if weapon
      logmsg += " with a #{weapon.attrs.name}"
    if randInt(0, 100) < hitProbability
      # hit
      tgt.applyDamage(bodyPart, dmg)
      logmsg += " for #{dmg} damage"
    else
      # miss
      logmsg += " but misses"
    @log logmsg
    if tgt.isDead()
      if tgt == @player
        @pop "Vanquished by a #{agg.name}"
        @sb.endGame()
      else
        @log "#{agg.name} kills #{tgt.name}"
        @giveXP(tgt)
        @destroyEntity(tgt)

  giveXP: (monster) ->
    xp = (monster.level) * (monster.level + 6) + 1
    @player.giveXP(xp)

  tryPlayerMove: (direction) ->
    # do the player's move and 'tick' so that monsters move
    nl = @newLoc @player.x, @player.y, direction
    [x,y] = nl
    @tryEntityMove(@player, x, y)
    @tick()

  playerSquare: ->
    # the actual screen slot where the player is rendered
    @screen()[@player.y][@player.x]

  playerSpace: ->
    # the map square that the player is on
    @map[@player.y][@player.x]

  createMonsters: (n = 10) ->
    allMonsters = _.keys(SBConf.monsters)

    # find suitable monsters up to the current level
    monsterPool = _.filter allMonsters, (mon) ->
      SBConf.monsters[mon].level && SBConf.monsters[mon].level <= @sb.current_level + 1

    # create 10 monsters?
    for i in [1..n]
      [x,y] = @findSpaceInRoom()
      mon = _.shuffle(monsterPool)[0]
      m = new Seabase.Entity.Monster(x, y, this, template: mon, sb: @sb)
      @createEntity(m)

  createItems: (n = 10) ->
    # create a pool of all items
    allItems = []
    for k in ['weapon', 'armour', 'item']
      key = k + 's'
      # inherit the base attributes for that type
      allItems = allItems.concat _.values(SBConf[key]).map (i) ->
        hash = _.clone(SBConf.item_meta[k])
        _.extend(hash, i)
        hash.itemType = k
        hash
    # filter again by just those items that are droppable
    allItems = allItems.filter (item) ->
      item.droppable == true

    # create random items from the pool
    for i in [1..n]
      theItem = _.sample(allItems)
      item = Seabase.Item.fromTemplate(theItem.itemType, theItem)
      feature = new Seabase.Feature.DroppedItem(item)
      @placeFeature feature

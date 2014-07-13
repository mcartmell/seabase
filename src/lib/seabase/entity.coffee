require './util'
require './item'
require './item/armour'
class Seabase.Entity
  constructor: (@x, @y, @map, args = {}) ->
    @name = args['name'] || 'something'
    @inventory = null
    @weapon = null
    @wield = []
    @bodyParts = {}
    @def = 0
    if template = args['template']
      @fromTemplate(template)
    @fromArgs[args]
    @sb = args['sb']

  fromTemplate: (template) ->
    attrs = SBConf.monsters[template]
    attrs = _.extend({name: template}, attrs)
    @fromArgs(attrs)
  
  fromArgs: (args) ->
    @char = args['char'] if args['char']
    @name = args['name'] if args['name']
    @def = args['def'] || 0
    @_colour = args['colour'] if args['colour']
    if bodyParts = args['bodyparts']
      for k in _.keys(bodyParts)
        bp = _.clone(bodyParts[k])
        # set the type and name automatically if not set
        bpType = bp.type || k
        bp['type'] = bpType
        bp['name'] ||= bpType

        # inherit from base bodyparts definition
        #TODO: check we have the minimum properties needed
        newbp = _.extend({}, SBConf.bodyparts[bpType] || {})
        bp = _.extend(newbp, bp)

        bp['maxhp'] = bp.hp
        if @bodyParts[bp.name]
          throw "Can't have two bodyparts with the same name"
        @bodyParts[bp.name] = bp
    else if args['hp']
      @bodyParts['body'] =
        hp: args['hp']
        fatal: true
    if args['weapon']
      @wield.push new Seabase.Item(type: 'weapon', attrs: SBConf.getWeapon(args['weapon']))
  toString: ->
    @char
  right: ->
    [@x + 1, @y]
  left: ->
    [@x - 1, @y]
  up: ->
    [@x, @y - 1]
  down: ->
    [@x, @y + 1]
  possibleMoves: ->
    allMoves = {}
    for move in ['up', 'down', 'left', 'right']
      [x,y] = this[move]()
      cm = @map.canMove(this, x, y)
      allMoves[cm] ||= []
      allMoves[cm].push [x,y]
    allMoves
  colour: ->
    SBConf.colours[@_colour]
  totalHP: ->
    Seabase.Util.sum _.values(@bodyParts).map (bp) ->
      bp.hp
  maxHP: =>
    Seabase.Util.sum @allLiveParts().map (bp) ->
      bp.maxhp
  # regenerate all hp
  regainHP: ->
    for bp in @allLiveParts()
      bp.hp = bp.maxhp
  # increase hp after level up
  increaseHP: (hp) ->
    totalHP = @maxHP()
    for bp in @allLiveParts()
      factor = bp.maxhp / totalHP
      bp.maxhp += Math.floor(hp * factor)
  allParts: ->
    _.values(@bodyParts)
  allLiveParts: ->
    _.values(@bodyParts).filter (bp) ->
      bp.hp > 0
  getArmourValue: ->
    rawArmourValue = Seabase.Util.sum @allParts().map (bp) ->
      if bp.wield then bp.wield.getArmourValue() else 0
    rawArmourValue * 10

  getWeaponDamage: (weapon) ->
    range = weapon.attrs.dmg 
    return Seabase.Util.randInt(range[0], range[1]) + @combatLevel()
  getWeaponAttackBonus: (weapon) ->
    weapon.attrs.att

  defence: ->
    @getArmourValue() + @def

  # give hitpoints to a random damaged bodypart
  giveHP: (hp) ->
    bp = _.sample @allLiveParts().filter (b) ->
      b.hp != b.maxhp
    if bp?
      bp.hp += hp
      if bp.hp > bp.maxhp
        bp.hp = p.maxhp

  # player is dead if any 'fatal' bodypart is dead
  isDead: ->
    @allParts().some (bp) ->
      bp.hp <= 0 && bp.fatal

  # apply damage to a bodypart
  applyDamage: (bp, hp) ->
    @bodyParts[bp].hp -= hp

  wear: (item, bp) ->
    # can wield only if the armour type matches the part
    if item instanceof Seabase.Item.Armour && item.getArmourType() == bp
      @bodyParts[bp].wield = item

  combatLevel: ->
    @level || @rank

  getAttacks: ->
    # allow player to attack with all wielded weapons for now
    return if @wield.length > 0 then @wield else []

require './util'
require './item'
class Seabase.Entity
  constructor: (@x, @y, @map, args = {}) ->
    @name = args['name'] || 'something'
    @inventory = null
    @weapon = null
    @wield = []
    @bodyParts = {}
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
  regainHP: ->
    for bp in @allLiveParts()
      bp.hp = bp.maxhp
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
  getWeaponDamage: (weapon) ->
    range = weapon.attrs.dmg 
    return Seabase.Util.randInt(range[0], range[1]) + @combatLevel()
  getWeaponAttackBonus: (weapon) ->
    weapon.attrs.att

  defence: ->
    0
  giveHP: (hp) ->
    bp = _.sample @allLiveParts().filter (b) ->
      b.hp != b.maxhp
    bp.hp += hp
    if bp.hp > bp.maxhp
      bp.hp = p.maxhp
  isDead: ->
    @allParts().some (bp) ->
      bp.hp <= 0 && bp.fatal
  applyDamage: (bp, hp) ->
    @bodyParts[bp].hp -= hp
  combatLevel: ->
    @level || @rank

  getAttacks: ->
    # allow player to attack with all wielded weapons for now
    return if @wield.length > 0 then @wield else [null]

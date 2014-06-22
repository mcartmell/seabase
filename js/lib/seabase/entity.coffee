class Seabase.Entity
  constructor: (@x, @y, @map, args = {}) ->
    @name = args['name'] || 'something'
    @char = args['char']
    @hp = @maxhp = args['hp'] || 10
    @power = args['power'] || 1
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

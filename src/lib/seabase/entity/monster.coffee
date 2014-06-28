_ = require 'underscore'

class Seabase.Entity.Monster extends Seabase.Entity
  constructor: (x,y,m,args) ->
    super(x,y,m,args)
    @level = args['level'] || 1
    @isMonster = true

  doMove: (map) ->
    moves = @possibleMoves()
    sel_moves = []
    f_moves = moves[Seabase.Map.MoveType.FIGHT]
    if f_moves && f_moves.length > 0
      sel_moves = moves[Seabase.Map.MoveType.FIGHT]
      sel_moves = _.filter sel_moves, (e) =>
        if target = @map.entityAt(e[0], e[1])
          if !target.isMonster
            return true
        return false

    if sel_moves.length == 0
      sel_moves = moves[Seabase.Map.MoveType.OK]
    move = _.shuffle(sel_moves)[0]
    [x,y] = move
    @map.tryEntityMove(this,x,y)

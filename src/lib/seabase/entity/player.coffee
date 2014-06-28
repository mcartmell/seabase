class Seabase.Entity.Player extends Seabase.Entity
  constructor: ->
    super
    @xp = 0
    @isPlayer = true
    @rank = 1
    @power = 5

  giveXP: (xp) ->
    @xp += xp
    newRank = @calcRank()
    if newRank > @rank
      @sb.pop 'Level up!' + "\n" + "You are now level #{newRank}"
      # level up!
      @rank = newRank
      # crude calculations
      @power += Seabase.randInt(1,3)
      @maxhp += Seabase.randInt(1,4)
      # regain hitpoints
      @hp = @maxhp

  giveHP: (hp) ->
    @hp += hp
    if @hp > @maxhp
      @hp = @maxhp

  calcRank: ->
    r = 1
    loop
      next_level = r + 1
      req = (2 * 10) * (2 ** (next_level - 2))
      if @xp < req
        return r
      else
        r = next_level
    return r

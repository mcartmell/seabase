class Seabase.Entity.Player extends Seabase.Entity
  constructor: ->
    super
    @xp = 0
    @isPlayer = true
    @rank = 1

  giveXP: (xp) ->
    @xp += xp
    newRank = @calcRank()
    if newRank > @rank
      @sb.pop 'Level up!' + "\n" + "You are now level #{newRank}"
      # level up!
      @rank = newRank
      # crude calculations
      @increaseHP(1,4)
      # regain hitpoints
      @regainHP()
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

  # pick up an item and add it to the inventory
  #TODO: can auto-wield or add cash here depending on the type of item
  take: (item) ->
    @inventory.push item
    @sb.log 'You picked up the ' + item.name

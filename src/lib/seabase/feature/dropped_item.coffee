class Seabase.Feature.DroppedItem extends Seabase.Feature
  constructor: (@item) ->
    super (@item.getChar() || '!')

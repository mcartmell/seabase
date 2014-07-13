class Seabase.Feature
  constructor: (@char) ->

  toString: ->
    @char

  isDownExit: ->
    @char == '>'

  isUpExit: ->
    @char == '<'

  canPickup: ->
    @ instanceof Seabase.Feature.DroppedItem

class Seabase.Log
  constructor: (@output, @buffer = 5) ->
    @msgs = []

  log: (msg) -> 
    @msgs.pop() if @msgs.size > @buffer
    @msgs.unshift(msg)
    @output.text = @msgs.join("\n")

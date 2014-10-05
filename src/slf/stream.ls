require! \./parse
require! <[ split stream-combiner through ]>

module.exports = ->
  parseable = ''
  stream-combiner split!, through (line) !->
    if line.index-of(\$$) is 0
      parseable += "#{line}\n"
    else
      if parseable is not ''
        try
          @queue parse parseable
        catch
          @queue parseable
        parseable := ''
        @queue '\n'
      @queue line .queue '\n'

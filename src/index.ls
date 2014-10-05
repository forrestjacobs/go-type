require! <[ ./go-type ./slf/stream ]>
require! <[ stream-combiner through ]>

go-type.stream = ->
  stream-combiner stream!, through (data) !->
    @.queue match typeof data
      | \string => data
      | _       => go-type.translate data

module.exports = go-type

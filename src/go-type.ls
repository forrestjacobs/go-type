require! <[ ./slf/parse ./svg/generate ]>
require! \d3

write = (element, model) !->
  model = parse model if typeof model is \string
  generate element, model

go-type = 
  write: write

  rewrite: !->
    element = d3.select this
    text = element.text!
    element.text ''
    write element, text

  translate: (model) ->
    element = d3.select \body .append \div .attr \class, \go-board-container
    write element, model
    html = element.node!outerHTML
    element.remove!
    html

if window?
  window.go-type = go-type
else
  module.exports = go-type

require! \./symbols
require! \d3

const margin = 0.5
const marker-attr = id: \arrow, class: \arrow, orient: \auto, view-box: '0 0 2 2', ref-x: 1, ref-y: 1
const marker-path = 'M 0 0 L 2 1 L 0 2 z'

translate = ([x, y]) ->
  "translate(#{x}, #{y})" unless x is 0 and y is 0

module.exports = (
  root,
  {data, directions, title, x-axis, y-axis},
  {cell-size = 30, label-size = 20, symbol-size = 15, axis-width = 21, line-stroke-width = 7, arrow-size = 18} = {}
) !->

  num-rows = data.length
  num-cols = data.0.length

  scale = d3.scale.linear!
    .domain [0, 1]
    .range [0, cell-size]

  # create the svg elem for the board
  board-size = (axis, length) ->
    axis-size = if axis? then axis-width else 0
    2 * margin + axis-size + scale length

  container = root.append \svg .attr do
    class: \go-board
    width:  board-size y-axis, num-cols
    height: board-size x-axis, num-rows

  # create the title
  if title
    root.append \div
      .text title
      .attr \class, \go-board-title

  # create the board offset group
  board-position = (axis, position) ->
    axis-size = if axis?position is position then axis-width else 0
    margin + axis-size + scale 0.5
  board = container.append \g
    .attr \transform, translate [(board-position y-axis, \left), (board-position x-axis, \top)]

  # add axes
  add-axis = (axis, length, translation-position, translation, tick-format-cb) !->
    if axis
      d3-axis = d3.svg.axis!
        .orient axis.position
        .scale scale
        .tick-values d3.range length
        .tick-size scale(0.5), 0
        .tick-format tick-format-cb
      board.append \g
        .attr \transform, ->
          translate translation if axis.position is translation-position
        .call d3-axis

  add-axis x-axis, num-cols, \bottom, [0, scale num-rows - 1], ->
    'ABCDEFGHJKLMNOPQRST'.char-at it + x-axis.start

  add-axis y-axis, num-rows, \right, [scale(num-cols - 1), 0], ->
    num-rows + y-axis.start - it

  # add bands (lines for each row and column)
  label-cover = label-size / scale 2
  add-bands = (name, s, near, far, data, translation-cb) ->
    board.select-all "g.#name"
      .data data
      .enter!append \g
      .attr do
        class: name
        transform: (, i) -> translate translation-cb scale i
      .each (d) !->
        elem = d3.select this
        iterate = (i, start) !->
          draw-line = (end) !->
            if end > start
              elem.append \line .attr do
                class: \grid
                "#{s}1": scale start
                "#{s}2": scale end
          e = d[i]
          if i >= d.length then draw-line d.length - 0.5
          else if e.separator?
            draw-line i - 0.5
            iterate i + 1, i + 0.5
          else if e.label? and e.intersection?
            draw-line i - label-cover
            iterate i + 1, i + label-cover unless e.border?[far]
          else if e.border?[far] then draw-line i
          else if e.stone? and start + 0.5 >= i then iterate i + 1, i + 0.5
          else iterate i + 1, start

        start =
          if d.0.border?[near] and not d.0.separator? then 0
          else -0.5
        iterate 0, start

  # add column bands
  col-data = [[item[d] for item in data] for d in d3.range(num-cols)]
  add-bands \col, \y, \top, \bottom, col-data, (i) -> [i, 0]

  # add row bands and insert a group for each cell in the row
  cells = add-bands \row, \x, \left, \right, data, (i) -> [0, i]
    .selectAll \g.row .data -> it
    .enter!append \g .attr do
      transform: (, i) -> translate [(scale i), 0]
      class: ({stone, symbol}:d) ->
        classes = [key for key of d]
        classes.push "#{stone.color}-stone" if stone?
        classes.push "#{symbol}-symbol" if symbol?
        "group #{["#{c}-group" for c in classes].join ' '}"
    .select ({link}) ->
      if link?
        d3.select this
          .append \a
          .attr \xlink:href, link
          .node!
      else this

  # appends the elem 'name' for each cell that has 'key' in its data.
  append-to-cells = (key, name) ->
    cells.select -> this if it[key]?
      .append name
      .attr \class, key

  # create the elements in each cell
  append-to-cells \star, \circle
    .attr \r, 0.5
  
  append-to-cells \stone, \circle
    .attr \r, scale 0.5
  
  append-to-cells \symbol, \path
    .attr \d, ({symbol}) -> symbols.path symbol, symbol-size

  append-to-cells \label, \text
    .text ({label}) -> label
    .attr \text-anchor : \middle, dy: \.32em

  append-to-cells \link, \circle
    .attr opacity: 0, r: scale 0.5

  # clean up
  board.select-all 'g.group:empty' .remove!
  board.select-all 'g.row:empty, g.col:empty' .remove!

  # add the lines and arrows
  if directions.length > 0
    marker-size = arrow-size / line-stroke-width
    container.append \defs .append \marker
      .attr marker-attr with { marker-width: marker-size, marker-height: marker-size }
      .append \path .attr \d, marker-path

    board .selectAll \path.direction .data directions .enter!append \path .attr do
        class: \direction
        \stroke-width : line-stroke-width
        \marker-end : ({type}) -> 'url(#arrow)' if type is \arrow
        d: ({type, start, end}) ->
          xy = ->
            x: scale it.col
            y: scale it.row
          start-xy = xy start
          end-xy = xy end
          diff =
            x: end-xy.x - start-xy.x
            y: end-xy.y - start-xy.y
          offset = if type is \line then 0
            else 0.5 * arrow-size / Math.sqrt(diff.x ^ 2 + diff.y ^ 2)
          "M #{start-xy.x} #{start-xy.y} L #{end-xy.x - diff.x * offset} #{end-xy.y - diff.y * offset}"

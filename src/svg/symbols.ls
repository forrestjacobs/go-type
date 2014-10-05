require! \d3

triangle-height = (Math.sqrt 3) / 2
center-height = 1 / 3

module.exports =
  path: (symbol, size) -> match symbol
    | \triangle =>
      "M #{-size / 2} #{size * center-height}
      h #size
      l #{-size / 2} #{-size * triangle-height}z"
    | \cross =>
      "M #{-size / 2} #{-size / 2}
      l #size #size
      m 0 #{-size}
      l #{-size} #size"
    | _ =>
      d3.svg.symbol!type symbol .size(size * size)!

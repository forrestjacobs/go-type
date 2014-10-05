const new-line-regex = /\r\n?|\n/g
const title-regex = /^\s*\$\$([WB])?(c)?(\d+)?(?:m(\d+))?(.*)$/
const line-regex = /^\s*\$\$(.*)$/
const border-row-regex = /^\s*-+\s*$/

const default-size = 19

make-stone = (color, symbol) ->
  stone: color: color
  symbol: symbol

make-intersection = (symbol) ->
  intersection: yes
  symbol: symbol

module.exports = (text) ->
  lines = text.trim!.split new-line-regex

  # Pares the title
  parsed-title-line = title-regex.exec lines.0

  starting-number = +parsed-title-line.4 or 1
  player-order = <[ white black ]>
    ..reverse! if parsed-title-line.1 is \W

  title = parsed-title-line.5.trim!
  size = +parsed-title-line.3 or default-size
  show-axis = parsed-title-line.2 is \c

  lines.shift!
  lines = [(line-regex.exec line .1).trim! for line in lines]

  direction-lines = [line.substring(1, line.length - 1).split ' ' for line in lines when line.char-at(0) is \{]

  links = {}
  for line in lines when line.char-at(0) is \[
    links[line.char-at 1] = line.substring 3, line.length - 1

  lines = [line for line in lines when line.char-at(0) not in [ \[ \{ ]]

  top    = border-row-regex.test lines.0
  bottom = border-row-regex.test lines[* - 1]
  lines.shift! if top
  lines.pop!   if bottom

  first-line = lines.0
  left  = first-line.char-at(0)                     is \|
  right = first-line.char-at(first-line.length - 1) is \|

  data = for line in lines
    chars = line.split ' '
    chars.shift! if left
    chars.pop!   if right

    cells = for char in chars
      value = match char
        | \. => make-intersection!
        | \, => intersection: yes, star: yes
        | \X => make-stone \black 
        | \O => make-stone \white 
        | \B => make-stone \black, \circle
        | \W => make-stone \white, \circle
        | \# => make-stone \black, \square
        | \@ => make-stone \white, \square
        | \Y => make-stone \black, \triangle
        | \Q => make-stone \white, \triangle
        | \Z => make-stone \black, \cross
        | \P => make-stone \white, \cross
        | \C => make-intersection \circle
        | \S => make-intersection \square
        | \T => make-intersection \triangle
        | \M => make-intersection \cross
        | \_ => separator: yes
        | _ =>
          number = +char
          unless isNaN number
            number = 10 if number is 0
            number = starting-number + number - 1

            stone: { color: player-order[number % 2] }
            label: number
          else intersection: yes, label: char
      value.link = links[char] if links[char]?
      value

    cells.0     .{}border.left  = left
    cells[* - 1].{}border.right = right

    cells

  for cell in data.0
    cell.{}border.top = top

  for cell in data[* - 1]
    cell.{}border.bottom = bottom

  rows = data.length
  cols = data.0.length

  size = rows if top  and bottom
  size = cols if left and right

  col-offset = if left   then 0 else size - cols
  row-offset = if bottom then 0 else size - rows

  if show-axis and (top or bottom) and (left or right)
    x-axis =
      start:    col-offset
      position: if bottom then \bottom else \top
    y-axis =
      start:    row-offset
      position: if left   then \left   else \right

  coordinate-to-row-col = (coordinate) ->
    if coordinate.index-of(\:) is -1
      col = ('ABCDEFGHJKLMNOPQRST'.index-of coordinate.substring 0, 1) - col-offset
      row = rows + row-offset - +coordinate.substring 1
    else
      split-coordinate = coordinate.split \:
      col = +split-coordinate.0 - 1
      row = +split-coordinate.1 - 1
    {row, col}

  directions = for direction in direction-lines
    type: match direction.0
      | \AR => \arrow
      | \LN => \line
    start: coordinate-to-row-col direction.1
    end:   coordinate-to-row-col direction.2

  { data, directions, title, x-axis, y-axis }

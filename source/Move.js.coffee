#= require roofpig/Layer
#= require roofpig/changers/CameraMovement
#= require roofpig/changers/MoveExecution

class @Move
  constructor: (code, @world3d, @speed = 400) ->
    [@layer, @turns, @is_rotation] = Move._parse_code(code)
    @turn_time = @speed/2 * (1 + Math.abs(@turns))

  @_parse_code: (code) ->
    turns = Move.parse_turns(code.substring(1))
    is_rotation = code.substring(1) in [">", ">>", "<", "<<"]
    layer = Layer.by_name(code[0])

    unless layer && turns
      throw new Error("Invalid Move code '#{code}'")
    [layer, turns, is_rotation]

  @parse_turns: (tcode) ->
    switch tcode
      when "1",  "", ">" then  1
      when "2", "²",">>" then  2
      when "3", "'", "<" then -1
      when "Z","2'","<<" then -2

  do: ->
    this._do(@turns, false)

  undo: ->
    this._do(-@turns, false)

  mix: ->
    unless @is_rotation
      this.undo()

  track_drift: (side_drift) ->
    for cycle in [@layer.cycle1, @layer.cycle2] when cycle[0].length == 1 # center cycle
      for side, location of side_drift
        for i in [0..3]
          if location == cycle[i]
            side_drift[side] = cycle[(i+@turns+4)% 4]

  show_do: ->
    this._do(@turns, true)

  show_undo: ->
    this._do( -@turns, true)

  _do: (do_turns, animate) ->
    if @is_rotation
      new CameraMovement(@world3d.camera, @layer.normal, do_turns * Math.PI/2, @turn_time, animate)
    else
      @world3d.pieces.move(@layer, do_turns)
      new MoveExecution(@world3d.pieces.on(@layer), @layer.normal, do_turns * -Math.PI/2, @turn_time, animate)

  count: (count_rotations) ->
    return 1 if count_rotations || not @is_rotation
    0

  to_s: ->
    turn_codes = { true: { 1: '>', 2: '>>', '-1': '<', '-2': '<<'}, false: { 1: '', 2: '2', '-1': "'", '-2': 'Z'}}
    "#{@layer.name}#{turn_codes[@is_rotation][@turns]}"

  @displayify: (move_text, algdisplay) ->
    result = move_text.replace('Z', algdisplay.Zcode)
    result = result.replace('2', '²') if algdisplay.fancy2s
    result

  display_text: (algdisplay) ->
    return Move.displayify(this.to_s(), algdisplay) if algdisplay.rotations || not @is_rotation
    ''

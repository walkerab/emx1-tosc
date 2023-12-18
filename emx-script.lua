function sleep(t)
  local start = getMillis()
  local now = 0
  repeat
    now = getMillis()
  until(now - start >= t)
end

function seq(s)
  for _, v in ipairs(s) do
    sendMIDI(v)
    sleep(1)
  end
end

function get_bitmasks_from_grid(grid)
  grid_items = grid.children
  drum_section_1_mask = 127
  for i=1,7 do
    if grid_items[i].values.x == 1 then
      drum_section_1_mask = bitwise_unmute(drum_section_1_mask, i-1)
    end
  end
  drum_section_2_mask = 3
  for i=8,9 do
    if grid_items[i].values.x == 1 then
      drum_section_2_mask = bitwise_unmute(drum_section_2_mask, i-8)
    end
  end
  synth_section_mask = 31
  for i=10,14 do
    if grid_items[i].values.x == 1 then
      synth_section_mask = bitwise_unmute(synth_section_mask, i-10)
    end
  end
  return synth_section_mask, drum_section_1_mask, drum_section_2_mask
end

debug_last_sent = nil
function sendMuteNRPN(drum_section_1_mask, drum_section_2_mask, synth_section_mask)
  seq({
    {MIDIMessageType.CONTROLCHANGE,99,11},
    {MIDIMessageType.CONTROLCHANGE,98,119},
    {MIDIMessageType.CONTROLCHANGE,6,0},
    {MIDIMessageType.CONTROLCHANGE,38,synth_section_mask},
    {MIDIMessageType.CONTROLCHANGE,98,120},
    {MIDIMessageType.CONTROLCHANGE,6,drum_section_2_mask},
    {MIDIMessageType.CONTROLCHANGE,38,drum_section_1_mask}
  })
  print(synth_section_mask, drum_section_1_mask, drum_section_2_mask)
  debug_last_sent = {
    synth_section_mask = synth_section_mask,
    drum_section_1_mask = drum_section_1_mask,
    drum_section_2_mask = drum_section_2_mask
  }
end

when = nil
queuedGrid = nil
function queueGrid(args)
  when = args.when
  queuedGrid = args.grid
  print('queuedGrid', when)
  if when == nil then
    sendGrid()
  end
end

pushGrid = nil
function startPushGrid(args)
  pushGrid = args.grid
end

function endPushGrid()
  pushGrid = nil
end

function sendGrid(grid)
  grid = grid or queuedGrid
  synth_section_mask, drum_section_1_mask, drum_section_2_mask = get_bitmasks_from_grid(grid)
  print("sending grid", drum_section_1_mask, drum_section_2_mask, synth_section_mask)
  sendMuteNRPN(drum_section_1_mask, drum_section_2_mask, synth_section_mask)
end

function bitwise_unmute(bits, unmute_index)
  return bit32.band(bits, bit32.bnot(bit32.lshift(1,unmute_index)))
end

position = 0
playing = false

function start()
  playing = true
  position = 0
  print('play')
end

function stop()
  playing = false
  print('stop')
end

function advanceClock(offset)
  offset = offset or 1
  position = position + offset
  -- print("advanceClock() sees position == ", position, " and when == ", when)
  if when ~= nil and position >= when then
    print('sending grid based on clock')
    sendGrid()
  end
  if position >= 96 then
    position = position % 96
    when = nil
  end
  if pushGrid ~= nil then
    sendGrid()
  end
end

function resetClock()
  position = 0
end

-- 768 clocks in 8 progressions
-- 96 in 1 progression

function onReceiveMIDI(message, connections)
  if message[1] == MIDIMessageType.START then
    start()
  elseif message[1] == MIDIMessageType.STOP then
    stop()
  elseif message[1] == MIDIMessageType.CLOCK and playing then
    advanceClock()
  end
end

function isControlChange(message)
  return message[1] >= MIDIMessageType.CONTROLCHANGE and message[1] < MIDIMessageType.CONTROLCHANGE + 16
end

control_changes = {}
function stashControlChange(message)
  if control_changes[message[1]] == nil then
    control_changes[message[1]] = {}
  end
  if control_changes[message[2]] == nil then
    control_changes[message[2]] = {}
  end
  control_changes[message[1]][message[2]] = message[3]
end

function peekControlChange(message)
  if control_changes[message[1]] == nil or control_changes[message[2]] == nil then
    return nil
  end
  return control_changes[message[1]][message[2]]
end

function clearControlChangeStash()
  control_changes = {}
end

function popControlChangeStash()
  control_changes_copy = control_changes
  clearControlChangeStash()
  return control_changes_copy
end

function sequenceFromControlChangeStash(control_changes)
  return {}
end

function clearGrid(grid)
  for i=1,#grid.children do
    grid.children[i].values.x = 0
  end
end

function assert(assertion, failure_message)
  failure_message = failure_message or ""
  if not assertion then error(failure_message) end
end

function runTests(args)
  print("running tests")

  clearGrid(args.grid)
  args.grid.children[1].values.x = 1
  sendGrid(args.grid)
  -- Expect only the first button to be pressed
    -- 0b1111110 = 126
    -- 0b11 = 3
    -- 0b11111 = 31
    assertSent(126,3,31)

  clearGrid(args.grid)
  sendGrid(args.grid)
  -- Expect no buttons to be pressed
    -- 0b1111111 = 127
    -- 0b11 = 3
    -- 0b11111 = 31
    assertSent(127,3,31)

    clearGrid(args.grid)
    args.grid.children[14].values.x = 1
    sendGrid(args.grid)
    -- Expect only the last synth button to be pressed
      -- 0b1111111 = 127
      -- 0b11 = 3
      -- 0b01111 = 15
      assertSent(127,3,15)

  advanceClock(96)
  assert(position == 0, "position == "..position)
  advanceClock(0)
  assert(position == 0, "position == "..position)
  advanceClock(97)
  assert(position == 1, "position == "..position)
  advanceClock(96)
  assert(position == 1, "position == "..position)
  advanceClock()
  assert(position == 2, "position == "..position)
  resetClock()
  assert(position == 0, "position == "..position)

  -- it sends the grid after one bar
  clearGrid(args.grid)
  args.grid.children[1].values.x = 1
  queueGrid({ grid = args.grid, when = 96 })
  advanceClock(96)
  assertSent(126,3,31)

  -- it sends the grid repeatedly for every clock pulse until we tell it to stop
  clearGrid(args.grid)
  args.grid.children[1].values.x = 1
  startPushGrid({ grid = args.grid })
  advanceClock()
  assertSent(126,3,31)
  sendMuteNRPN(127,3,31)
  assertSent(127,3,31)
  advanceClock()
  assertSent(126,3,31)
  endPushGrid()
  sendMuteNRPN(127,3,31)
  assertSent(127,3,31)
  advanceClock()
  assertSent(127,3,31)
  resetClock()

  -- detects control change channel 1
  assert(isControlChange({ MIDIMessageType.CONTROLCHANGE, 1, 102 }) == true, "MIDIMessageType.CONTROLCHANGE on channel 1 not detected as control change")
  assert(isControlChange({ MIDIMessageType.CONTROLCHANGE+1, 1, 106 }) == true, "MIDIMessageType.CONTROLCHANGE on channel 2 not detected as control change")
  assert(not isControlChange({ MIDIMessageType.CONTROLCHANGE+100, 1, 106 }) == true, "MIDIMessageType.CONTROLCHANGE on invalid channel detected as control change")
  assert(not isControlChange({ MIDIMessageType.NOTE_ON, 12, 88 }), "MIDIMessageType.NOTE_ON detected as MIDIMessageType.CONTROLCHANGE")

  -- can save/replay last value of control changes
  stashControlChange({ MIDIMessageType.CONTROLCHANGE, 1, 102 })
  assert(peekControlChange({ MIDIMessageType.CONTROLCHANGE, 1 }) == 102)
  stashControlChange({ MIDIMessageType.CONTROLCHANGE, 1, 127 })
  assert(peekControlChange({ MIDIMessageType.CONTROLCHANGE, 1 }) == 127)
  stashControlChange({ MIDIMessageType.CONTROLCHANGE+2, 1, 1 })
  assert(peekControlChange({ MIDIMessageType.CONTROLCHANGE+2, 1 }) == 1)
  clearControlChangeStash()
  assert(peekControlChange({ MIDIMessageType.CONTROLCHANGE+2, 1 }) == nil)
  
  -- clearControlChangeStash()
  -- assert(equals(popControlChangeStash(), {}, true))
  -- stashControlChange({ MIDIMessageType.CONTROLCHANGE, 1, 102 })
  -- table.concat(popControlChangeStash())
  -- assert(equals(popControlChangeStash(), {
  --   [MIDIMessageType.CONTROLCHANGE] = {
  --     [1] = 102
  --   }
  -- }, true), "oopsy")
  -- assert(sequenceFromControlChangeStash(popControlChangeStash() == {}))

  print("All tests passed!")
end

function equals(o1, o2, ignore_mt)
  if o1 == o2 then return true end
  local o1Type = type(o1)
  local o2Type = type(o2)
  if o1Type ~= o2Type then return false end
  if o1Type ~= 'table' then return false end

  if not ignore_mt then
      local mt1 = getmetatable(o1)
      if mt1 and mt1.__eq then
          --compare using built in method
          return o1 == o2
      end
  end

  local keySet = {}

  for key1, value1 in pairs(o1) do
      local value2 = o2[key1]
      if value2 == nil or equals(value1, value2, ignore_mt) == false then
          return false
      end
      keySet[key1] = true
  end

  for key2, _ in pairs(o2) do
      if not keySet[key2] then return false end
  end
  return true
end

function assertSent(drum_section_1_mask, drum_section_2_mask, synth_section_mask)
  assert(debug_last_sent.drum_section_1_mask == drum_section_1_mask, "drum_section_1_mask == "..debug_last_sent.drum_section_1_mask)
  assert(debug_last_sent.drum_section_2_mask == drum_section_2_mask, "drum_section_2_mask == "..debug_last_sent.drum_section_2_mask)
  assert(debug_last_sent.synth_section_mask == synth_section_mask, "synth_section_mask == "..debug_last_sent.synth_section_mask)
end

methods = {
  queueGrid = queueGrid,
  runTests = runTests,
  startPushGrid = startPushGrid,
  endPushGrid = endPushGrid
}

function onReceiveNotify(from, to)
--  _G[method](args)
  method, args = table.unpack(to)
  print(method, args)
  for k,v in pairs(args) do
    print(k, ":", v)
  end
--  loadstring(method.."()")(args)
  methods[method](args)
end
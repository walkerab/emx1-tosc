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
  elseif stash_control_changes and isControlChange(message) and not messageIsNRPN(message) then
    stashControlChange(message)
    debugControlChangeStash()
  end
end

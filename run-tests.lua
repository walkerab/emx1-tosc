function runTests(args)
  print("running tests")

  clearGrid(args.grid1)
  args.grid1.children[1].values.x = 1
  sendGrid(args.grid1)
  -- Expect only the first button to be pressed
    -- 0b1111110 = 126
    -- 0b11 = 3
    -- 0b11111 = 31
    assertSent(126,3,31)

  clearGrid(args.grid1)
  sendGrid(args.grid1)
  -- Expect no buttons to be pressed
    -- 0b1111111 = 127
    -- 0b11 = 3
    -- 0b11111 = 31
    assertSent(127,3,31)

    clearGrid(args.grid1)
    args.grid1.children[14].values.x = 1
    sendGrid(args.grid1)
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
  clearGrid(args.grid1)
  args.grid1.children[1].values.x = 1
  queueGrid({ grid = args.grid1, when = 96 })
  advanceClock(96)
  assertSent(126,3,31)

  -- it sends the grid repeatedly for every clock pulse until we tell it to stop
  clearGrid(args.grid1)
  args.grid1.children[1].values.x = 1
  startPushGrid({ grid = args.grid1 })
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
  assert(peekControlChangeStash({ MIDIMessageType.CONTROLCHANGE, 1 }) == 102)
  stashControlChange({ MIDIMessageType.CONTROLCHANGE, 1, 127 })
  assert(peekControlChangeStash({ MIDIMessageType.CONTROLCHANGE, 1 }) == 127)
  stashControlChange({ MIDIMessageType.CONTROLCHANGE+2, 1, 1 })
  assert(peekControlChangeStash({ MIDIMessageType.CONTROLCHANGE+2, 1 }) == 1)
  clearControlChangeStash()
  assert(peekControlChangeStash({ MIDIMessageType.CONTROLCHANGE+2, 1 }) == nil)
  
  clearControlChangeStash()
  assert(equals(peekControlChangeStash(), {}))
  clearControlChangeStash()
  stashControlChange({ MIDIMessageType.CONTROLCHANGE, 1, 102 })
  assert(equals(peekControlChangeStash(), {
    [MIDIMessageType.CONTROLCHANGE] = {
      [1] = 102
    }
  }), "oopsy")
  
  assert(equals(
    sequenceFromControlChangeStash({
      [MIDIMessageType.CONTROLCHANGE] = {
        [1] = 102
      }
    }),
    {
      { MIDIMessageType.CONTROLCHANGE, 1, 102 }
    }
  ))
  assert(equals(
    sequenceFromControlChangeStash({
      [MIDIMessageType.CONTROLCHANGE] = {
        [1] = 102
      },
      [MIDIMessageType.CONTROLCHANGE+1] = {
        [1] = 102
      }
    }),
    {
      { MIDIMessageType.CONTROLCHANGE, 1, 102 },
      { MIDIMessageType.CONTROLCHANGE+1, 1, 102 }
    }
  ))
  assert(equals(
    sequenceFromControlChangeStash({
      [MIDIMessageType.CONTROLCHANGE] = {
        [1] = 102,
        [2] = 100
      },
      [MIDIMessageType.CONTROLCHANGE+1] = {
        [1] = 102
      }
    }),
    {
      { MIDIMessageType.CONTROLCHANGE, 1, 102 },
      { MIDIMessageType.CONTROLCHANGE, 2, 100 },
      { MIDIMessageType.CONTROLCHANGE+1, 1, 102 }
    }
  ))

  print("All tests passed!")
end

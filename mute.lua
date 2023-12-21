function bitwise_unmute(bits, unmute_index)
  return bit32.band(bits, bit32.bnot(bit32.lshift(1,unmute_index)))
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

function messageIsMuteNRPN(message)
  return isControlChange(message) and (
    message[2] == 99
    or
    message[2] == 98
    or
    message[2] == 6
    or
    message[2] == 38
  )
end

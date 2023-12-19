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

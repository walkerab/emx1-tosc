function debugControlChangeStash()
  printTable(control_change_stash)
end

function isControlChange(message)
  return message[1] >= MIDIMessageType.CONTROLCHANGE and message[1] < MIDIMessageType.CONTROLCHANGE + 16
end

control_change_stash = {}
function stashControlChange(message)
  if control_change_stash[message[1]] == nil then
    control_change_stash[message[1]] = {}
  end
  control_change_stash[message[1]][message[2]] = message[3]
end

function peekControlChangeStash(message)
  if message == nil then
    return control_change_stash
  end
  if control_change_stash[message[1]] == nil then
    return nil
  end
  return control_change_stash[message[1]][message[2]]
end

function clearControlChangeStash()
  control_change_stash = {}
end

function popControlChangeStash()
  control_change_stash_copy = control_change_stash
  clearControlChangeStash()
  return control_change_stash_copy
end

function sequenceFromControlChangeStash(control_change_stash)
  local acc = {}
  for channel, control_codes in pairs(control_change_stash) do
    for control_code, control_value in pairs(control_codes) do
      table.insert(acc, { channel, control_code, control_value })
    end
  end
  return acc
end

stash_control_changes = true
function startStashingControlChanges()
  stash_control_changes = true
end

function stopStashingControlChanges()
  stash_control_changes = false
end

function playBackControlChangeStash()
  seq(sequenceFromControlChangeStash(control_change_stash))
end

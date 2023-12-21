function assert(assertion, failure_message)
  failure_message = failure_message or ""
  if not assertion then error(failure_message, 2) end
end

function equals(o1, o2)
  if o1 == o2 then return true end
  local o1Type = type(o1)
  local o2Type = type(o2)
  if o1Type ~= o2Type then return false end
  if o1Type ~= 'table' then return false end

  local keySet = {}

  for key1, value1 in pairs(o1) do
      local value2 = o2[key1]
      if value2 == nil or equals(value1, value2) == false then
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

function printTable(t, indent)
  local indent = indent or 0
  print(string.rep("  ", indent).."{")
  for k, v in pairs(t) do
    if type(v) ~= "table" then
      print(string.rep("  ", indent+1)..k, ":", v)
    else
      print(string.rep("  ", indent+1)..k, ":")  
      printTable(v, indent+1)
    end
  end
  print(string.rep("  ", indent).."}")
end

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

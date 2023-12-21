methods = {
  runTests = runTests,
  queueGrid = queueGrid,
  startPushGrid = startPushGrid,
  endPushGrid = endPushGrid,
  startStashingControlChanges = startStashingControlChanges,
  stopStashingControlChanges = stopStashingControlChanges,
  playBackControlChangeStash = playBackControlChangeStash,
  clearControlChangeStash = clearControlChangeStash
}

function onReceiveNotify(from, to)
  method, args = table.unpack(to)
  print("onReceiveNotify", method)
  print(method, args)
  for k,v in pairs(args) do
    print(k, ":", v)
  end
  methods[method](args)
end

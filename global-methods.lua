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
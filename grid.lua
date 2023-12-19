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

function clearGrid(grid)
  for i=1,#grid.children do
    grid.children[i].values.x = 0
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

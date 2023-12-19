tell application "System Events" to tell process "TouchOSC"
    set frontmost to true
    do shell script "/opt/homebrew/bin/cliclick c:1159,426"
    click menu item "Select All" of menu 1 of menu bar item "Edit" of menu bar 1
    do shell script "cat utils.lua clock.lua mute.lua grid.lua control-change-stash.lua test-helpers.lua run-tests.lua global-methods.lua | pbcopy"
    click menu item "Paste" of menu 1 of menu bar item "Edit" of menu bar 1
    click menu item "Toggle Editor" of menu 1 of menu bar item "View" of menu bar 1

    do shell script "/opt/homebrew/bin/cliclick dd:1111,86"
    do shell script "/opt/homebrew/bin/cliclick du:1111,86"
end tell
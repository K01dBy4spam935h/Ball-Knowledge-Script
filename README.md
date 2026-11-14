Ball Knowledge Exploit (multi-file)

Exploit/
  load.lua              entry — loadstring this
  modules/
    Config.lua          delays, tiers, toggles
    Bank.lua            answer bank by prompt.id
    Harvest.lua         session discovery + dump
    Core.lua            remotes, match, submit, auto
    UI.lua              panel, support indicator, buttons

GitHub loadstring





Push this folder to a repo (raw files must be public).



Edit load.lua → set BASE to your raw root, e.g.

local BASE = "https://raw.githubusercontent.com/You/bk-exploit/main/"

If modules live at modules/ under that root, the loader already requests BASE .. "modules/Config.lua" etc.





In executor:

loadstring(game:HttpGet("https://raw.githubusercontent.com/You/bk-exploit/main/load.lua"))()

Local

Set in load.lua:

local USE_HTTP = false
local LOCAL_DIR = "modules/"  -- or full path your executor uses

Then loadstring(readfile("load.lua"))().

Flow





Play matches → reveals harvest into session + merge into Bank



Red UNSUPPORTED → answer manually (still harvests your lock)



Dump new questions → prints BK_Harvest.lua table; paste answers into modules/Bank.lua under the matching id permanently

Bank format

trees = {
  { text = "Wollemi Pine", tier = "Legendary" },
  { text = "Mockernut Hickory", tier = "Rare" },
},


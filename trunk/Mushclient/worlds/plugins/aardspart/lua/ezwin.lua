-------------------------------------------------------------------------------
-- BEGIN ezwin miniwindow class
-------------------------------------------------------------------------------
ezwin = {}
function ezwin.new(name, left, top, width, height, pos, flags, bg, fg, var)
    local self = {}
    self.name = name
    self.var = var
    WindowCreate(name, left, top, width, height, pos, flags, bg)
        
    function self.loadFont(id, f, ds)
        local nm, sz, bl, it, ul, so
        if f ~= nil then
            nm, sz, bl, it, ul, so = f.name, f.size, f.bold, f.italic, f.underline, f.strikeout
        else
            Note("loadFont: nil font table.")
            nm, sz, bl, it, ul, so = '-NoFont', 12, false, false, false, false
        end
        local res = WindowFont (self.name, id, nm, sz, bl, it, ul, so) -- default font
        if res == error_code.eNoSuchWindow then
            Note("loadFont: no such window.")
            ColourNote("white","red","No such window: ", self.name, " in ezwin.loadFont().")
            ColourNote("white","red","Please notify the plugin author: ", GetPluginInfo(GetPluginId(), 2))
        elseif res == error_code.eCannotAddFont then
            Note("loadFont: bad font.")
            ColourNote("yellow","black","Could not load font: ", nm, " (", id, ")")
            ColourNote("yellow","black","Using default font.")
            nm, sz, bl, it, ul, so = '-NoFont', 12, false, false, false, false
            res = WindowFont (self.name, id, nm, sz, bl, it, ul, so) -- default font
        else  -- res == eOK
            -- font was loaded - no op here.
        end
    end --self.loadFont
    
    function self.addDrag()
        -- creates a hotspot that covers the entire window and is linked to the window drag handlers
        self.events = events.new(self)
        res = WindowAddHotspot(self.name, "hs1",  
                         0, 0, WindowInfo(self.name, 3), WindowInfo(self.name, 4),   -- rectangle
                         "",   -- MouseOver
                         "",   -- CancelMouseOver
                         self.var .. ".events.mousedown",
                         self.var .. ".events.cancelmousedown", 
                         self.var .. ".events.mouseup", 
                         "Left-Click to drag this window.\nRight-Click to configure.",  -- tooltip text
                         1, 0)  -- hand cursor
        res = WindowDragHandler (self.name, "hs1", self.var .. ".events.dragmove", self.var .. ".events.dragrelease", 0)
    end --self.addDrag
    
    function self.createMenu()
        if self.menuColor == nil then self.menuColor = ColourNameToRGB("white") end
        WindowPolygon(win, "4,4,18,4,11,14" , self.menuColor, 6, 1, self.menuColor, 8 , true, false)
        self.menu = menu.new(self)
        WindowAddHotspot(self.name, "0hs",  
                 0, 0, 20, 20,   -- rectangle
                 "",   -- MouseOver
                 "",   -- CancelMouseOver
                 "",
                 "", 
                 self.var .. ".menu.showMenu", 
                 "Click to configure smoothTick.",  -- tooltip text
                 1, 0)  -- hand cursor
    end --self.createMenu
    
    function self.bringToFront()
        local wl = WindowList()
        local m
        for _, w in pairs(wl) do
            m = math.max(m or 0, WindowInfo(w, 22))
        end
        WindowSetZOrder(self.name, m + 1)
    end --self.bringToFront
      
    function self.sendToBack()
        local wl = WindowList()
        local m
        for _, w in pairs(wl) do
            m = math.min(m or 0, WindowInfo(w, 22))
        end
        WindowSetZOrder(self.name, m - 1)
    end --self.sendToBack

    return self
end --ezwin.new
-------------------------------------------------------------------------------
-- END ezwin miniwindow class
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- BEGIN miniwindow menu class
-------------------------------------------------------------------------------
menu = {}
function menu.new(win)
    local self = {}
    self.win = win
  
    function self.add(item)
        -- a menu item table should contain the following elements:
        --   displayName = text to be displayed on the menu.
        --   enabled     = boolean true to enable, false to disable
        --   checked     = function to determine whether or not the item is checked.
        --                 true = checked, false = unchecked.  If a boolean value is
        --                 supplied, then the state can not be changed by the menu.
        --   callback    = function to call when the menu item is selected
        --   submenu     = boolean true if future items should be children of this
        --                 item.  true with nil display name to end a submenu.
        -- if item is nil, then a separator will be added
        -- if displayName is nil and submenu is true the current submenu will end
        local msg = ''
        self.menu = self.menu or {}
        self.mActive = {}
        menu = self.menu -- shortcut
    
        if item == nil then
            table.insert(menu, {displayName = '-'})
            return
        end
        if item.displayName == nil and item.submenu then
            table.insert(menu, {displayName = '<'})
            return
        end
    
        if type(item.displayName) ~= 'string' and type(item.displayName) ~= 'function' then
            msg = 'menu item ' .. #menu + 1 .. ' could not be added.  displayName must be string or a function that returns string.'
        end
        if type(item.enabled) ~= 'boolean' and type(item.enabled) ~= 'function' then
            msg = msg .. '\n' .. 'menu item ' .. item.displayName .. ' could not be added.  enabled must be boolean or a function that returns boolean.'
        end
        if not item.submenu and type(item.callback) ~= 'function' then
            msg = msg .. '\n' .. 'menu item ' .. item.displayName .. ' could not be added.  callback must be a function.'
        end
    
        if msg:len() > 0 then
            -- something is wrong with this menu item, so we are not going to use it.
            ColourNote("yellow","black",msg)
            ColourNote("yellow","black","please notify the plugin author of this problem.")
        else
            -- add new item
            n = n or 1
            table.insert(menu, {displayName = item.displayName, enabled = item.enabled, checked = item.checked, callback = item.callback, submenu = item.submenu})
        end
        return
    end --self.add
  
    function self.buildMenu()
        local mStr = ''
        for _, item in pairs(self.menu) do
            if mStr:len() > 0 then mStr = mStr .. ' | ' else mStr = '!' end
            if item.displayName == '-' or item.displayName == '<' then
                mStr = mStr .. item.displayName  
            else
                if type(item.checked)=='function' then checked = item.checked() else checked = item.checked end
                if type(item.enabled)=='function' then enabled = item.enabled() else enabled = item.enabled end
                if type(item.submenu)=='function' then submenu = item.submenu() else submenu = item.submenu end
                if checked ~= nil then
                    if checked then
                        mStr = mStr .. '+' .. item.displayName
                    else
                        mStr = mStr .. item.displayName
                    end
                    -- this item counts, so tag it and increment our counter
                    table.insert(self.mActive, item)
                elseif enabled == false then -- we don't want nil values to give us a false negative on this flag...
                    mStr = mStr .. '^' .. item.displayName  -- not counted
                elseif submenu then
                    mStr = mStr .. '>' .. item.displayName
                    -- this item counts, so tag it and increment our counter
                    -- table.insert(self.mActive, item)
                else
                    mStr = mStr .. item.displayName
                    -- this item counts, so tag it and increment our counter
                    table.insert(self.mActive, item)        
                end
            end
        end
        return mStr
    end --self.buildMenu
  
    function self.showMenu(flags, hotspot_id)  -- this is what will be called to start the menu
        OnPluginSaveState()
        mStr = self.buildMenu()
        if mStr:len() == 0 then return end
        local res = tonumber(WindowMenu(self.win.name, 5, 5, mStr)) or -1
        if res > 0 and res <= #self.mActive then
            self.mActive[res].callback()
        elseif res >= 1 then
            ColourNote('yellow','black','Unkown menu option (' .. res .. ').  Please contact the plugin developer.')
        end
        OnPluginSaveState()
    end --self.showMenu
  
    return self
end --menu.new
-------------------------------------------------------------------------------
-- END miniwindow menu class
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- BEGIN miniwindow event handler class
-------------------------------------------------------------------------------
events = {}
function events.new(win)
    local self = {}
    self.win = win
  
    function self.mousedown(flags, hotspot_id)
        startx, starty = WindowInfo (self.win.name, 14), WindowInfo (self.win.name, 15)
        WindowSetZOrder(self.win.name, 1200)
    end -- mousedown

    function self.cancelmousedown(flags, hotspot_id)
    end -- cancelmousedown

    function self.mouseup(flags, hotspot_id)
        if hasbit(flags, miniwin.hotspot_got_rh_mouse) then
            self.win.menu.showMenu()
        end
    end -- mouseup

    function self.dragmove(flags, hotspot_id)
        if hasbit(flags, miniwin.hotspot_got_rh_mouse) then
            -- don't drag on right-click
            return
        end
        local posx, posy, flags = WindowInfo (self.win.name, 17),
                                        WindowInfo (self.win.name, 18),
                                        WindowInfo(self.win.name, 8)
        WindowPosition(self.win.name, posx - startx, posy - starty, 0, setbit(flags, 2));
    
        -- change the mouse cursor shape appropriately
        if posx < 0 or posx > GetInfo (281) or
            posy < 0 or posy > GetInfo (280) then
            check (SetCursor ( 11))   -- X cursor
        else
            check (SetCursor ( 1))   -- hand cursor
        end -- if    
    end -- dragmove
  
    function self.dragrelease(flags, hotspot_id)
        OnPluginSaveState()
    end -- dragrelease
  
    return self
end --events.new
-------------------------------------------------------------------------------
-- END miniwindow event handler class
-------------------------------------------------------------------------------
guSB = CreateFrame("Frame","guSB")

guSB:SetScript("OnEvent", function(self, event, ...)
	self[event](self, event, ...)
end)

guSB:RegisterEvent("ADDON_LOADED")

local buffs = {}
local debuffs = {}
local wench = {}
local auras = {wench,buffs,debuffs}
local buffs_anchor, debuffs_anchor, cons_frame

local cons_num, cons_btn
local consolidatedbtn = {}
local consolidated = {}

local arset = {}

local defaults = {
    buffs_point = "TOPRIGHT",
    buffs_x = -150,
    buffs_y = -10,
    debuffs_point = "TOPRIGHT",
    debuffs_x = -133,
    debuffs_y = -138,
    growthy = "BOTTOM",
    growthx = "LEFT",
    orientation = "HORIZONTAL",
    maxlength = 16,
    gap = 5,
    width = 30,
    height = 25,
    hideblizzard = true,
    consolidate = true,
}

local function Flip(p1,x,y)
    local p2 = ""
    local dir
    if p1 == "CENTER" then return "CENTER" end
        if string.find(p1,"TOP") then p2 = p2..(y and "BOTTOM" or "TOP")end
        if string.find(p1,"BOTTOM") then p2 = p2..(y and "TOP" or "BOTTOM") end
        if string.find(p1,"LEFT") then p2 = p2..(x and "RIGHT" or "LEFT") end
        if string.find(p1,"RIGHT") then p2 = p2..(x and "LEFT" or "RIGHT") end
    if p2 == "RIGHT" or p2 == "LEFT" then
        dir = "HORIZONTAL"
    elseif p2 == "TOP" or p2 == "BOTTOM" then
        dir = "VERTICAL"
    end
    return p2, dir
end

function guSB.ADDON_LOADED(self,event,arg1)
    if arg1 == "guSmallBuffs" then
        gusbDB = gusbDB or {}
        gusbDB.cons_ids = gusbDB.cons_ids or {}
        gusbDB = setmetatable(gusbDB,{ __index = function(t,k) return defaults[k] end})
        
        guSB:UpdateLayoutSettings()
        buffs_anchor = self:CreateAnchor("buffs")
        debuffs_anchor = self:CreateAnchor("debuffs")
        
        guSB:RegisterEvent("UNIT_AURA")
        if gusbDB.hideblizzard then
            BuffFrame:UnregisterEvent("UNIT_AURA")
            BuffFrame:Hide()
            ConsolidatedBuffs.Show = ConsolidatedBuffs.Hide
            ConsolidatedBuffs:Hide()
            TemporaryEnchantFrame:Hide()
        end
                
        if gusbDB.consolidate then
            cons_btn = guSB:MakeConsButton()
            table.insert(auras, 1, consolidatedbtn)
            table.insert(auras, consolidated)
            consolidatedbtn[1] = cons_btn
            cons_frame = guSB:MakeConsolidatedFrame(cons_btn)
        end
        guSB.CheckWeaponEnchants(self)
        guSB:UNIT_AURA(nil, "player")
        
        SLASH_GUSB1= "/gusb"
        SLASH_GUSB2= "/gusmallbuffs"
        SlashCmdList["GUSB"] = guSB.SlashCmd
    end
end

function guSB.UNIT_AURA(self, event, unit)
    if unit ~= "player" then return end
    
    if gusbDB.consolidate then 
        cons_num = 0
        for i,btn in pairs(consolidated) do
            consolidated[i] = nil
        end
    end
    
    local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID
    for i=1, BUFF_MAX_DISPLAY do
        name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura("player",i,"HELPFUL")
        if not name then
            for j=i,BUFF_MAX_DISPLAY do
                if buffs[j] then buffs[j]:Hide()
                else break end
            end
            break
        end
        
        if not buffs[i] then
            local btn = self:CreateBuffIcon("buff")
            btn.id = i
            buffs[i] = btn
        end
        
        local btn = buffs[i]
        btn.icon:SetTexture(icon)
        btn.bar:SetMinMaxValues(0, duration)
        btn.count:SetText(count)
        if count > 1 then btn.count:Show() else btn.count:Hide() end
        btn.duration = duration
        btn.expires = expires
        btn.OnUpdateCounter = 1
        btn:Show()
        
        if gusbDB.consolidate then
            if shouldConsolidate then
                consolidated[i] = btn
                btn:SetParent(cons_frame)
                cons_num = cons_num + 1
            else
                btn:SetParent(UIParent)
            end
        end
    end
    for i=1, DEBUFF_MAX_DISPLAY do
        name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura("player",i,"HARMFUL")
        if not name then
            for j=i,DEBUFF_MAX_DISPLAY do
                if debuffs[j] then debuffs[j]:Hide()
                else break end
            end
            break
        end
        
        if not debuffs[i] then
            local btn = self:CreateBuffIcon("debuff")
            btn.id = i
            debuffs[i] = btn
        end
        
        local btn = debuffs[i]
        btn.icon:SetTexture(icon)
            local color
            if ( dispelType ) then
                color = DebuffTypeColor[dispelType];
            else
                color = DebuffTypeColor["none"];
            end
            btn:SetBackdropColor(color.r,color.g,color.b)
        btn.bar:SetMinMaxValues(0, duration)
        btn.duration = duration
        btn.count:SetText(count)
        if count > 1 then btn.count:Show() else btn.count:Hide() end
        btn.expires = expires
        btn.OnUpdateCounter = 1
        btn:Show()
    end
    if gusbDB.consolidate then
        cons_btn.count:SetText(cons_num)
        if cons_num > 0 then cons_btn:Show() else cons_btn:Hide() end
        if cons_frame:IsShown() then cons_frame:ResizeFrame() end
    end
    guSB:ArrangeIcons()
end

function guSB.UpdateLayoutSettings(self)
    arset.gxdir = (gusbDB.growthx == "LEFT" and -1 or 1)
    arset.gydir = (gusbDB.growthy == "BOTTOM" and -1 or 1)
    arset.stepx = (gusbDB.orientation == "HORIZONTAL" and 1 or 0) * arset.gxdir * gusbDB.gap
    arset.stepy = (gusbDB.orientation == "VERTICAL" and 1 or 0) * arset.gydir * gusbDB.gap
    arset.point = Flip(gusbDB.growthy..gusbDB.growthx, true, true)
    arset.to = Flip(arset.point,(arset.stepx ~= 0),(arset.stepy ~= 0))
    arset.newrowto = Flip(arset.point,(arset.stepy ~= 0),(arset.stepx ~= 0))
    arset.max = gusbDB.maxlength

        for _, icons in pairs(auras) do
            for id,btn in pairs(icons) do
                btn:SetWidth(gusbDB.width)
                btn:SetHeight(gusbDB.height)
                btn.icon:SetWidth(gusbDB.height)
                btn.icon:SetHeight(gusbDB.height)
                btn.bar:SetWidth(gusbDB.width - gusbDB.height - 2)
                btn.bar:SetHeight(gusbDB.height)
                btn:ClearAllPoints()
            end
        end
end

function guSB.ArrangeIcons(self)
    local prev, prevcol
    local placed = 1
    local gxdir = arset.gxdir
    local gydir = arset.gydir
    local stepx = arset.stepx
    local stepy = arset.stepy
    local point = arset.point
    local to = arset.to
    local newrowto = arset.newrowto
    local max = arset.max
    for _, icons in ipairs(auras) do
        if icons == debuffs then
            prev = debuffs_anchor
            placed = 1
        elseif icons == consolidated then
            prev = cons_frame
            max = 3
            placed = 1
        elseif not prev then
            prev = buffs_anchor
        end
        for id,btn in pairs(icons) do

            local btn = icons[id]
            if not btn:IsShown() then break end
            if icons ~= buffs or not consolidated[id] then
            if placed > 1 and select(2,math.modf((placed-1)/max)) == 0 then
                btn:SetPoint(point,prevcol,newrowto, math.abs(stepy)*gxdir, math.abs(stepx)*gydir )
                prevcol = btn
            else
                if placed == 1 then prevcol = btn end
                btn:SetPoint(point,prev,to, stepx, stepy)
            end
            if placed == 1 and icons == consolidated then   
                btn:SetPoint(arset.point,cons_frame,arset.point,0,0)
            end
            placed = placed + 1
            prev = btn
            end
        end
    end
end

local function AuraOnUpdate(self,time)
        self.OnUpdateCounter = (self.OnUpdateCounter or 0) + time
        if self.OnUpdateCounter < 0.2 then return end
        self.OnUpdateCounter = 0
        local left = self.expires - GetTime()
        self.bar:SetValue(left)
        local r,g,b
        local duration = self.duration

        if duration == 0 and self.expires == 0 then
            r,g,b = 1,0.5,0.9
            self.bar:SetValue(1)
        else
            if left > duration / 2 then
                r,g,b = (duration - left)*2/duration, 1, 0
            else
                r,g,b = 1, left*2/duration, 0
            end
        end
        self.bar:SetStatusBarColor(r,g,b)
        self.bar.bg:SetVertexColor(r/2,g/2,b/2)
end

function guSB.CreateBuffIcon(self, auratype)
    local backdrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 0,
        insets = {left = -2, right = -2, top = -2, bottom = -2},
    }
    local f = CreateFrame("Button",nil,UIParent)
    local width = gusbDB.width
    local height = gusbDB.height
    f:SetWidth(width)
    f:SetHeight(height)
    f:SetBackdrop(backdrop)
    f:SetBackdropColor(0, 0, 0, 0.7)

    f.icon = f:CreateTexture(nil,"ARTWORK")
    f.icon:SetTexCoord(.07, .93, .07, .93)
    f.icon:SetWidth(height)
    f.icon:SetHeight(height)
    f.icon:SetPoint("TOP", 0, 0)
    f.icon:SetPoint("RIGHT", 0, 0)
    
    f.count  =  f:CreateFontString(nil, "OVERLAY")
    f.count:SetFont("Fonts\\FRIZQT__.TTF",13,"OUTLINE")
    f.count:SetJustifyH("RIGHT")
    f.count:SetVertexColor(1,1,1)
    f.count:SetPoint("BOTTOMRIGHT",f.icon,"BOTTOMRIGHT",0,0)
    f.count:Hide()
    
    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetStatusBarTexture[[Interface\AddOns\guSmallBuffs\white.tga]]
    bar:SetWidth(width - height - 2)
    bar:SetHeight(height)
    bar:SetOrientation("VERTICAL")
    bar:SetMinMaxValues(0,100)
    bar:SetValue(50)
    bar:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
    bar:SetStatusBarColor(1,0,0)
    f.bar = bar
    
    local bbg =  bar:CreateTexture(nil,"BACKGROUND")
    bbg:SetTexture[[Interface\AddOns\guSmallBuffs\white.tga]]
    bbg:SetAllPoints(bar)  
    bbg:SetVertexColor(0.4,0,0)
    f.bar.bg = bbg
    
    f:EnableMouse(true)
    if auratype ~= "debuff" then
        f:RegisterForClicks("RightButtonUp")
        f:SetScript("OnClick",function(self,button)
            CancelUnitBuff("player", self.id, self.filter)
        end)
    end
    
    f.filter = (auratype == "buff") and "HELPFUL" or "HARMFUL"
    f:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetUnitAura("player", self.id, self.filter)
    end)
    f:SetScript("OnLeave",function(self)
        GameTooltip:Hide()
    end)
    
    f:SetScript("OnUpdate",AuraOnUpdate)
    
    f:Show()
    
    return f
end

function guSB.CreateAnchor(self,tbl)
    local f = CreateFrame("Button",nil,UIParent)
    local width = gusbDB.width
    local height = gusbDB.height
    f:SetWidth(width)
    f:SetHeight(height)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 0,
        insets = {left = -2, right = -2, top = -2, bottom = -2},
    })
    f:SetBackdropColor(0, 1, 0, 1)
    
    f:RegisterForDrag("LeftButton")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(2)
    f:SetScript("OnDragStart",function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing();
        _,_, gusbDB[tbl.."_point"], gusbDB[tbl.."_x"], gusbDB[tbl.."_y"] = self:GetPoint(1)
    end)

    f.SetPos = function(self,point, x, y )
        gusbDB[tbl.."_point"] = point
        gusbDB[tbl.."_x"] = x
        gusbDB[tbl.."_y"] = y
        self:ClearAllPoints()
        self:SetPoint(point, UIParent, point, x, y) 
    end
    f:SetPos(gusbDB[tbl.."_point"], gusbDB[tbl.."_x"], gusbDB[tbl.."_y"])
    
    f:Hide()
    
    return f
end

function guSB.MakeConsolidatedFrame(self, cbtn)
    local f = CreateFrame("Frame",nil,UIParent)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 0,
        insets = {left = -5, right = -5, top = -5, bottom = -5},
    })
    f:SetBackdropColor(0, 0, 0, 0.85)
    f:SetFrameLevel(5)
    f:SetPoint(arset.point,cbtn,Flip(arset.point, (arset.stepx == 0), (arset.stepy == 0)),0,0)
    f:SetWidth(1)
    f:SetHeight(1)
    f.ResizeFrame = function(self)
        local num = 0
        local button = select(2,next(consolidated))
        if not button then return end
        for id, btn in pairs(consolidated) do
            num = num + 1
        end
        local i,f = math.modf(num/3)
        local hr = i + (f > 0 and 1 or 0)
        local wr = i > 0 and 3 or num
        local hf = (arset.stepx == 0) and "SetWidth" or "SetHeight"
        local wf = (arset.stepx == 0) and "SetHeight" or "SetWidth"
        local ghf = hf == "SetWidth" and "GetWidth" or "GetHeight"
        local gwf = wf == "SetWidth" and "GetWidth" or "GetHeight"
        self[hf](self,hr*button[ghf](button) + (hr-1)*gusbDB.gap)
        self[wf](self,wr*button[gwf](button) + (wr-1)*gusbDB.gap)
        --pizdec kakaya huinya
    end
    f:SetScript("OnShow", f.ResizeFrame)
    f.fadeOnUpdate = function(self,time)
        self.timeElapsed = (self.timeElapsed or 0) + time
        if self.timeElapsed > 3 then
            self:Hide()
            self:SetScript("OnUpdate",nil)
            self.timeElapsed = 0
        end
    end
    f:Hide()
    return f
end
function guSB.MakeConsButton(self)
    local btn = self:CreateBuffIcon("debuff")
    btn.icon:SetTexture("Interface\\Buttons\\BuffConsolidation")
    btn.icon:SetTexCoord(0.15, 0.35, 0.3, 0.7)
    btn:SetScript("OnUpdate",nil)
    btn:SetScript("OnEnter",function () cons_frame:Show(); end)
    btn:SetScript("OnLeave",function () cons_frame:SetScript("OnUpdate",cons_frame.fadeOnUpdate) end)
    btn.bar:SetStatusBarColor(1,0.5,0.5)
    btn.bar:SetValue(100)
    btn.count:Show()
    btn:Show()
    
    return btn
end

function guSB.MutateToWeaponEnchant(f, id)
    f.id = id
    f:SetBackdropColor(0.5,0.2,0.85,1)
    f:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
            GameTooltip:SetInventoryItem("player", self.id)
        end)
    f:SetScript("OnClick",function(self)
                CancelItemTempEnchantment(self.id - 15);   -- should be 1 for mh
                guSB:CheckWeaponEnchants()
        end)
    f.duration = 3600
    f.bar:SetMinMaxValues(0,f.duration)
    f:Hide()
    
    return f
end

function guSB.CheckWeaponEnchants(self)
    local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo();
    if ( hasOffHandEnchant ) then
		if not wench[2] then
            local btn = guSB:CreateBuffIcon("weapon")
            guSB.MutateToWeaponEnchant(btn, 17)
            wench[2] = btn
        end
        wench[2].icon:SetTexture(GetInventoryItemTexture("player", 17))
        wench[2].expires = offHandExpiration/1000+GetTime()
        if not wench[2]:IsShown()then
            wench[2]:Show()
            guSB:ArrangeIcons()
        end
    else
        if wench[2] then if wench[2]:IsShown() then wench[2]:Hide() guSB:ArrangeIcons() end end
	end
    if ( hasMainHandEnchant ) then
		if not wench[1] then
            local btn = guSB:CreateBuffIcon("weapon")
            guSB.MutateToWeaponEnchant(btn, 16)
            wench[1] = btn
        end
        wench[1].icon:SetTexture(GetInventoryItemTexture("player", 16))
        wench[1].expires = mainHandExpiration/1000+GetTime()
        if not wench[1]:IsShown()then
            wench[1]:Show()
            guSB:ArrangeIcons()
        end
    else
        if wench[1] then if wench[1]:IsShown() then wench[1]:Hide() guSB:ArrangeIcons() end end
	end
end

CreateFrame("Frame",nil):SetScript("OnUpdate",function(self,time)
    self.OnUpdateCounter = (self.OnUpdateCounter or 1) + time
    if self.OnUpdateCounter < 1 then return end
    self.OnUpdateCounter = 0
    
    guSB:CheckWeaponEnchants()
end)



local ParseOpts = function(str)
    local fields = {}
    for opt,args in string.gmatch(str,"(%w*)%s*=%s*([%w%,%-%_%.%:%\\%']+)") do
        fields[opt:lower()] = tonumber(args) or string.upper(args)
    end
    return fields
end
function guSB.SlashCmd(msg)
    k,v = string.match(msg, "([%w%+%-%=]+) ?(.*)")
    if not k or k == "help" then print([[Usage:
      |cffff99bb/gusb set|r width=26 height=20 growthx=left/right growthy=top/bottom maxlength=16 gap=5 orientation=vertical/horizontal
      |cffff99bb/gusb opts|r : display current settings
      |cffff99bb/gusb hideblizz|r
      |cffff99bb/gusb consolidate|r
      |cffff99bb/gusb lock|r
      |cffff99bb/gusb unlock|r ]]
    )end
    if k == "opts" then
        print ("Width: "..gusbDB.width)
        print ("Height: "..gusbDB.height)
        print ("Growth-X: "..gusbDB.growthx)
        print ("Growth-Y: "..gusbDB.growthy)
        print ("Orientation: "..gusbDB.orientation)
        print ("Max length: "..gusbDB.maxlength)
        print ("Gap: "..gusbDB.gap)
        print ("Hide Blizzard frames: "..(gusbDB.hideblizzard and "true" or "false"))
        print ("Consolidate Buffs: "..(gusbDB.consolidate and "true" or "false"))
    end
    if k == "set" then
        local p = ParseOpts(v)
        gusbDB.width = p["width"] or gusbDB.width
        gusbDB.height = p["height"] or gusbDB.height
        gusbDB.growthx = p["growthx"] or gusbDB.growthx
        gusbDB.growthy = p["growthy"] or gusbDB.growthy
        gusbDB.orientation = p["orientation"] or gusbDB.orientation
        gusbDB.maxlength = p["maxlength"] or gusbDB.maxlength
        gusbDB.gap = p["gap"] or gusbDB.gap
        guSB:UpdateLayoutSettings()
        guSB:ArrangeIcons()
    end
    if k == "hideblizz" then
        gusbDB.hideblizzard = not gusbDB.hideblizzard
        print('Changes will take effect after reloadui')
    end
    if k == "consolidate" then
        gusbDB.consolidate = not gusbDB.consolidate
        print("Consolidated Buffs "..(gusbDB.consolidate and "enabled" or "disabled"))
        print('Changes will take effect after reloadui')
    end
    if k == "unlock" then
        buffs_anchor:Show()
        debuffs_anchor:Show()
    end
    if k == "lock" then
        buffs_anchor:Hide()
        debuffs_anchor:Hide()
    end
end
Eon = CreateFrame("Frame","Eon")
Eon:SetScript("OnEvent", function(self, event, ...)
	self[event](self, event, ...)
end)
Eon:RegisterEvent("ADDON_LOADED")



--[[
separateOwn = [NUMBER] -- indicate whether buffs you cast yourself should be separated before (1) or after (-1) others. If 0 or nil, no separation is done.
sortMethod = ["INDEX", "NAME", "TIME"] -- defines how the group is sorted (Default: "INDEX")
sortDir = ["+", "-"] -- defines the sort order (Default: "+")
groupBy = [nil, auraFilter] -- if present, a series of comma-separated filters, appended to the base filter to separate auras into groups within a single stream
consolidateTo = [nil, NUMBER] -- The aura sub-stream before which to place a proxy for the consolidated header. If nil or 0, consolidation is ignored.
consolidateDuration = [nil, NUMBER] -- the minimum total duration an aura should have to be considered for consolidation (Default: 30)
consolidateThreshold = [nil, NUMBER] -- buffs with less remaining duration than this many seconds should not be consolidated (Default: 10)
consolidateFraction = [nil, NUMBER] -- The fraction of remaining duration a buff should still have to be eligible for consolidation (Default: .10)

point = [STRING] -- a valid XML anchoring point (Default: "TOPRIGHT")
xOffset = [NUMBER] -- the x-Offset to use when anchoring the unit buttons. This should typically be set to at least the width of your buff template.
yOffset = [NUMBER] -- the y-Offset to use when anchoring the unit buttons. This should typically be set to at least the height of your buff template.
wrapAfter = [NUMBER] -- begin a new row or column after this many auras
wrapXOffset = [NUMBER] -- the x-offset from one row or column to the next
wrapYOffset = [NUMBER] -- the y-offset from one row or column to the next
maxWraps = [NUMBER] -- limit the number of rows or columns
]]

local headers = {
    ["player|HELPFUL"] = {
        initialPoint = "TOPRIGHT",
        sortMethod = "INDEX",
        xOffset = -40,
        yOffset = 0,
        wrapAfter = 16,
        wrapXOffset = 0,
        wrapYOffset = -34,
        width = 33,
        height = 28,
        consolidate = true,
        weapons = true,
    },
    ["player|HARMFUL"] = { 
        initialPoint = "TOPRIGHT",
        sortMethod = "INDEX",
        xOffset = -50,
        yOffset = 0,
        wrapAfter = 5,
        wrapXOffset = 0,
        wrapYOffset = -40,
        width = 40,
        height = 32,
    }
}





local anchors = {}

local defaults = {

    ["player|HELPFUL"] = { 
        point = "TOPRIGHT",
        x = -155,
        y = -8,
    },
    ["player|HARMFUL"] = { 
        point = "TOPRIGHT",
        x = -133,
        y = -138,
    },
    
    hideblizzard = true,
}

local nextaura = function(hdr, i )
    i = i + 1;
	local child = hdr:GetAttribute("child" .. i);
	if child and child:IsShown() then
		return i, child , child:GetAttribute("index");
	end
end
local auras = function(hdr) return nextaura, hdr, 0 end
function EonButton_OnLoad(self)
    self:SetBackdropColor(0,0,0,0.8);
    local hdr = self:GetParent()
    if hdr.parentHeader then hdr = hdr.parentHeader end
    self.unit = hdr:GetAttribute("unit")
    self.filter = hdr:GetAttribute("filter")
    self.btnWidth = hdr:GetAttribute("btnWidth")
    self.btnHeight = hdr:GetAttribute("btnHeight")
    EonButton_ChangeSize(self)
end
function EonButton_OnUpdate(self,time)
        self.OnUpdateCounter = (self.OnUpdateCounter or 0) + time
        if self.OnUpdateCounter < 0.2 then return end
        self.OnUpdateCounter = 0
        
        if not self.expires then return end
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
function EonButton_Update(self)
    local index = self:GetAttribute("index")
    if not index then return end
    
    local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura(self.unit,index,self.filter)
    if not name then return end
    self.icon:SetTexture(icon)
    self.bar:SetMinMaxValues(0, duration)
    self.count:SetText(count)
    if count > 1 then self.count:Show() else self.count:Hide() end
    self.duration = duration
    self.expires = expires
    if self.debuff then
        local color
        if dispelType then color = DebuffTypeColor[dispelType];
        else color = DebuffTypeColor["none"]; end
        self:SetBackdropColor(color.r,color.g,color.b)
    end

    self.OnUpdateCounter = 1
end
function EonWeaponButton_Update(self)
    local slot = self:GetAttribute("target-slot")
    if not slot then return end
    local _, mainHandExpiration, _, _, offHandExpiration, _ = GetWeaponEnchantInfo()
    local expirationTime = (slot == 16) and mainHandExpiration or offHandExpiration
    self.icon:SetTexture(GetInventoryItemTexture("player", slot))
    self.expires = expirationTime/1000+GetTime()
    self.duration = 3600
    self.bar:SetMinMaxValues(0, self.duration)
end
function EonButton_ChangeSize(self)
    local w = self.btnWidth or self:GetWidth()
    local h = self.btnHeight or self:GetHeight()
    self:SetWidth(w)
    self:SetHeight(h)
    self.icon:SetWidth(h)
    self.icon:SetHeight(h)
    self.bar:SetWidth(w-h-2)
    self.bar:SetHeight(h)
end
function Eon.CreateHeader(self,unit,filter,opts)
    local hdr = CreateFrame("Frame","EonBuffsHeader",UIParent,"SecureAuraHeaderTemplate")
    hdr:SetAttribute("unit",unit)
    hdr:SetAttribute("filter",filter)
    hdr:SetAttribute("template","EonTemplate")
    hdr:SetAttribute("sortMethod",opts.sortMethod or "INDEX")
    hdr:SetAttribute("point",opts.initialPoint or "TOPRIGHT")
    hdr:SetAttribute("xOffset", opts.xOffset or -40);
    hdr:SetAttribute("yOffset", opts.yOffset or 0);
    hdr:SetAttribute("minWidth",10)
    hdr:SetAttribute("minHeight",10)
    hdr:SetAttribute("groupBy",opts.groupBy)
    hdr:SetAttribute("sortDir",opts.sortDir)
    hdr:SetAttribute("wrapAfter",opts.wrapAfter or 12)
    hdr:SetAttribute("separateOwn",opts.separateOwn)
    hdr:SetAttribute("wrapXOffset",opts.wrapXOffset or 0)
    hdr:SetAttribute("wrapYOffset",opts.wrapYOffset or -36)
    hdr:SetAttribute("btnWidth",opts.width)
    hdr:SetAttribute("btnHeight",opts.height)
    
    
    if opts.weapons then
    hdr:SetAttribute("includeWeapons",1)
    hdr:SetAttribute("weaponTemplate","EonWeaponTemplate")
    end

    
    if opts.consolidate then
    local chdr = CreateFrame("Frame","consHeader",hdr,"SecureAuraHeaderTemplate")
    chdr.parentHeader = hdr
    chdr:SetFrameLevel(5)
    chdr:SetAttribute("filter",filter)
    chdr:SetAttribute("template","EonTemplate")
    chdr:SetAttribute("sortMethod",opts.sortMethod or "INDEX")
    chdr:SetAttribute("point",opts.initialPoint or "TOPRIGHT")
    chdr:SetAttribute("xOffset", opts.xOffset or -40);
    chdr:SetAttribute("yOffset", opts.yOffset or 0);
    chdr:SetAttribute("minWidth",10)
    chdr:SetAttribute("minHeight",10)
    chdr:SetAttribute("wrapAfter",opts.wrapAfter and opts.wrapAfter*.5 or 6)
    chdr:SetAttribute("wrapXOffset",opts.wrapXOffset or 0)
    chdr:SetAttribute("wrapYOffset",opts.wrapYOffset or -36)
    --chdr:Show()
    
    local proxy = CreateFrame("Button","EonConsolidateButton",hdr,"EonConsolidateProxy")
    proxy.consolidateHeader = chdr
    
    local backdrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 0,
        insets = {left = -7, right = -7, top = -7, bottom = -7},
    }
    chdr:SetBackdrop(backdrop)
    chdr:SetBackdropColor(0,0,0,0.8)
    chdr:SetPoint("TOPRIGHT",proxy,"BOTTOMRIGHT",0,-9)
    
    hdr:SetAttribute("consolidateDuration",300)
    hdr:SetAttribute("consolidateTreshold",60)
    --hdr:SetAttribute("consolidateFraction",.10)
    
    hdr:SetAttribute("consolidateTo",1)
    hdr:SetAttribute("consolidateProxy",proxy)
    hdr:SetAttribute("consolidateHeader",chdr)
    end
    
    --hdr:SetPoint("CENTER",UIParent,"CENTER",0,0)
    hdr:Show()
    
    self.headers[unit] = self.headers[unit] or {}
    self.headers[unit][filter] = hdr
    
    table.insert(anchors,self:CreateAnchor(hdr,unit.."|"..filter))
end

function Eon.ADDON_LOADED(self,event,arg1)
    if arg1 ~= "Eon" then return end
    EonDB = EonDB or {}
    EonDB = setmetatable(EonDB,{ __index = function(t,k) return defaults[k] end})
    Eon.headers = {}
    Eon.anchors = anchors
    
    for name,opts in pairs(headers) do
        local unit, filter = name:match("(.-)|(.+)")
        if unit then Eon:CreateHeader(unit,filter,opts) end
    end
    
    if EonDB.hideblizzard then
        BuffFrame:UnregisterEvent("UNIT_AURA")
        BuffFrame:Hide()
        ConsolidatedBuffs.Show = ConsolidatedBuffs.Hide
        ConsolidatedBuffs:Hide()
        TemporaryEnchantFrame:Hide()
    end
    
    SLASH_EON1= "/eon"
    SlashCmdList["EON"] = Eon.SlashCmd
end

function Eon.CreateAnchor(self,hdr,tbl)
    local f = CreateFrame("Frame",nil,UIParent)
    f:SetHeight(20)
    f:SetWidth(20)

    local t = f:CreateTexture(nil,"BACKGROUND")
    t:SetTexture("Interface\\Buttons\\UI-RadioButton")
    t:SetTexCoord(0,0.25,0,1)
    t:SetAllPoints(f)
    
    t = f:CreateTexture(nil,"BACKGROUND")
    t:SetTexture("Interface\\Buttons\\UI-RadioButton")
    t:SetTexCoord(0.25,0.49,0,1)
    t:SetVertexColor(1, 0, 0)
    t:SetAllPoints(f)

    f:RegisterForDrag("LeftButton")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(2)
    f:SetScript("OnDragStart",function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing();
        EonDB[tbl] = {}
        _,_, EonDB[tbl].point, EonDB[tbl].x, EonDB[tbl].y = self:GetPoint(1)
    end)

    f:SetPoint(EonDB[tbl].point, UIParent, EonDB[tbl].point, EonDB[tbl].x, EonDB[tbl].y) 
    
    hdr:SetPoint("TOPRIGHT",f,"BOTTOMRIGHT",0,-6)
    
    f:Hide()
    
    return f
end

local ParseOpts = function(str)
    local fields = {}
    for opt,args in string.gmatch(str,"(%w*)%s*=%s*([%w%,%-%_%.%|%:%\\%']+)") do
        fields[opt:lower()] = tonumber(args) or string.upper(args)
    end
    return fields
end
function Eon.SlashCmd(msg)
    k,v = string.match(msg, "([%w%+%-%=]+) ?(.*)")
    if not k or k == "help" then print([[Usage:
      |cffff99bb/eon hideblizz|r
      |cffff99bb/eon lock|r
      |cffff99bb/eon unlock|r ]]
    )end
    if k == "hideblizz" then
        EonDB.hideblizzard = not EonDB.hideblizzard
        print('Changes will take effect after reloadui')
    end
    if k == "unlock" then
        for _, anchor in pairs(anchors) do
            anchor:Show()
        end
    end
    if k == "lock" then
        for _, anchor in pairs(anchors) do
            anchor:Hide()
        end
    end
end
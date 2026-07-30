if _G._PhazeLoaded then
    pcall(function() if _G._Funcs and _G._Funcs.Unload then _G._Funcs.Unload() end end)
    pcall(function() if _G._PhazeScreenGui then _G._PhazeScreenGui:Destroy() end end)
end
_G._PhazeLoaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local AntiCheatDetection = {Enabled=false,DetectedScripts={},DetectedRemotes={},SuspiciousPatterns={},ProtectionLevel="Medium"}
local AntiCheatBypass = {AntiKick=false,AntiTeleportDetection=false,AntiSpeedDetection=false,SpoofWalkSpeed=false,SpoofJumpPower=false,HideFromAdmins=false,SpoofMonetization=false,GodMode=false,AntiRubberband=false,AntiAFK=false,AutoRescan=false}
local ESP = {Enabled=false,ShowName=true,ShowHealth=true,ShowDistance=true,ShowBoxes=false,ShowTracers=false,ShowSkeleton=false,WallCheck=false,TeamCheck=false,HighlightColor=Color3.fromRGB(255,255,255),SkeletonColor=Color3.fromRGB(255,255,255),VisibleColor=Color3.fromRGB(50,255,50),FillTransparency=1,OutlineTransparency=0,MaxDistance=1000,TracerThickness=2,TracerColor=Color3.fromRGB(255,255,255),TracerTransparency=0.5,TracerOrigin="Bottom"}
local Aimbot = {Enabled=false,TeamCheck=false,VisibilityCheck=true,FOV=100,ShowFOV=true,FOVColor=Color3.fromRGB(255,255,255),Smoothness=0.2,AimPart="Head",TriggerBot=false,Prediction=0}
local MagicBullet = {SilentAim=false,BulletTP=false,CurveBullet=false,AimPart="Head"}
local HitboxExpander = {Enabled=false,Size=10,Transparency=0.5,CanCollide=false}
local NoClip = {Enabled=false}
local Fly = {Enabled=false,Speed=50,Smoothness=0.1}
local CustomSpeed = {Enabled=false,Speed=16}
local KillAura = {Enabled=false,Range=15,Delay=0.1}
local OneHitKill = {Enabled=false,Connection=nil}
local Fling = {Enabled=false,TargetPlayer=nil,Power=750}
local ServerTroll = {ChatSpam=false,ChatMessage="Phaze",SpamDelay=1,RemoteSpam=false,ToolSpam=false}
local CurrentAnimation = nil
local FoundFunctions = {}
local FESounds = {Volume=0.5,PlaybackSpeed=1}
local ESPObjects = {}
local NoclipConnection,FlyConnection,FlyBodyVelocity,FlyBodyGyro = nil,nil,nil,nil
local CustomSpeedConn = nil
local KillAuraConnection,AimbotConnection,FOVCircle,HitboxConnection = nil,nil,nil,nil
local ChatSpamConnection,RemoteSpamConnection,ToolSpamConnection = nil,nil,nil
local CurrentSound,GodModeConnection,BringLoopConnection = nil,nil,nil
local AntiRubberbandConn = nil
local _lastValidPos = nil
local _playerTeleporting = false
local AntiCheatPatterns = {
    ScriptNames={"anticheat","anti-cheat","anticheats","ac","antihack","antihacker","antiexploit","security","detect","kick","ban","banwave","protection","guard","shield","defender","watch","monitor","scanner","checker"},
    RemoteNames={"kick","ban","flag","anticheat","suspicious","bac","cheatdetect","violation","penalty"},
    LocalScriptPatterns={"speed","fly","noclip","teleport","aimbot","esp","wallhack","godmode","infinite"}
}
local AntiDetect = {Enabled=false}

local function ScanForAntiCheat()
    AntiCheatDetection.DetectedScripts={}; AntiCheatDetection.DetectedRemotes={}; local sc=0
    local yieldCounter = 0
    for _,loc in pairs({ReplicatedStorage,Workspace,game:GetService("ServerScriptService"),game:GetService("StarterPlayer"),game:GetService("StarterGui"),LocalPlayer.PlayerScripts,LocalPlayer.PlayerGui}) do
        pcall(function() for _,obj in pairs(loc:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then local sn=obj.Name:lower(); for _,p in pairs(AntiCheatPatterns.ScriptNames) do if sn:find(p) then table.insert(AntiCheatDetection.DetectedScripts,{Name=obj.Name,ClassName=obj.ClassName,Path=obj:GetFullName(),Parent=obj.Parent.Name,Pattern=p}); sc=sc+1 end end end
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then local rn=obj.Name:lower(); for _,p in pairs(AntiCheatPatterns.RemoteNames) do if rn:find(p) then table.insert(AntiCheatDetection.DetectedRemotes,{Name=obj.Name,ClassName=obj.ClassName,Path=obj:GetFullName(),Parent=obj.Parent.Name,Pattern=p,Obj=obj}); sc=sc+1 end end end
            yieldCounter = yieldCounter + 1
            if yieldCounter % 150 == 0 then task.wait() end
        end end)
    end; return sc
end
local function GetProtectionDetails()
    local d={TotalScripts=#AntiCheatDetection.DetectedScripts,TotalRemotes=#AntiCheatDetection.DetectedRemotes,RiskLevel="Unknown",Recommendations={}}
    local t=d.TotalScripts+d.TotalRemotes
    if t==0 then d.RiskLevel="None/Low" elseif t<=3 then d.RiskLevel="Low" elseif t<=7 then d.RiskLevel="Medium" else d.RiskLevel="High" end
    return d
end
local MarketplaceService=game:GetService("MarketplaceService"); local IsBypassInitialized=false
local _BypassError = nil

local _safeGetgenv = function() local ok,v=pcall(getgenv); if ok then return v end; return nil end
local _safeGetrenv = function() local ok,v=pcall(getrenv); if ok then return v end; return nil end
local _safeGetfenv = function(n) local ok,v=pcall(getfenv,n); if ok then return v end; return nil end
local function _getFunc(name)
    local f = nil

    local g = _safeGetgenv(); if g then pcall(function() f = g[name] end); if f then return f end end

    pcall(function() f = _G[name] end); if f then return f end

    local fe = _safeGetfenv(); if fe then pcall(function() f = fe[name] end); if f then return f end end
    local fe0 = _safeGetfenv(0); if fe0 then pcall(function() f = fe0[name] end); if f then return f end end

    local re = _safeGetrenv(); if re then pcall(function() f = re[name] end); if f then return f end end

    local syn = _G.syn or (g and g.syn); if syn and syn[name] then return syn[name] end

    pcall(function() local ls = loadstring("return "..name); if ls then f = ls() end end)
    return f
end

local _getrawmetatable = _getFunc("getrawmetatable") or _getFunc("debug_getmetatable")
local _setreadonly = _getFunc("setreadonly") or _getFunc("make_writeable") or _getFunc("setwriteable")
local _newcclosure = _getFunc("newcclosure") or function(f) return f end
local _checkcaller = _getFunc("checkcaller") or function() return false end
local _getnamecallmethod = _getFunc("getnamecallmethod") or _getFunc("get_namecall_method")
local _hookmetamethod = _getFunc("hookmetamethod") or _getFunc("hook_metamethod") or _getFunc("hookMetamethod")
local _hookfunction = _getFunc("hookfunction") or _getFunc("hook_function") or _getFunc("replaceclosure") or _getFunc("replace_closure") or _getFunc("detour_function")

if not _hookfunction then
    _hookfunction = function(orig, newFn)

        return orig
    end
end

pcall(function()
    print("[Phaze] Executor capabilities:")
    print("  hookmetamethod (final):", _hookmetamethod ~= nil)
    print("  hookfunction (final):", _hookfunction ~= nil)
    print("  getrawmetatable (manual hook source):", _getrawmetatable ~= nil)
    print("  setreadonly:", _setreadonly ~= nil)
    print("  newcclosure:", _getFunc("newcclosure") ~= nil)
    print("  checkcaller:", _getFunc("checkcaller") ~= nil)
    print("  getnamecallmethod:", _getFunc("getnamecallmethod") ~= nil)
    print("  getrawmetatable:", _getFunc("getrawmetatable") ~= nil)
    print("  writefile:", _getFunc("writefile") ~= nil)
    print("  getgenv available:", pcall(getgenv))
end)

local _cachedGamepasses = {}
local function FireGamepassRemotes(gamePassId)
    pcall(function()
        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                local rn = remote.Name:lower()
                if rn:find("gamepass") or rn:find("purchase") or rn:find("bought") or rn:find("owned") or rn:find("product") or rn:find("verify") then
                    pcall(function() remote:FireServer(gamePassId, true) end)
                    pcall(function() remote:FireServer(LocalPlayer.UserId, gamePassId, true) end)
                end
            end
        end
    end)
end

local _bypassQueue = {}
local _bypassRunning = false

local function QueueHook(name, fn)
    table.insert(_bypassQueue, {name=name, fn=fn})
end

local function RunBypassQueue(onDone)
    if _bypassRunning then return end
    _bypassRunning = true
    task.spawn(function()
        task.wait(0.2)
        for i, hook in ipairs(_bypassQueue) do
            local ok, err = pcall(hook.fn)
            if not ok then
                _BypassError = hook.name..": "..tostring(err)
            end
            task.wait(0.1)
        end
        _bypassQueue = {}
        _bypassRunning = false
        if onDone then onDone() end
    end)
end

local _liteBypassDone = false
local _fullBypassDone = false

local function SetupLiteBypass()
    if _liteBypassDone then return end
    _liteBypassDone = true
    IsBypassInitialized = true

    if _hookfunction then
        QueueHook("kick", function()
            pcall(function() _hookfunction(LocalPlayer.Kick, _newcclosure(function() return end)) end)
        end)
        QueueHook("tp1", function()
            pcall(function()
                local currentPlaceId = game.PlaceId
                _hookfunction(TeleportService.Teleport, _newcclosure(function(self, placeId, ...)
                    if placeId ~= currentPlaceId and AntiCheatBypass.AntiKick then return nil end
                    return TeleportService.Teleport(self, placeId, ...)
                end))
            end)
        end)
    end

    QueueHook("antidle", function()
        LocalPlayer.Idled:Connect(function()
            if not AntiCheatBypass.AntiAFK then return end
            pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
        end)
    end)

    RunBypassQueue()
end

local function SetupFullBypass()
    if _fullBypassDone then return end
    if not _liteBypassDone then SetupLiteBypass() end

    task.spawn(function()
        while _bypassRunning do task.wait(0.1) end
        _fullBypassDone = true

        if _hookmetamethod then
            QueueHook("namecall", function()
                local blockedMethods = {Kick=true}
                local tpMethods = {Teleport=true,TeleportToPlaceInstance=true,TeleportPartyAsync=true,TeleportToPrivateServer=true}
                local gpOwn = {UserOwnsGamePassAsync=true,PlayerOwnsAsset=true}
                local gpPrompt = {PromptGamePassPurchase=true,PromptProductPurchase=true,PromptPurchase=true,PromptBundlePurchase=true,PromptPremiumPurchase=true}
                local currentPlaceId = game.PlaceId
                local oldNamecall
                oldNamecall = _hookmetamethod(game, "__namecall", _newcclosure(function(self, ...)
                    if _checkcaller() then return oldNamecall(self, ...) end
                    local method = getnamecallmethod and getnamecallmethod() or ""
                    if blockedMethods[method] then return nil end
                    if AntiCheatBypass.GodMode and (method == "TakeDamage" or method == "BreakJoints") then
                        local ok, cn = pcall(function() return self.ClassName end)
                        if ok and (cn == "Humanoid" or cn == "Model") then return nil end
                    end
                    if tpMethods[method] and self == TeleportService and AntiCheatBypass.AntiKick then
                        local args = {...}
                        if not args[1] or args[1] ~= currentPlaceId then return nil end
                    end
                    if self == MarketplaceService and AntiCheatBypass.SpoofMonetization then
                        if gpOwn[method] then return true end
                        if gpPrompt[method] then
                            local a = {...}; task.defer(function() FireGamepassRemotes(a[2] or a[1] or 0) end)
                            return nil
                        end
                    end
                    return oldNamecall(self, ...)
                end))
            end)

            QueueHook("index", function()
                local spoofKeys = {WalkSpeed=true,JumpPower=true,Health=true,MaxHealth=true}
                local velKeys = {Velocity=true,AssemblyLinearVelocity=true}
                local oldIndex
                oldIndex = _hookmetamethod(game, "__index", _newcclosure(function(self, key)
                    if _checkcaller() then return oldIndex(self, key) end
                    if spoofKeys[key] then
                        local ok, cn = pcall(function() return self.ClassName end)
                        if ok and cn == "Humanoid" then
                            if key == "WalkSpeed" and AntiCheatBypass.SpoofWalkSpeed then return 16 end
                            if key == "JumpPower" and AntiCheatBypass.SpoofJumpPower then return 50 end
                            if (key == "Health" or key == "MaxHealth") and AntiCheatBypass.GodMode then return 100 end
                        end
                    end
                    if velKeys[key] and AntiCheatBypass.AntiSpeedDetection then
                        local c = LocalPlayer.Character
                        if c then
                            local ok, rp = pcall(GetRootPart, c)
                            if ok and rp and self == rp then
                                local real = oldIndex(self, key)
                                if typeof(real) == "Vector3" then
                                    local flat = Vector3.new(real.X, 0, real.Z)
                                    if flat.Magnitude > 18 then
                                        return flat.Unit * 18 + Vector3.new(0, real.Y, 0)
                                    end
                                end
                                return real
                            end
                        end
                    end
                    if key == "MembershipType" and self == LocalPlayer and AntiCheatBypass.SpoofMonetization then return Enum.MembershipType.Premium end
                    return oldIndex(self, key)
                end))
            end)

            RunBypassQueue(function()
                if _BypassError then _fullBypassDone = false end
            end)
        end
    end)
end

local function SetupAdvancedBypasses()
    if IsBypassInitialized then return end
    SetupLiteBypass()
end
local function SetupAntiKick() SetupLiteBypass() end
local function SetupAntiTeleportDetection() SetupLiteBypass() end
local function SetupAntiSpeedDetection() SetupFullBypass() end

local HideAdminsConn = nil
local function SetupHideFromAdmins()
    if HideAdminsConn then HideAdminsConn:Disconnect(); HideAdminsConn = nil end
    if not AntiCheatBypass.HideFromAdmins then return end
    local function apply(c)
        pcall(function() local h=GetHumanoid(c); if h then h.DisplayName="Player" end end)
    end
    if LocalPlayer.Character then apply(LocalPlayer.Character) end
    HideAdminsConn = LocalPlayer.CharacterAdded:Connect(function(nc)
        if AntiCheatBypass.HideFromAdmins then apply(nc) end
    end)
end

local AntiDetectThread = nil
local function SetAntiDetect(e)
    AntiDetect.Enabled = e
    if AntiDetectThread then pcall(function() task.cancel(AntiDetectThread) end); AntiDetectThread = nil end
    if not e then return end
    AntiDetectThread = task.spawn(function()
        while AntiDetect.Enabled do
            pcall(function()
                if ScreenGui then
                    ScreenGui.Name = "ScreenGui"..tostring(math.random(10000,99999))
                    if not ScreenGui.Parent then
                        ScreenGui.Parent = game:GetService("CoreGui")
                        if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
                    end
                end
            end)
            task.wait(math.random(20,40))
        end
    end)
end

local _blockedRemoteCount = 0
local function BlockFlaggedRemotes()
    if not _hookfunction or not _newcclosure then
        NotifyError("Block Remotes","Executor has no hookfunction support",4)
        return
    end
    local blocked = 0
    for _, r in pairs(AntiCheatDetection.DetectedRemotes) do
        local obj = r.Obj
        if obj and obj.Parent then
            pcall(function()
                if obj:IsA("RemoteEvent") and not obj:GetAttribute("_PhazeBlocked") then
                    local oldFire = obj.FireServer
                    _hookfunction(oldFire, _newcclosure(function(self, ...)
                        if self == obj and not (_checkcaller and _checkcaller()) then return nil end
                        return oldFire(self, ...)
                    end))
                    obj:SetAttribute("_PhazeBlocked", true)
                    blocked = blocked + 1
                elseif obj:IsA("RemoteFunction") and not obj:GetAttribute("_PhazeBlocked") then
                    local oldInvoke = obj.InvokeServer
                    _hookfunction(oldInvoke, _newcclosure(function(self, ...)
                        if self == obj and not (_checkcaller and _checkcaller()) then return nil end
                        return oldInvoke(self, ...)
                    end))
                    obj:SetAttribute("_PhazeBlocked", true)
                    blocked = blocked + 1
                end
            end)
        end
    end
    _blockedRemoteCount = _blockedRemoteCount + blocked
    if blocked > 0 then
        Notify("Block Remotes","Blocked "..blocked.." flagged remote(s)",3)
    else
        Notify("Block Remotes","Nothing new to block — run Scan first",3)
    end
end

local AutoRescanConn = nil
local function SetAutoRescan(e)
    AntiCheatBypass.AutoRescan = e
    if AutoRescanConn then AutoRescanConn:Disconnect(); AutoRescanConn = nil end
    if not e then return end
    AutoRescanConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if AntiCheatBypass.AutoRescan then ScanForAntiCheat() end
    end)
end

local _arb_frameskip = 0

local GetRootPart, GetHumanoid
local Notify, NotifyError
local IsVisible
local ScreenGui, Panel, ActiveCat, ToggleRegistry, ToggleStates, SliderStates, DropdownStates, RenderCategory, AddCategory
local TeleportTo, SendChatMessage

local function SetAntiRubberband(enabled)
    if AntiRubberbandConn then AntiRubberbandConn:Disconnect(); AntiRubberbandConn = nil end
    if not enabled then _lastValidPos = nil; return end

    _lastValidPos = nil
    _arb_frameskip = 0
    AntiRubberbandConn = RunService.RenderStepped:Connect(function()
        if not AntiCheatBypass.AntiRubberband then return end
        local c = LocalPlayer.Character
        if not c then _lastValidPos = nil; return end
        local rp = GetRootPart(c)
        if not rp then _lastValidPos = nil; return end

        local currentPos = rp.CFrame

        if _playerTeleporting then
            _lastValidPos = currentPos
            _arb_frameskip = 5
            return
        end

        if _arb_frameskip > 0 then
            _arb_frameskip = _arb_frameskip - 1
            _lastValidPos = currentPos
            return
        end

        if not _lastValidPos then
            _lastValidPos = currentPos
            return
        end

        local dist = (currentPos.Position - _lastValidPos.Position).Magnitude
        local maxDist = 20
        if Fly.Enabled then maxDist = Fly.Speed * 0.5 end
        if NoClip.Enabled then maxDist = math.max(maxDist, 40) end

        if dist > maxDist then
            task.defer(function()
                if rp and rp.Parent then
                    rp.CFrame = _lastValidPos
                    pcall(function() rp.Velocity = Vector3.new(0, 0, 0) end)
                    pcall(function() rp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
                end
            end)
        else
            _lastValidPos = currentPos
        end
    end)
end

GetRootPart = function(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
        or character.PrimaryPart
        or (function() for _,p in pairs(character:GetChildren()) do if p:IsA("BasePart") then return p end end return nil end)()
end

GetHumanoid = function(character)
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
        or character:FindFirstChild("Humanoid")
end

local function GetAimPart(character, partName)
    if not character then return nil end
    local p = character:FindFirstChild(partName)
    if p then return p end
    if partName == "Head" then
        p = character:FindFirstChild("Head")
        if not p then p = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart") end
    end
    if not p then p = GetRootPart(character) end
    return p
end

local function IsAlive(character)
    if not character then return false end
    local rp = GetRootPart(character)
    if not rp then return false end
    local hum = GetHumanoid(character)
    if hum and hum.Health <= 0 then return false end
    return true
end

local SkeletonBones_R15 = {
    {"Head","UpperTorso"},
    {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},
    {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},
    {"RightUpperArm","RightLowerArm"},
    {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},
    {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},
    {"RightUpperLeg","RightLowerLeg"},
    {"RightLowerLeg","RightFoot"},
}
local SkeletonBones_R6 = {
    {"Head","Torso"},
    {"Torso","Left Arm"},
    {"Torso","Right Arm"},
    {"Torso","Left Leg"},
    {"Torso","Right Leg"},
}

local function CreateSkeletonLines()
    local lines = {}
    pcall(function()
        for i = 1, 14 do
            local l = Drawing.new("Line")
            l.Thickness = 1.5
            l.Color = ESP.SkeletonColor
            l.Transparency = 1
            l.Visible = false
            table.insert(lines, l)
        end
    end)
    return lines
end

local function UpdateSkeleton(lines, character, visible)
    if not lines or #lines == 0 then return end
    if not visible or not character then
        for _, l in pairs(lines) do pcall(function() l.Visible = false end) end
        return
    end
    local bones = character:FindFirstChild("UpperTorso") and SkeletonBones_R15 or SkeletonBones_R6
    for i, l in pairs(lines) do
        local bone = bones[i]
        if not bone then
            pcall(function() l.Visible = false end)
            continue
        end
        local p1 = character:FindFirstChild(bone[1])
        local p2 = character:FindFirstChild(bone[2])
        if p1 and p2 then
            local s1, on1 = Camera:WorldToViewportPoint(p1.Position)
            local s2, on2 = Camera:WorldToViewportPoint(p2.Position)
            if on1 and on2 then
                pcall(function()
                    l.From = Vector2.new(s1.X, s1.Y)
                    l.To = Vector2.new(s2.X, s2.Y)
                    l.Color = ESP.SkeletonColor
                    l.Visible = true
                end)
            else
                pcall(function() l.Visible = false end)
            end
        else
            pcall(function() l.Visible = false end)
        end
    end
end

local _espPlayerCounter = 0
local function CreateESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    _espPlayerCounter = _espPlayerCounter + 1
    local d = {Highlight=Instance.new("Highlight"), BillboardGui=Instance.new("BillboardGui"), TextLabel=Instance.new("TextLabel"), TracerLine=nil, SkeletonLines=nil, _wallVisible=false, _wallFrame=_espPlayerCounter % 6}
    d.Highlight.OutlineColor = ESP.HighlightColor
    d.Highlight.FillColor = ESP.HighlightColor
    d.Highlight.FillTransparency = ESP.FillTransparency
    d.Highlight.OutlineTransparency = ESP.OutlineTransparency
    d.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    d.BillboardGui.Size = UDim2.new(0,200,0,60)
    d.BillboardGui.StudsOffset = Vector3.new(0,3,0)
    d.BillboardGui.AlwaysOnTop = true
    d.TextLabel.Size = UDim2.new(1,0,1,0)
    d.TextLabel.BackgroundTransparency = 1
    d.TextLabel.TextColor3 = Color3.fromRGB(255,255,255)
    d.TextLabel.TextStrokeTransparency = 0
    d.TextLabel.Font = Enum.Font.GothamBold
    d.TextLabel.TextSize = 14
    d.TextLabel.Parent = d.BillboardGui
    pcall(function()
        local l = Drawing.new("Line")
        l.Thickness = ESP.TracerThickness
        l.Color = ESP.TracerColor
        l.Transparency = ESP.TracerTransparency
        l.Visible = false
        d.TracerLine = l
    end)
    d.SkeletonLines = CreateSkeletonLines()
    ESPObjects[player] = d
end

local function HideESPData(d)
    d.Highlight.Enabled = false
    d.BillboardGui.Enabled = false
    if d.TracerLine then d.TracerLine.Visible = false end
    UpdateSkeleton(d.SkeletonLines, nil, false)
end

local function RemoveESP(p)
    local d = ESPObjects[p]
    if not d then return end
    pcall(function() d.Highlight:Destroy() end)
    pcall(function() d.BillboardGui:Destroy() end)
    if d.TracerLine then pcall(function() d.TracerLine:Remove() end) end
    if d.SkeletonLines then for _, l in pairs(d.SkeletonLines) do pcall(function() l:Remove() end) end end
    ESPObjects[p] = nil
end

local function RefreshAllESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            RemoveESP(p)
            CreateESP(p)
        end
    end
end

local function UpdateAllTracers()
    for _, d in pairs(ESPObjects) do
        if d.TracerLine then
            if ESP.ShowTracers then
                d.TracerLine.Color = ESP.TracerColor
                d.TracerLine.Transparency = ESP.TracerTransparency
                d.TracerLine.Thickness = ESP.TracerThickness
            else
                d.TracerLine.Visible = false
            end
        end
    end
end

local _espFrame = 0
local _espConn = nil
local function StartESPLoop()
    if _espConn then return end
    _espConn = RunService.Heartbeat:Connect(function()
        _espFrame = _espFrame + 1
        if not ESP.Enabled then
            if _espFrame % 10 == 0 then
                for _, d in pairs(ESPObjects) do HideESPData(d) end
            end
            return
        end
        for player, d in pairs(ESPObjects) do
            local ch = player.Character
            if not ch or not ch.Parent then HideESPData(d); continue end
            local rp = GetRootPart(ch)
            if not rp then HideESPData(d); continue end
            local hum = GetHumanoid(ch)
            if hum and hum.Health <= 0 then HideESPData(d); continue end
            local dist = math.floor((Camera.CFrame.Position - rp.Position).Magnitude)
            if dist > ESP.MaxDistance then HideESPData(d); continue end
            if ESP.TeamCheck then
                local skip = false
                pcall(function()
                    if player.Team and LocalPlayer.Team then
                        if player.Team == LocalPlayer.Team then skip = true end
                    elseif player.TeamColor and LocalPlayer.TeamColor then
                        if player.TeamColor == LocalPlayer.TeamColor then skip = true end
                    elseif player.Neutral and LocalPlayer.Neutral then
                        skip = true
                    end
                end)
                if skip then HideESPData(d); continue end
            end
            local sp, on = Camera:WorldToViewportPoint(rp.Position)
            if not on then HideESPData(d); continue end

            local espColor = ESP.HighlightColor
            if ESP.WallCheck then
                d._wallTimer = (d._wallTimer or 6) + 1
                if d._wallTimer >= 6 then
                    d._wallTimer = 0
                    d._wallVisible = IsVisible(Camera.CFrame.Position, rp.Position, LocalPlayer.Character, ch)
                end
                espColor = d._wallVisible and ESP.VisibleColor or ESP.HighlightColor
            end

            pcall(function()
                d.Highlight.Enabled = true
                d.Highlight.OutlineColor = espColor
                d.Highlight.FillColor = ESP.ChamsColor or espColor
                d.Highlight.FillTransparency = ESP.FillTransparency
                if d.Highlight.Parent ~= ch then d.Highlight.Parent = ch end
            end)
            local headPart = ch:FindFirstChild("Head") or rp
            pcall(function()
                d.BillboardGui.Enabled = true
                if d.BillboardGui.Parent ~= headPart then d.BillboardGui.Parent = headPart end
            end)

            if _espFrame % 3 == 0 then
                local info = ""
                if ESP.ShowName then info = player.DisplayName or player.Name end
                if ESP.ShowHealth and hum then info = info..(info~="" and "\n" or "").."HP: "..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth) end
                if ESP.ShowDistance then info = info..(info~="" and "\n" or "")..dist.."m" end
                if ESP.WallCheck then info = info..(info~="" and "\n" or "")..(d._wallVisible and "[VISIBLE]" or "[WALL]") end
                d.TextLabel.Text = info
            end

            if ESP.ShowTracers and d.TracerLine then
                local fromY = ESP.TracerOrigin == "Center" and Camera.ViewportSize.Y/2 or Camera.ViewportSize.Y
                d.TracerLine.From = Vector2.new(Camera.ViewportSize.X/2, fromY)
                d.TracerLine.To = Vector2.new(sp.X, sp.Y)
                d.TracerLine.Color = espColor
                d.TracerLine.Visible = true
            elseif d.TracerLine then
                d.TracerLine.Visible = false
            end

            if _espFrame % 2 == 0 then
                UpdateSkeleton(d.SkeletonLines, ch, ESP.ShowSkeleton)
            end
        end
    end)
end
StartESPLoop()

local function CreateFOVCircle()
    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    pcall(function()
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = 2
        FOVCircle.NumSides = 60
        FOVCircle.Radius = Aimbot.FOV
        FOVCircle.Color = Aimbot.FOVColor
        FOVCircle.Transparency = 1
        FOVCircle.Filled = false
        FOVCircle.Visible = Aimbot.ShowFOV
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end)
end

local _originalRaycast = Workspace.Raycast
IsVisible = function(origin, target, ignoreChar, targetChar)
    local ok, result = pcall(function()
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local filter = {Camera}
        if ignoreChar then table.insert(filter, ignoreChar) end
        if targetChar then table.insert(filter, targetChar) end
        params.FilterDescendantsInstances = filter
        local dir = target - origin
        if dir.Magnitude < 1 then return nil end
        return _originalRaycast(Workspace, origin, dir.Unit * (dir.Magnitude - 1), params)
    end)
    if not ok then return true end
    if not result then return true end
    return false
end

local function GetClosestPlayerInFOV()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local candidates = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if Aimbot.TeamCheck then
                local skip = false
                pcall(function()
                    if p.Team and LocalPlayer.Team then
                        if p.Team == LocalPlayer.Team then skip = true end
                    elseif p.TeamColor and LocalPlayer.TeamColor then
                        if p.TeamColor == LocalPlayer.TeamColor then skip = true end
                    elseif p.Neutral and LocalPlayer.Neutral then
                        skip = true
                    end
                end)
                if skip then continue end
            end
            local ch = p.Character
            if not IsAlive(ch) then continue end
            local ap = GetAimPart(ch, Aimbot.AimPart)
            if not ap then continue end
            local sp, on = Camera:WorldToViewportPoint(ap.Position)
            if on then
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if d < Aimbot.FOV then
                    table.insert(candidates, {player=p, dist=d})
                end
            end
        end
    end
    table.sort(candidates, function(a,b) return a.dist < b.dist end)
    if not Aimbot.VisibilityCheck or #candidates == 0 then
        return candidates[1] and candidates[1].player or nil
    end
    local checked = 0
    for _, c in ipairs(candidates) do
        checked = checked + 1
        local ch = c.player.Character
        local ap = GetAimPart(ch, Aimbot.AimPart)
        if ap and IsVisible(Camera.CFrame.Position, ap.Position, LocalPlayer.Character, ch) then
            return c.player
        end
        if checked >= 5 then break end
    end
    return candidates[1] and candidates[1].player or nil
end

do
local _mousemoverel = _getFunc("mousemoverel") or _getFunc("mouse_moverel") or _getFunc("Input.MouseMove")
local _mouse1click = _getFunc("mouse1click") or _getFunc("mouse_click") or _getFunc("click")
local _mouse1press = _getFunc("mouse1press") or _getFunc("mouse_press")
local _mouse1release = _getFunc("mouse1release") or _getFunc("mouse_release")
local _vim = nil
pcall(function() _vim = game:GetService("VirtualInputManager") end)
local _triggerCooldown = 0

local function SetAimbot(e)
    if AimbotConnection then AimbotConnection:Disconnect(); AimbotConnection = nil end
    if not e then
        if FOVCircle then pcall(function() FOVCircle.Visible = false end) end
        return
    end
    CreateFOVCircle()
    AimbotConnection = RunService.RenderStepped:Connect(function()
        if not Aimbot.Enabled then return end
        if FOVCircle then
            pcall(function()
                FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                FOVCircle.Radius = Aimbot.FOV
                FOVCircle.Color = Aimbot.FOVColor
                FOVCircle.Visible = Aimbot.ShowFOV
            end)
        end
        local t = GetClosestPlayerInFOV()
        if t and t.Character then
            local ap = GetAimPart(t.Character, Aimbot.AimPart)
            if ap then
                local aimPos = ap.Position
                if Aimbot.Prediction and Aimbot.Prediction > 0 then
                    local ok, vel = pcall(function() return ap.AssemblyLinearVelocity end)
                    if ok and typeof(vel) == "Vector3" then
                        aimPos = aimPos + Vector3.new(vel.X, 0, vel.Z) * Aimbot.Prediction
                    end
                end
                if _mousemoverel then
                    local sp = Camera:WorldToViewportPoint(aimPos)
                    local cx, cy = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
                    local dx = (sp.X - cx) * Aimbot.Smoothness
                    local dy = (sp.Y - cy) * Aimbot.Smoothness
                    pcall(function() _mousemoverel(dx, dy) end)
                else
                    local targetCF = CFrame.new(Camera.CFrame.Position, aimPos)
                    Camera.CFrame = Camera.CFrame:Lerp(targetCF, Aimbot.Smoothness)
                end
                if Aimbot.TriggerBot and tick() - _triggerCooldown > 0.08 then
                    _triggerCooldown = tick()
                    local fired = false
                    local c = LocalPlayer.Character
                    if c then
                        local tl = c:FindFirstChildOfClass("Tool")
                        if tl then pcall(function() tl:Activate() end); fired = true end
                    end
                    if not fired then
                        if _mouse1click then
                            pcall(_mouse1click)
                        elseif _mouse1press and _mouse1release then
                            pcall(_mouse1press)
                            task.delay(0.03, function() pcall(_mouse1release) end)
                        elseif _vim then
                            pcall(function()
                                local cx, cy = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
                                _vim:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                            end)
                            task.delay(0.03, function()
                                pcall(function()
                                    local cx, cy = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
                                    _vim:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                                end)
                            end)
                        end
                    end
                end
            end
        end
    end) end
_G._SetAimbot = SetAimbot
end

do
local _silentAimHooked = false
local _silentAimCallCount = 0
local _oldRaycast = nil
local _bulletTPConn = nil
local _curveBulletConn = nil

local function GetMagicTarget()
    local best, bestDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and IsAlive(p.Character) then
            local skip = false
            pcall(function()
                if Aimbot.TeamCheck then
                    if p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team then skip = true
                    elseif p.TeamColor and LocalPlayer.TeamColor and p.TeamColor == LocalPlayer.TeamColor then skip = true end
                end
            end)
            if not skip then
                local ap = GetAimPart(p.Character, MagicBullet.AimPart)
                if ap then
                    local sp, on = Camera:WorldToViewportPoint(ap.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                        if d < bestDist then bestDist = d; best = ap end
                    end
                end
            end
        end
    end
    return best
end

local _silentOldNamecall = nil
local function SetSilentAim(e)
    if e and not _silentAimHooked then
        _silentAimHooked = true
        local hooked = false
        local errMsg = ""

        if _hookmetamethod and _newcclosure then
            local ok, err = pcall(function()
                local oldNc
                oldNc = _hookmetamethod(game, "__namecall", _newcclosure(function(self, ...)
                    local method = _getnamecallmethod and _getnamecallmethod() or ""
                    if (MagicBullet.SilentAim or MagicBullet.BulletTP) and self == Workspace and (method == "Raycast" or method == "raycast") then
                        if not (_checkcaller and _checkcaller()) then
                            local args = {...}
                            local origin = args[1]
                            local direction = args[2]
                            if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
                                local target = GetMagicTarget()
                                if target then
                                    local newDir = (target.Position - origin).Unit * direction.Magnitude
                                    args[2] = newDir
                                    return oldNc(self, unpack(args))
                                end
                            end
                        end
                    end
                    if self == Workspace and (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") then
                        if (MagicBullet.SilentAim or MagicBullet.BulletTP) and not (_checkcaller and _checkcaller()) then
                            local args = {...}
                            if typeof(args[1]) == "Ray" then
                                local target = GetMagicTarget()
                                if target then
                                    local ray = args[1]
                                    local newDir = (target.Position - ray.Origin).Unit * ray.Direction.Magnitude
                                    args[1] = Ray.new(ray.Origin, newDir)
                                    return oldNc(self, unpack(args))
                                end
                            end
                        end
                    end
                    return oldNc(self, ...)
                end))
                _silentOldNamecall = oldNc
                hooked = true
            end)
            if not ok then errMsg = tostring(err) end
        end

        if not hooked and _hookfunction and _newcclosure then
            local ok, err = pcall(function()
                local _oldWSRaycast = Workspace.Raycast
                _hookfunction(Workspace.Raycast, _newcclosure(function(self, origin, direction, params, ...)
                    _silentAimCallCount = (_silentAimCallCount or 0) + 1
                    if not ((MagicBullet.SilentAim or MagicBullet.BulletTP)) or (_checkcaller and _checkcaller()) then
                        return _oldWSRaycast(self, origin, direction, params, ...)
                    end
                    local target = GetMagicTarget()
                    if target then
                        local newDir = (target.Position - origin).Unit * direction.Magnitude
                        return _oldWSRaycast(self, origin, newDir, params, ...)
                    end
                    return _oldWSRaycast(self, origin, direction, params, ...)
                end))
            end)
            if ok then hooked = true else errMsg = errMsg.." | "..tostring(err) end

            pcall(function()
                local _oldFPOR = Workspace.FindPartOnRay
                _hookfunction(Workspace.FindPartOnRay, _newcclosure(function(self, ray, ...)
                    _silentAimCallCount = (_silentAimCallCount or 0) + 1
                    if not ((MagicBullet.SilentAim or MagicBullet.BulletTP)) or (_checkcaller and _checkcaller()) or typeof(ray) ~= "Ray" then
                        return _oldFPOR(self, ray, ...)
                    end
                    local target = GetMagicTarget()
                    if target then
                        local newDir = (target.Position - ray.Origin).Unit * ray.Direction.Magnitude
                        return _oldFPOR(self, Ray.new(ray.Origin, newDir), ...)
                    end
                    return _oldFPOR(self, ray, ...)
                end))
            end)
            pcall(function()
                local _oldFPORI = Workspace.FindPartOnRayWithIgnoreList
                _hookfunction(Workspace.FindPartOnRayWithIgnoreList, _newcclosure(function(self, ray, ...)
                    _silentAimCallCount = (_silentAimCallCount or 0) + 1
                    if not ((MagicBullet.SilentAim or MagicBullet.BulletTP)) or (_checkcaller and _checkcaller()) or typeof(ray) ~= "Ray" then
                        return _oldFPORI(self, ray, ...)
                    end
                    local target = GetMagicTarget()
                    if target then
                        local newDir = (target.Position - ray.Origin).Unit * ray.Direction.Magnitude
                        return _oldFPORI(self, Ray.new(ray.Origin, newDir), ...)
                    end
                    return _oldFPORI(self, ray, ...)
                end))
            end)
            pcall(function()
                local _oldFPORW = Workspace.FindPartOnRayWithWhitelist
                _hookfunction(Workspace.FindPartOnRayWithWhitelist, _newcclosure(function(self, ray, ...)
                    _silentAimCallCount = (_silentAimCallCount or 0) + 1
                    if not ((MagicBullet.SilentAim or MagicBullet.BulletTP)) or (_checkcaller and _checkcaller()) or typeof(ray) ~= "Ray" then
                        return _oldFPORW(self, ray, ...)
                    end
                    local target = GetMagicTarget()
                    if target then
                        local newDir = (target.Position - ray.Origin).Unit * ray.Direction.Magnitude
                        return _oldFPORW(self, Ray.new(ray.Origin, newDir), ...)
                    end
                    return _oldFPORW(self, ray, ...)
                end))
            end)
        end

        if hooked then
            Notify("Silent Aim", "Hooked successfully!", 3)
        else
            local diag = "hookmeta:"..(_hookmetamethod and "Y" or "N").." hookfn:"..(_hookfunction and "Y" or "N").." newcc:"..(_newcclosure and "Y" or "N")
            NotifyError("Silent Aim", diag.." err="..errMsg, 8)
            print("[Phaze SilentAim] Diagnostic:", diag, "Err:", errMsg)
            _silentAimHooked = false
        end
    end
end

local function _isLikelyOwnBullet(obj)
    local c = LocalPlayer.Character
    if not c then return false end
    if obj:FindFirstChild("creator") then return true end
    if obj.Parent == c then return true end
    local rp = GetRootPart(c)
    local dist = rp and (obj.Position - rp.Position).Magnitude or math.huge
    return dist < 40
end

local function _waitForFastVelocity(obj, callback)
    task.spawn(function()
        for i = 1, 15 do
            if not obj or not obj.Parent then return end
            local ok, mag = pcall(function() return obj.Velocity.Magnitude end)
            if ok and mag > 100 then
                callback()
                return
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

local function SetBulletTP(e)
    if _bulletTPConn then _bulletTPConn:Disconnect(); _bulletTPConn = nil end
    if e then

        SetSilentAim(true)
        _bulletTPConn = Workspace.DescendantAdded:Connect(function(obj)
            if not MagicBullet.BulletTP then return end
            if not obj:IsA("BasePart") then return end
            _waitForFastVelocity(obj, function()
                if not MagicBullet.BulletTP then return end
                if _isLikelyOwnBullet(obj) then
                    local target = GetMagicTarget()
                    if target then
                        pcall(function() obj.CFrame = target.CFrame end)
                    end
                end
            end)
        end)
    end
end

local function SetCurveBullet(e)
    if _curveBulletConn then _curveBulletConn:Disconnect(); _curveBulletConn = nil end
    if e then
        _curveBulletConn = Workspace.DescendantAdded:Connect(function(obj)
            if not MagicBullet.CurveBullet then return end
            if not obj:IsA("BasePart") then return end
            _waitForFastVelocity(obj, function()
                if not MagicBullet.CurveBullet then return end
                if not _isLikelyOwnBullet(obj) then return end
                local target = GetMagicTarget()
                if not target then return end
                task.spawn(function()
                    for i = 1, 30 do
                        if not obj or not obj.Parent then break end
                        if not target or not target.Parent then break end
                        pcall(function()
                            local dir = (target.Position - obj.Position)
                            if dir.Magnitude < 2 then
                                obj.CFrame = target.CFrame
                                return
                            end
                            local curve = dir.Unit * math.min(dir.Magnitude, obj.Velocity.Magnitude * 0.03)
                            local up = Vector3.new(0, math.sin(i / 30 * math.pi) * 3, 0)
                            obj.CFrame = obj.CFrame + curve + up
                            obj.Velocity = (target.Position - obj.Position).Unit * obj.Velocity.Magnitude
                        end)
                        task.wait()
                    end
                end)
            end)
        end)
    end
end

_G._MagicBullet = {SetSilentAim=SetSilentAim, SetBulletTP=SetBulletTP, SetCurveBullet=SetCurveBullet, GetCallCount=function() return _silentAimCallCount or 0 end}
end

;(function()
local function SetHitboxExpander(e) if HitboxConnection then HitboxConnection:Disconnect(); HitboxConnection=nil end; if e then HitboxConnection=RunService.Heartbeat:Connect(function() if not HitboxExpander.Enabled then return end; for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then local h=GetRootPart(p.Character); if h then pcall(function() h.Size=Vector3.new(HitboxExpander.Size,HitboxExpander.Size,HitboxExpander.Size); h.Transparency=HitboxExpander.Transparency; h.CanCollide=HitboxExpander.CanCollide; h.Massless=true end) end end end end) else for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then local h=GetRootPart(p.Character); if h then pcall(function() h.Size=Vector3.new(2,2,1); h.Transparency=1; h.CanCollide=false end) end end end end end
function SendChatMessage(msg) pcall(function() if TextChatService.ChatVersion==Enum.ChatVersion.TextChatService then local tc=TextChatService.TextChannels:FindFirstChild("RBXGeneral"); if tc then tc:SendAsync(msg) end end end); pcall(function() local cr=ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents"); if cr then local sm=cr:FindFirstChild("SayMessageRequest"); if sm then sm:FireServer(msg,"All") end end end) end
local function SetChatSpam(e) if ChatSpamConnection then ChatSpamConnection:Disconnect(); ChatSpamConnection=nil end; if e then ChatSpamConnection=RunService.Heartbeat:Connect(function() if ServerTroll.ChatSpam then SendChatMessage(ServerTroll.ChatMessage); task.wait(ServerTroll.SpamDelay) end end) end end
local function SetRemoteSpam(e) if RemoteSpamConnection then RemoteSpamConnection:Disconnect(); RemoteSpamConnection=nil end; if e then RemoteSpamConnection=RunService.Heartbeat:Connect(function() if ServerTroll.RemoteSpam then for _,f in pairs(FoundFunctions.RemoteEvents or {}) do pcall(function() f.Object:FireServer() end) end; task.wait(0.5) end end) end end
local function SetToolSpam(e) if ToolSpamConnection then ToolSpamConnection:Disconnect(); ToolSpamConnection=nil end; if e then ToolSpamConnection=RunService.Heartbeat:Connect(function() if ServerTroll.ToolSpam then local c=LocalPlayer.Character; if c then for _,t in pairs(c:GetChildren()) do if t:IsA("Tool") then pcall(function() t:Activate() end) end end end; task.wait(0.1) end end) end end
local function FlingAllPlayers() task.spawn(function() for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then local h=GetRootPart(p.Character); if h then pcall(function() local bv=Instance.new("BodyVelocity"); bv.MaxForce=Vector3.new(math.huge,math.huge,math.huge); bv.Velocity=Vector3.new(math.random(-500,500),500,math.random(-500,500)); bv.Parent=h; task.wait(0.1); bv:Destroy() end) end end end end) end
local function GetNearestPlayer() local c=LocalPlayer.Character; if not c then return nil end; local rp=GetRootPart(c); if not rp then return nil end; local np,nd=nil,KillAura.Range; for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character and IsAlive(p.Character) then local tr=GetRootPart(p.Character); if tr then local d=(rp.Position-tr.Position).Magnitude; if d<nd then nd=d; np=p end end end end; return np end
local function FEFling(tp) if not tp or not tp.Character then return false end; local c=LocalPlayer.Character; if not c then return false end; local h=GetRootPart(c); local hum=GetHumanoid(c); if not h or not hum then return false end; local tr=GetRootPart(tp.Character); if not tr then return false end; local oc=h.CFrame; pcall(function() settings().Physics.AllowSleep=false end); local bv=Instance.new("BodyVelocity"); bv.MaxForce=Vector3.new(math.huge,math.huge,math.huge); bv.Velocity=Vector3.new(0,0,0); bv.P=1250; bv.Parent=h; local ba=Instance.new("BodyAngularVelocity"); ba.MaxTorque=Vector3.new(math.huge,math.huge,math.huge); ba.AngularVelocity=Vector3.new(0,0,0); ba.P=1250; ba.Parent=h; for _,pt in pairs(c:GetDescendants()) do if pt:IsA("BasePart") then pt.CanCollide=false; pt.Massless=true end end; task.spawn(function() for i=1,150 do if not Fling.Enabled or not tp.Character then break end; local cr=GetRootPart(tp.Character); if not cr then break end; h.CFrame=cr.CFrame; bv.Velocity=Vector3.new(math.random(-Fling.Power,Fling.Power),Fling.Power,math.random(-Fling.Power,Fling.Power)); ba.AngularVelocity=Vector3.new(math.random(-250,250),math.random(-250,250),math.random(-250,250)); task.wait() end; bv:Destroy(); ba:Destroy(); for _,pt in pairs(c:GetDescendants()) do if pt:IsA("BasePart") then pt.CanCollide=true; pt.Massless=false end end; task.wait(0.5); h.CFrame=oc; h.Velocity=Vector3.new(0,0,0); h.RotVelocity=Vector3.new(0,0,0) end); return true end
local AnimationsList={["Wave"]="rbxassetid://507770239",["Point"]="rbxassetid://507770453",["Dance"]="rbxassetid://507771019",["Dance2"]="rbxassetid://507771955",["Dance3"]="rbxassetid://507772104",["Laugh"]="rbxassetid://507770818",["Cheer"]="rbxassetid://507770677",["Ninja Run"]="rbxassetid://656118852",["Zombie"]="rbxassetid://616158929",["Astronaut"]="rbxassetid://891621366",["Robot"]="rbxassetid://616088211",["Floss"]="rbxassetid://5917459365",["Default Dance"]="rbxassetid://5918726674",["Spin"]="rbxassetid://188632011"}
local function PlayAnimation(id,looped) local c=LocalPlayer.Character; if not c then return end; local h=GetHumanoid(c); if not h then return end; if CurrentAnimation then CurrentAnimation:Stop() end; local a=Instance.new("Animation"); a.AnimationId=id; local at=h:LoadAnimation(a); at.Looped=looped or false; at:Play(); CurrentAnimation=at end
local function StopAnimation() if CurrentAnimation then CurrentAnimation:Stop(); CurrentAnimation=nil end end
local function FindAllFunctions()
    FoundFunctions = {RemoteEvents={}, RemoteFunctions={}}
    local yieldCounter = 0
    for _, loc in pairs({ReplicatedStorage, Workspace, Players}) do
        for _, obj in pairs(loc:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                table.insert(FoundFunctions.RemoteEvents, {Name=obj.Name, Path=obj:GetFullName(), Object=obj, Parent=obj.Parent.Name})
            elseif obj:IsA("RemoteFunction") then
                table.insert(FoundFunctions.RemoteFunctions, {Name=obj.Name, Path=obj:GetFullName(), Object=obj, Parent=obj.Parent.Name})
            end
            yieldCounter = yieldCounter + 1
            if yieldCounter % 150 == 0 then task.wait() end
        end
    end
    return FoundFunctions
end
local function GetFunctionNames() local n={}; for i,f in pairs(FoundFunctions.RemoteEvents) do if i<=50 then table.insert(n,f.Name.." ["..f.Parent.."]") end end; if #n==0 then table.insert(n,"Find first") end; return n end
local selectedFunction=nil
local function ExecuteFunction(args) if not selectedFunction then return end; pcall(function() selectedFunction.Object:FireServer(unpack(args or {})) end) end
local SoundList={["Nuke Alarm"]="rbxassetid://138093488",["Bruh"]="rbxassetid://4275842574",["Oof"]="rbxassetid://6518380183",["Windows XP"]="rbxassetid://6026984224",["Vine Boom"]="rbxassetid://6308385367",["Discord Ping"]="rbxassetid://7147454322",["Rickroll"]="rbxassetid://6243296559",["Scary"]="rbxassetid://1841427141",["Nokia"]="rbxassetid://158561138",["Siren"]="rbxassetid://6565487346"}
local function PlayFESound(id,vol,spd,loop) if CurrentSound then CurrentSound:Destroy() end; local c=LocalPlayer.Character; if not c then return end; local r=GetRootPart(c); if not r then return end; local s=Instance.new("Sound"); s.SoundId=id; s.Volume=vol or 0.5; s.PlaybackSpeed=spd or 1; s.Looped=loop or false; s.Parent=r; s:Play(); CurrentSound=s; if not loop then s.Ended:Connect(function() s:Destroy(); CurrentSound=nil end) end end
local function StopFESound() if CurrentSound then CurrentSound:Destroy(); CurrentSound=nil end end
local PhysicsService = game:GetService("PhysicsService")
local _noclipGroupReady = false
local _noclipUseGroup = false
local function _ensureNoclipGroup()
    if _noclipGroupReady then return end
    _noclipGroupReady = true
    pcall(function() PhysicsService:RegisterCollisionGroup("PhazeNoclip") end)
    pcall(function() PhysicsService:CollisionGroupSetCollidable("PhazeNoclip", "Default", false) end)
    local verified = false
    pcall(function() verified = (PhysicsService:CollisionGroupsAreCollidable("PhazeNoclip", "Default") == false) end)
    _noclipUseGroup = verified
    if not verified then
        print("[Phaze] NoClip: collision-group method unavailable on this executor, falling back to CanCollide")
    end
end
local function SetNoClip(e)
    if NoclipConnection then NoclipConnection:Disconnect(); NoclipConnection=nil end
    if e then
        SetupLiteBypass()
        _ensureNoclipGroup()
        NoclipConnection=RunService.Stepped:Connect(function()
            if NoClip.Enabled then
                local c=LocalPlayer.Character
                if c then
                    for _,p in pairs(c:GetDescendants()) do
                        if p:IsA("BasePart") then
                            if _noclipUseGroup then
                                if p.CollisionGroup ~= "PhazeNoclip" then
                                    pcall(function() PhysicsService:SetPartCollisionGroup(p, "PhazeNoclip") end)
                                end
                            elseif p.CanCollide then
                                p.CanCollide = false
                            end
                        end
                    end
                end
            end
        end)
    else
        local c=LocalPlayer.Character
        if c then
            for _,p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                    pcall(function() PhysicsService:SetPartCollisionGroup(p, "Default") end)
                    p.CanCollide = true
                end
            end
        end
    end
end
local Fullbright = {Enabled=false, _backup={}}
local function SetFullbright(e)
    local Lighting = game:GetService("Lighting")
    if e then
        Fullbright._backup.Brightness = Lighting.Brightness
        Fullbright._backup.ClockTime = Lighting.ClockTime
        Fullbright._backup.FogEnd = Lighting.FogEnd
        Fullbright._backup.FogStart = Lighting.FogStart
        Fullbright._backup.GlobalShadows = Lighting.GlobalShadows
        Fullbright._backup.OutdoorAmbient = Lighting.OutdoorAmbient
        Fullbright._backup.Ambient = Lighting.Ambient
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        Lighting.Ambient = Color3.fromRGB(178,178,178)
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then
                if not Fullbright._backup.Atmosphere then Fullbright._backup.Atmosphere = {obj=v, Density=v.Density} end
                v.Density = 0
            elseif v:IsA("ColorCorrectionEffect") then
                if not Fullbright._backup.CCE then Fullbright._backup.CCE = {obj=v, Enabled=v.Enabled} end
                v.Enabled = false
            elseif v:IsA("BloomEffect") then
                if not Fullbright._backup.Bloom then Fullbright._backup.Bloom = {obj=v, Enabled=v.Enabled} end
                v.Enabled = false
            elseif v:IsA("BlurEffect") then
                if not Fullbright._backup.Blur then Fullbright._backup.Blur = {obj=v, Enabled=v.Enabled} end
                v.Enabled = false
            end
        end
    else
        local b = Fullbright._backup
        if b.Brightness then Lighting.Brightness = b.Brightness end
        if b.ClockTime then Lighting.ClockTime = b.ClockTime end
        if b.FogEnd then Lighting.FogEnd = b.FogEnd end
        if b.FogStart then Lighting.FogStart = b.FogStart end
        if b.GlobalShadows ~= nil then Lighting.GlobalShadows = b.GlobalShadows end
        if b.OutdoorAmbient then Lighting.OutdoorAmbient = b.OutdoorAmbient end
        if b.Ambient then Lighting.Ambient = b.Ambient end
        if b.Atmosphere then pcall(function() b.Atmosphere.obj.Density = b.Atmosphere.Density end) end
        if b.CCE then pcall(function() b.CCE.obj.Enabled = b.CCE.Enabled end) end
        if b.Bloom then pcall(function() b.Bloom.obj.Enabled = b.Bloom.Enabled end) end
        if b.Blur then pcall(function() b.Blur.obj.Enabled = b.Blur.Enabled end) end
        Fullbright._backup = {}
    end
end
local InfiniteJump = {Enabled=false}
local InfJumpConn = nil
local function SetInfiniteJump(e)
    InfiniteJump.Enabled = e
    if InfJumpConn then InfJumpConn:Disconnect(); InfJumpConn = nil end
    if not e then return end
    InfJumpConn = UserInputService.JumpRequest:Connect(function()
        if not InfiniteJump.Enabled then return end
        local c = LocalPlayer.Character
        if not c then return end
        local hum = GetHumanoid(c)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

local AntiFall = {Enabled=false}
local AntiFallConn = nil
local _antiFallSafePos = nil
local function SetAntiFall(e)
    AntiFall.Enabled = e
    if AntiFallConn then AntiFallConn:Disconnect(); AntiFallConn = nil end
    if not e then return end
    _antiFallSafePos = nil
    AntiFallConn = RunService.Heartbeat:Connect(function()
        if not AntiFall.Enabled then return end
        local c = LocalPlayer.Character
        if not c then return end
        local rp = GetRootPart(c)
        local hum = GetHumanoid(c)
        if not rp or not hum then return end
        local ok, state = pcall(function() return hum:GetState() end)
        if ok and state ~= Enum.HumanoidStateType.Freefall then
            _antiFallSafePos = rp.CFrame
        end
        local killY = workspace.FallenPartsDestroyHeight
        if killY and killY < 0 and _antiFallSafePos and rp.Position.Y < killY + 150 then
            rp.CFrame = _antiFallSafePos
            pcall(function() rp.Velocity = Vector3.new(0,0,0) end)
            pcall(function() rp.AssemblyLinearVelocity = Vector3.new(0,0,0) end)
            Notify("Anti-Fall","Caught you before the void!",2)
        end
    end)
end

local CustomScale = {Enabled=false, Value=1}
local CustomScaleConn = nil
local function SetCharacterScale(scale)
    local c = LocalPlayer.Character
    if not c then return end
    local hum = GetHumanoid(c)
    if not hum then return end
    local ok = pcall(function() c:ScaleTo(scale) end)
    if not ok then
        for _, name in pairs({"HeadScale","BodyHeightScale","BodyWidthScale","BodyDepthScale"}) do
            local sv = hum:FindFirstChild(name)
            if sv then pcall(function() sv.Value = scale end) end
        end
        print("[Phaze] Resize: :ScaleTo unavailable, used legacy R15-only NumberValue method (no effect on R6 rigs)")
    end
end
local function SetCustomScale(e)
    CustomScale.Enabled = e
    if CustomScaleConn then CustomScaleConn:Disconnect(); CustomScaleConn = nil end
    if not e then
        SetCharacterScale(1)
        return
    end
    SetupLiteBypass()
    SetCharacterScale(CustomScale.Value)
    CustomScaleConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if CustomScale.Enabled then SetCharacterScale(CustomScale.Value) end
    end)
end
local function UpdateCustomScale(v)
    CustomScale.Value = v
    if CustomScale.Enabled then SetCharacterScale(v) end
end

local function _createRagdollJoints(character)
    local joints = {}
    for _, motor in pairs(character:GetDescendants()) do
        if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
            local ok = pcall(function()
                local a0 = Instance.new("Attachment"); a0.CFrame = motor.C0; a0.Parent = motor.Part0
                local a1 = Instance.new("Attachment"); a1.CFrame = motor.C1; a1.Parent = motor.Part1
                local socket = Instance.new("BallSocketConstraint")
                socket.Attachment0 = a0; socket.Attachment1 = a1
                socket.LimitsEnabled = true; socket.TwistLimitsEnabled = true
                socket.MaxFrictionTorque = 30
                socket.Parent = motor.Part0
                motor.Enabled = false
                table.insert(joints, {motor=motor, a0=a0, a1=a1, socket=socket})
            end)
        end
    end
    return joints
end
local function _removeRagdollJoints(joints)
    for _, j in pairs(joints) do
        pcall(function() j.socket:Destroy() end)
        pcall(function() j.a0:Destroy() end)
        pcall(function() j.a1:Destroy() end)
        pcall(function() if j.motor and j.motor.Parent then j.motor.Enabled = true end end)
    end
end
local _ragdollJoints = nil
local function DoRagdoll(character, enable)
    local hum = GetHumanoid(character)
    if not hum then return end
    if enable then
        if _ragdollJoints then _removeRagdollJoints(_ragdollJoints); _ragdollJoints = nil end
        pcall(function() hum.PlatformStand = true end)
        for _, p in pairs(character:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
        end
        _ragdollJoints = _createRagdollJoints(character)
    else
        if _ragdollJoints then _removeRagdollJoints(_ragdollJoints); _ragdollJoints = nil end
        pcall(function() hum.PlatformStand = false end)
    end
end

local RandomRagdoll = {Enabled=false, Interval=5}
local RandomRagdollThread = nil
local function SetRandomRagdoll(e)
    RandomRagdoll.Enabled = e
    if RandomRagdollThread then pcall(function() task.cancel(RandomRagdollThread) end); RandomRagdollThread = nil end
    if not e then
        local c = LocalPlayer.Character
        if c then DoRagdoll(c, false) end
        return
    end
    SetupLiteBypass()
    RandomRagdollThread = task.spawn(function()
        while RandomRagdoll.Enabled do
            task.wait(RandomRagdoll.Interval)
            if not RandomRagdoll.Enabled then break end
            local c = LocalPlayer.Character
            if c and GetHumanoid(c) then
                DoRagdoll(c, true)
                task.wait(2.5)
                if RandomRagdoll.Enabled and c.Parent then
                    DoRagdoll(c, false)
                end
            end
        end
    end)
end

local function SetCustomSpeed(e)
    CustomSpeed.Enabled = e
    if CustomSpeedConn then CustomSpeedConn:Disconnect(); CustomSpeedConn = nil end
    if not e then
        local c = LocalPlayer.Character
        if c then local hum = GetHumanoid(c); if hum then hum.WalkSpeed = 16 end end
        return
    end
    SetupLiteBypass()
    CustomSpeedConn = RunService.Heartbeat:Connect(function()
        if not CustomSpeed.Enabled then return end
        local c = LocalPlayer.Character
        if not c then return end
        local hum = GetHumanoid(c)
        if hum and hum.WalkSpeed ~= CustomSpeed.Speed then hum.WalkSpeed = CustomSpeed.Speed end
    end)
end
local function SetFly(e) local c=LocalPlayer.Character; if not c then return end; local hum=GetHumanoid(c); local rp=GetRootPart(c); if not hum or not rp then return end; if FlyConnection then FlyConnection:Disconnect(); FlyConnection=nil end; if FlyBodyVelocity then FlyBodyVelocity:Destroy(); FlyBodyVelocity=nil end; if FlyBodyGyro then FlyBodyGyro:Destroy(); FlyBodyGyro=nil end; if e then SetupLiteBypass(); hum.PlatformStand=true; FlyBodyVelocity=Instance.new("BodyVelocity"); FlyBodyVelocity.MaxForce=Vector3.new(9e9,9e9,9e9); FlyBodyVelocity.Velocity=Vector3.new(0,0,0); FlyBodyVelocity.Parent=rp; FlyBodyGyro=Instance.new("BodyGyro"); FlyBodyGyro.MaxTorque=Vector3.new(9e9,9e9,9e9); FlyBodyGyro.CFrame=rp.CFrame; FlyBodyGyro.Parent=rp; local cv=Vector3.new(0,0,0); FlyConnection=RunService.RenderStepped:Connect(function() if Fly.Enabled and FlyBodyVelocity and FlyBodyGyro then local cam=workspace.CurrentCamera; local md=Vector3.new(0,0,0); if UserInputService:IsKeyDown(Enum.KeyCode.W) then md=md+cam.CFrame.LookVector end; if UserInputService:IsKeyDown(Enum.KeyCode.S) then md=md-cam.CFrame.LookVector end; if UserInputService:IsKeyDown(Enum.KeyCode.A) then md=md-cam.CFrame.RightVector end; if UserInputService:IsKeyDown(Enum.KeyCode.D) then md=md+cam.CFrame.RightVector end; if UserInputService:IsKeyDown(Enum.KeyCode.Space) then md=md+Vector3.new(0,1,0) end; if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then md=md-Vector3.new(0,1,0) end; if md.Magnitude>0 then md=md.Unit end; cv=cv:Lerp(md*Fly.Speed,Fly.Smoothness); FlyBodyVelocity.Velocity=cv; FlyBodyGyro.CFrame=CFrame.new(rp.Position,rp.Position+Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)) end end) else if hum then hum.PlatformStand=false end end end
function TeleportTo(cf)
    local c=LocalPlayer.Character; if not c then return end; local rp=GetRootPart(c)
    if rp then
        _playerTeleporting = true
        if AntiCheatBypass.AntiTeleportDetection then
            TweenService:Create(rp,TweenInfo.new(0.5,Enum.EasingStyle.Quad),{CFrame=cf}):Play()
        else
            rp.CFrame=cf
        end
        _lastValidPos = cf
        task.delay(0.5, function() _playerTeleporting = false end)
    end
end
local MovementRecorder = {Recording=false, Playing=false, Frames={}, Status="Idle", LoopPlayback=false}
local _movRecConn = nil
local _movPlayConn = nil
local function SetMovementRecord(e)
    if _movRecConn then _movRecConn:Disconnect(); _movRecConn = nil end
    MovementRecorder.Recording = e
    if not e then
        MovementRecorder.Status = "Stopped recording ("..#MovementRecorder.Frames.." frames)"
        return
    end
    if MovementRecorder.Playing then
        NotifyError("Movement Recorder","Stop playback first",3)
        MovementRecorder.Recording = false
        return
    end
    local c = LocalPlayer.Character
    local rp = c and GetRootPart(c)
    if not rp then
        NotifyError("Movement Recorder","No character found",3)
        MovementRecorder.Recording = false
        return
    end
    MovementRecorder.Frames = {}
    local startTime = os.clock()
    Notify("Movement Recorder","Recording started - move around now",3)
    _movRecConn = RunService.Heartbeat:Connect(function()
        if not MovementRecorder.Recording then return end
        local cc = LocalPlayer.Character
        local crp = cc and GetRootPart(cc)
        if not crp then return end
        local hum = cc:FindFirstChildOfClass("Humanoid")
        local state = hum and hum:GetState()
        table.insert(MovementRecorder.Frames, {t=os.clock()-startTime, cf=crp.CFrame, jump=(state==Enum.HumanoidStateType.Jumping or state==Enum.HumanoidStateType.Freefall)})
        MovementRecorder.Status = "Recording... ("..#MovementRecorder.Frames.." frames)"
    end)
end
local function SetMovementPlay(e)
    if _movPlayConn then pcall(task.cancel, _movPlayConn); _movPlayConn = nil end
    MovementRecorder.Playing = e
    if not e then
        MovementRecorder.Status = "Playback stopped"
        return
    end
    if MovementRecorder.Recording then
        NotifyError("Movement Recorder","Stop recording first",3)
        MovementRecorder.Playing = false
        return
    end
    if #MovementRecorder.Frames == 0 then
        NotifyError("Movement Recorder","No recording saved yet",3)
        MovementRecorder.Playing = false
        return
    end
    _movPlayConn = task.spawn(function()
        repeat
            local startTime = os.clock()
            local frames = MovementRecorder.Frames
            local i = 1
            local wasJumping = false
            while MovementRecorder.Playing and i <= #frames do
                local c = LocalPlayer.Character
                local rp = c and GetRootPart(c)
                if not rp then break end
                local now = os.clock() - startTime
                while i <= #frames and frames[i].t <= now do
                    pcall(function() rp.CFrame = frames[i].cf end)
                    if frames[i].jump and not wasJumping then
                        local hum = c:FindFirstChildOfClass("Humanoid")
                        if hum then pcall(function() hum.Jump = true end) end
                    end
                    wasJumping = frames[i].jump
                    i = i + 1
                end
                MovementRecorder.Status = "Playing... ("..i.."/"..#frames..")"
                RunService.Heartbeat:Wait()
            end
        until not MovementRecorder.Playing or not MovementRecorder.LoopPlayback
        MovementRecorder.Playing = false
        MovementRecorder.Status = "Playback finished"
    end)
end
local function SaveMovementRecordingToFile(name)
    local wf = _getFunc("writefile")
    if not wf then return false, "Executor doesn't support writefile" end
    local data = {}
    for _, f in ipairs(MovementRecorder.Frames) do
        table.insert(data, {t=f.t, cf={f.cf:GetComponents()}, jump=f.jump})
    end
    local ok, err = pcall(function()
        wf("Phaze_Movement_"..name..".json", HttpService:JSONEncode(data))
    end)
    return ok, err
end
local function LoadMovementRecordingFromFile(name)
    local rf = _getFunc("readfile")
    local isfile = _getFunc("isfile")
    if not rf then return false, "Executor doesn't support readfile" end
    if isfile and not isfile("Phaze_Movement_"..name..".json") then return false, "File not found" end
    local ok, result = pcall(function()
        local raw = rf("Phaze_Movement_"..name..".json")
        local data = HttpService:JSONDecode(raw)
        local frames = {}
        for _, f in ipairs(data) do
            table.insert(frames, {t=f.t, cf=CFrame.new(unpack(f.cf)), jump=f.jump})
        end
        return frames
    end)
    if ok then MovementRecorder.Frames = result end
    return ok, result
end
local function SetKillAura(e) if KillAuraConnection then KillAuraConnection:Disconnect(); KillAuraConnection=nil end; if e then KillAuraConnection=RunService.Heartbeat:Connect(function() if KillAura.Enabled then local c=LocalPlayer.Character; if not c then return end; local np=GetNearestPlayer(); if np and np.Character then local tr=GetRootPart(np.Character); if tr then local tl=c:FindFirstChildOfClass("Tool"); if tl then tl:Activate() end; local rp=GetRootPart(c); if rp then rp.CFrame=CFrame.new(rp.Position,tr.Position) end end end; task.wait(KillAura.Delay) end end) end end
local GodModeHealthConn = nil
local GodModeHeartbeat = nil
local GodModeDiedConn = nil
local function SetGodMode(e)
    if GodModeConnection then GodModeConnection:Disconnect(); GodModeConnection=nil end
    if GodModeHealthConn then GodModeHealthConn:Disconnect(); GodModeHealthConn=nil end
    if GodModeHeartbeat then GodModeHeartbeat:Disconnect(); GodModeHeartbeat=nil end
    if GodModeDiedConn then GodModeDiedConn:Disconnect(); GodModeDiedConn=nil end
    if e then
        local function setupGod()
            local ch = LocalPlayer.Character
            if not ch then return end
            local h = GetHumanoid(ch)
            if not h then return end
            pcall(function()
                h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                h:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                h.BreakJointsOnDeath = false
                h.RequiresNeck = false
                h.MaxHealth = math.huge
                h.Health = math.huge
            end)

            pcall(function()
                local head = ch:FindFirstChild("Head")
                if head then
                    for _, j in pairs(ch:GetDescendants()) do
                        if j:IsA("Motor6D") or j:IsA("Weld") then
                            pcall(function() j.Enabled = true end)
                        end
                    end
                end
            end)
            if GodModeHealthConn then GodModeHealthConn:Disconnect() end
            GodModeHealthConn = h.HealthChanged:Connect(function(newHealth)
                if AntiCheatBypass.GodMode then
                    pcall(function() h.Health = h.MaxHealth end)
                end
            end)
            if GodModeDiedConn then GodModeDiedConn:Disconnect() end
            GodModeDiedConn = h.Died:Connect(function()
                if AntiCheatBypass.GodMode then
                    pcall(function() h.Health = h.MaxHealth end)
                end
            end)
            if GodModeHeartbeat then GodModeHeartbeat:Disconnect() end
            GodModeHeartbeat = RunService.Heartbeat:Connect(function()
                if not AntiCheatBypass.GodMode then return end
                local c2 = LocalPlayer.Character
                if not c2 then return end
                local h2 = GetHumanoid(c2)
                if not h2 then return end
                pcall(function()
                    if h2.Health < h2.MaxHealth then h2.Health = h2.MaxHealth end
                end)
            end)
        end
        setupGod()
        GodModeConnection = LocalPlayer.CharacterAdded:Connect(function(ch)
            ch:WaitForChild("Humanoid", 5)
            task.wait(0.3)
            if AntiCheatBypass.GodMode then setupGod() end
        end)
    end
end
local function SetOneHitKill(e) if OneHitKill.Connection then OneHitKill.Connection:Disconnect() end; if e then OneHitKill.Connection=RunService.Heartbeat:Connect(function() if OneHitKill.Enabled then local c=LocalPlayer.Character; if not c then return end; local tl=c:FindFirstChildOfClass("Tool"); if tl and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then local ha=tl:FindFirstChild("Handle"); if ha then local myRp=GetRootPart(c); local n=GetNearestPlayer(); if n and n.Character and myRp then local tr=GetRootPart(n.Character); if tr and (myRp.Position-tr.Position).Magnitude<12 then local _fti=_getFunc("firetouchinterest"); if _fti then for i=1,60 do pcall(function() _fti(tr,ha,0); _fti(tr,ha,1) end) end end end end end end end end) end end

local FreecamConn = nil
local FreecamActive = false
local FreecamState = {Speed=50, Yaw=0, Pitch=0}
local FreecamSavedTransparency = {}
local FreecamAnchoredRoot = nil
local FreecamCharAddedConn = nil
local FreecamMouseConn = nil
local FreecamSavedMouseBehavior = nil
local FreecamPos = nil
local FreecamClickConn = nil
local FreecamArrowConn = nil
local FreecamRMBConn = nil
local FreecamRMBUpConn = nil
local FreecamRMBDown = false
local FreecamHint = nil
local FreecamHintLabel = nil
local FreecamMode = "Teleport"
local FreecamModes = {"Teleport", "Build", "CornerBuild", "Draw"}
local FreecamBlockSize = 12
local FreecamCornerThickness = 2
local FreecamPlacedParts = {}
local FreecamCornerA = nil
local FreecamCornerMarker = nil
local FreecamDrawPoints = {}
local FreecamDrawEntries = {}
local FreecamDrawTip = nil
local function _freecamHintText()
    local holdRmb = "Hold Right-Click: Look Around  |  "
    if FreecamMode == "Build" then
        return holdRmb.."Left-Click: Place Platform  |  ←→: Switch Mode (Build)"
    elseif FreecamMode == "CornerBuild" then
        if FreecamCornerA then
            return holdRmb.."Left-Click: Set Corner B  |  Backspace: Cancel  |  ←→: Switch Mode (Corner Build)"
        end
        return holdRmb.."Left-Click: Set Corner A  |  ←→: Switch Mode (Corner Build)"
    elseif FreecamMode == "Draw" then
        return holdRmb.."Left-Click: Add Waypoint  |  Backspace: Undo Last  |  ←→: Switch Mode (Draw)"
    end
    return holdRmb.."Left-Click: Teleport Here  |  ←→: Switch Mode (Teleport)"
end
local function _ensureFreecamHint()
    if FreecamHint then return end
    if not ScreenGui then return end
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(0,320,0,30)
    holder.AnchorPoint = Vector2.new(0.5,1)
    holder.Position = UDim2.new(0.5,0,1,-70)
    holder.BackgroundColor3 = Color3.fromRGB(10,10,11)
    holder.BackgroundTransparency = 0.25
    holder.BorderSizePixel = 0
    holder.Visible = false
    holder.Parent = ScreenGui
    local corner = Instance.new("UICorner", holder); corner.CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", holder); stroke.Color = Color3.fromRGB(60,60,64); stroke.Thickness = 1; stroke.Transparency = 0.3
    local lbl = Instance.new("TextLabel", holder)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = _freecamHintText()
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(240,240,244)
    FreecamHint = holder
    FreecamHintLabel = lbl
end
local function _placeFreecamBlock(pos)
    local ok = pcall(function()
        local part = Instance.new("Part")
        part.Size = Vector3.new(FreecamBlockSize, 1, FreecamBlockSize)
        part.CFrame = CFrame.new(pos)
        part.Anchored = true
        part.CanCollide = true
        part.Material = Enum.Material.Concrete
        part.Color = Color3.fromRGB(150,150,158)
        part.Name = "PhazeBuild"
        part.Parent = Workspace
        table.insert(FreecamPlacedParts, part)
    end)
    return ok
end
local function _setFreecamCornerMarker(pos)
    if FreecamCornerMarker then pcall(function() FreecamCornerMarker:Destroy() end); FreecamCornerMarker = nil end
    if not pos then return end
    pcall(function()
        local marker = Instance.new("Part")
        marker.Shape = Enum.PartType.Ball
        marker.Size = Vector3.new(1.5, 1.5, 1.5)
        marker.CFrame = CFrame.new(pos)
        marker.Anchored = true
        marker.CanCollide = false
        marker.Material = Enum.Material.Neon
        marker.Color = Color3.fromRGB(255, 200, 60)
        marker.Name = "PhazeCornerMarker"
        marker.Parent = Workspace
        FreecamCornerMarker = marker
    end)
end
local function _placeFreecamCornerBlock(a, b)
    local ok = pcall(function()
        local sizeX = math.max(math.abs(a.X - b.X), FreecamCornerThickness)
        local sizeY = math.max(math.abs(a.Y - b.Y), FreecamCornerThickness)
        local sizeZ = math.max(math.abs(a.Z - b.Z), FreecamCornerThickness)
        local center = (a + b) / 2
        local part = Instance.new("Part")
        part.Size = Vector3.new(sizeX, sizeY, sizeZ)
        part.CFrame = CFrame.new(center)
        part.Anchored = true
        part.CanCollide = true
        part.Material = Enum.Material.Concrete
        part.Color = Color3.fromRGB(150,150,158)
        part.Name = "PhazeBuild"
        part.Parent = Workspace
        table.insert(FreecamPlacedParts, part)
    end)
    return ok
end
local function ClearFreecamBlocks()
    for _, p in pairs(FreecamPlacedParts) do pcall(function() p:Destroy() end) end
    FreecamPlacedParts = {}
    FreecamCornerA = nil
    _setFreecamCornerMarker(nil)
end
local function _addFreecamDrawPoint(pos)
    table.insert(FreecamDrawPoints, pos)
    local entry = {}
    pcall(function()
        local marker = Instance.new("Part")
        marker.Shape = Enum.PartType.Ball
        marker.Size = Vector3.new(1.6, 1.6, 1.6)
        marker.CFrame = CFrame.new(pos)
        marker.Anchored = true
        marker.CanCollide = false
        marker.Material = Enum.Material.Neon
        marker.Color = Color3.fromRGB(255, 200, 60)
        marker.Name = "PhazeDrawPoint"
        marker.Parent = Workspace
        entry.marker = marker
    end)
    if FreecamDrawTip then
        pcall(function() FreecamDrawTip.Size = Vector3.new(0.8, 0.8, 0.8); FreecamDrawTip.Color = Color3.fromRGB(80, 200, 255) end)
    end
    FreecamDrawTip = entry.marker
    local n = #FreecamDrawPoints
    if n > 1 then
        local a, b = FreecamDrawPoints[n-1], FreecamDrawPoints[n]
        pcall(function()
            local dist = (b - a).Magnitude
            local mid = (a + b) / 2
            local line = Instance.new("Part")
            line.Size = Vector3.new(0.35, 0.35, dist)
            line.CFrame = CFrame.lookAt(mid, b)
            line.Anchored = true
            line.CanCollide = false
            line.Material = Enum.Material.Neon
            line.Color = Color3.fromRGB(80, 200, 255)
            line.Name = "PhazeDrawLine"
            line.Parent = Workspace
            entry.line = line
        end)
    end
    table.insert(FreecamDrawEntries, entry)
end
local function _undoFreecamDrawPoint()
    if #FreecamDrawEntries == 0 then return end
    local entry = table.remove(FreecamDrawEntries, #FreecamDrawEntries)
    table.remove(FreecamDrawPoints, #FreecamDrawPoints)
    pcall(function() if entry.marker then entry.marker:Destroy() end end)
    pcall(function() if entry.line then entry.line:Destroy() end end)
    local prev = FreecamDrawEntries[#FreecamDrawEntries]
    if prev and prev.marker then
        FreecamDrawTip = prev.marker
        pcall(function() FreecamDrawTip.Size = Vector3.new(1.6, 1.6, 1.6); FreecamDrawTip.Color = Color3.fromRGB(255, 200, 60) end)
    else
        FreecamDrawTip = nil
    end
end
local function ClearFreecamDrawing()
    for _, entry in pairs(FreecamDrawEntries) do
        pcall(function() if entry.marker then entry.marker:Destroy() end end)
        pcall(function() if entry.line then entry.line:Destroy() end end)
    end
    FreecamDrawEntries = {}
    FreecamDrawPoints = {}
    FreecamDrawTip = nil
end
local function SetFreecam(e)
    if FreecamConn then FreecamConn:Disconnect(); FreecamConn = nil end
    if FreecamCharAddedConn then FreecamCharAddedConn:Disconnect(); FreecamCharAddedConn = nil end
    if FreecamMouseConn then FreecamMouseConn:Disconnect(); FreecamMouseConn = nil end
    if FreecamClickConn then FreecamClickConn:Disconnect(); FreecamClickConn = nil end
    if FreecamArrowConn then FreecamArrowConn:Disconnect(); FreecamArrowConn = nil end
    if FreecamRMBConn then FreecamRMBConn:Disconnect(); FreecamRMBConn = nil end
    if FreecamRMBUpConn then FreecamRMBUpConn:Disconnect(); FreecamRMBUpConn = nil end
    FreecamRMBDown = false
    FreecamActive = e
    if not e then FreecamCornerA = nil; _setFreecamCornerMarker(nil) end
    _ensureFreecamHint()
    if FreecamHint then FreecamHint.Visible = e end
    if FreecamHintLabel then FreecamHintLabel.Text = _freecamHintText() end
    local c = LocalPlayer.Character
    if e then
        if c then
            local rp = GetRootPart(c)
            if rp then FreecamAnchoredRoot = rp; pcall(function() rp.Anchored = true end) end
        end
        pcall(function()
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CameraSubject = nil
        end)
        local startCF = Camera.CFrame
        FreecamPos = startCF.Position
        local rx, ry = startCF:ToOrientation()
        FreecamState.Pitch = math.clamp(math.deg(rx), -89, 89)
        FreecamState.Yaw = math.deg(ry)

        FreecamSavedMouseBehavior = UserInputService.MouseBehavior
        pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)

        FreecamMouseConn = UserInputService.InputChanged:Connect(function(inp)
            if not FreecamActive or not FreecamRMBDown then return end
            if inp.UserInputType == Enum.UserInputType.MouseMovement then
                local sens = 0.2
                FreecamState.Yaw = FreecamState.Yaw - inp.Delta.X * sens
                FreecamState.Pitch = math.clamp(FreecamState.Pitch - inp.Delta.Y * sens, -89, 89)
            end
        end)

        FreecamRMBConn = UserInputService.InputBegan:Connect(function(inp, gpe)
            if not FreecamActive or gpe then return end
            if inp.UserInputType == Enum.UserInputType.MouseButton2 then
                FreecamRMBDown = true
                pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter end)
            end
        end)
        FreecamRMBUpConn = UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton2 then
                FreecamRMBDown = false
                if FreecamActive then pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end) end
            end
        end)

        FreecamArrowConn = UserInputService.InputBegan:Connect(function(inp, gpe)
            if not FreecamActive then return end
            if inp.KeyCode == Enum.KeyCode.Left or inp.KeyCode == Enum.KeyCode.Right then
                local curIdx = table.find(FreecamModes, FreecamMode) or 1
                local dir = (inp.KeyCode == Enum.KeyCode.Right) and 1 or -1
                local nextIdx = ((curIdx - 1 + dir) % #FreecamModes) + 1
                FreecamMode = FreecamModes[nextIdx]
                FreecamCornerA = nil
                _setFreecamCornerMarker(nil)
                if FreecamHintLabel then FreecamHintLabel.Text = _freecamHintText() end
                Notify("Freecam","Mode: "..FreecamMode,1.5)
            elseif inp.KeyCode == Enum.KeyCode.Backspace and FreecamMode == "CornerBuild" and FreecamCornerA then
                FreecamCornerA = nil
                _setFreecamCornerMarker(nil)
                if FreecamHintLabel then FreecamHintLabel.Text = _freecamHintText() end
                Notify("Freecam","Corner A cancelled",1.5)
            elseif inp.KeyCode == Enum.KeyCode.Backspace and FreecamMode == "Draw" then
                _undoFreecamDrawPoint()
                Notify("Freecam","Undid last waypoint ("..#FreecamDrawPoints.." left)",1.5)
            end
        end)

        FreecamClickConn = UserInputService.InputBegan:Connect(function(inp, gpe)
            if not FreecamActive or gpe then return end
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            pcall(function()
                local origin = Camera.CFrame.Position
                local dir = Camera.CFrame.LookVector * 2000
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                local c = LocalPlayer.Character
                params.FilterDescendantsInstances = c and {c} or {}
                local result = Workspace:Raycast(origin, dir, params)
                local dest = result and result.Position or (origin + Camera.CFrame.LookVector * 300)
                if FreecamMode == "Build" then
                    if _placeFreecamBlock(dest) then
                        Notify("Freecam","Platform placed (visible/usable to you only)",2)
                    end
                elseif FreecamMode == "CornerBuild" then
                    if not FreecamCornerA then
                        FreecamCornerA = dest
                        _setFreecamCornerMarker(dest)
                        if FreecamHintLabel then FreecamHintLabel.Text = _freecamHintText() end
                        Notify("Freecam","Corner A set — click Corner B",2)
                    else
                        if _placeFreecamCornerBlock(FreecamCornerA, dest) then
                            Notify("Freecam","Block built between corners (visible/usable to you only)",2)
                        end
                        FreecamCornerA = nil
                        _setFreecamCornerMarker(nil)
                        if FreecamHintLabel then FreecamHintLabel.Text = _freecamHintText() end
                    end
                elseif FreecamMode == "Draw" then
                    _addFreecamDrawPoint(dest)
                    Notify("Freecam","Waypoint "..#FreecamDrawPoints.." added",1.2)
                else
                    TeleportTo(CFrame.new(dest + Vector3.new(0,3,0)))
                    Notify("Freecam","Teleported to clicked spot",2)
                end
            end)
        end)

        FreecamConn = RunService.RenderStepped:Connect(function(dt)
            if not FreecamActive then return end
            pcall(function()
                if Camera.CameraType ~= Enum.CameraType.Scriptable then
                    Camera.CameraType = Enum.CameraType.Scriptable
                end
            end)
            local speed = FreecamState.Speed * dt
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 2.5 end
            local rotCF = CFrame.Angles(0, math.rad(FreecamState.Yaw), 0) * CFrame.Angles(math.rad(FreecamState.Pitch), 0, 0)
            local move = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + rotCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - rotCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - rotCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + rotCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then move = move - Vector3.new(0,1,0) end
            if move.Magnitude > 0 then
                FreecamPos = FreecamPos + move.Unit * speed
            end
            Camera.CFrame = CFrame.new(FreecamPos) * rotCF
        end)
        FreecamCharAddedConn = LocalPlayer.CharacterAdded:Connect(function(nc)
            if not FreecamActive then return end
            nc:WaitForChild("HumanoidRootPart", 5)
            task.wait(0.2)
            local rp = GetRootPart(nc)
            if rp then FreecamAnchoredRoot = rp; pcall(function() rp.Anchored = true end) end
        end)
    else
        pcall(function()
            Camera.CameraType = Enum.CameraType.Custom
            if c then
                local h = GetHumanoid(c)
                if h then Camera.CameraSubject = h end
            end
        end)
        pcall(function() UserInputService.MouseBehavior = FreecamSavedMouseBehavior or Enum.MouseBehavior.Default end)
        if FreecamAnchoredRoot then pcall(function() FreecamAnchoredRoot.Anchored = false end); FreecamAnchoredRoot = nil end
    end
end

local NoReload = {Enabled=false}
local NoReloadConn = nil
local NoReloadHooks = {}
local function _findAmmoValues(tool)
    local found = {}
    for _, d in pairs(tool:GetDescendants()) do
        if d:IsA("IntValue") or d:IsA("NumberValue") then
            local n = d.Name:lower()
            if n:find("ammo") or n:find("bullet") or n:find("mag") or n:find("clip") or n:find("round") then
                table.insert(found, d)
            end
        end
    end
    return found
end
local function _scanToolForMax(tool)
    local maxV = nil
    for _, d in pairs(tool:GetDescendants()) do
        if d:IsA("IntValue") or d:IsA("NumberValue") then
            local n = d.Name:lower()
            if n:find("max") and (n:find("ammo") or n:find("bullet") or n:find("mag") or n:find("clip")) then
                maxV = d.Value
                break
            end
        end
    end
    return maxV
end
local function SetNoReload(e)
    NoReload.Enabled = e
    if NoReloadConn then pcall(function() NoReloadConn:Disconnect() end); NoReloadConn = nil end
    for _, c in pairs(NoReloadHooks) do pcall(function() c:Disconnect() end) end
    NoReloadHooks = {}
    if e then

        if _hookfunction and _newcclosure and not _G._NoReloadHookInstalled then
            _G._NoReloadHookInstalled = true
            pcall(function()
                local tmpEv = Instance.new("RemoteEvent")
                local oldFire
                oldFire = _hookfunction(tmpEv.FireServer, _newcclosure(function(self, ...)
                    if NoReload.Enabled and not (_checkcaller and _checkcaller()) and typeof(self) == "Instance" then
                        local ok, n = pcall(function() return self.Name:lower() end)
                        if ok and n:find("reload") then return nil end
                    end
                    return oldFire(self, ...)
                end))
                tmpEv:Destroy()
                local tmpFn = Instance.new("RemoteFunction")
                local oldInv
                oldInv = _hookfunction(tmpFn.InvokeServer, _newcclosure(function(self, ...)
                    if NoReload.Enabled and not (_checkcaller and _checkcaller()) and typeof(self) == "Instance" then
                        local ok, n = pcall(function() return self.Name:lower() end)
                        if ok and n:find("reload") then return nil end
                    end
                    return oldInv(self, ...)
                end))
                tmpFn:Destroy()
            end)
        end

        if false and _hookmetamethod and _newcclosure and not _G._NoReloadNamecallInstalled then
            _G._NoReloadNamecallInstalled = true
            pcall(function()
                local oldNc
                oldNc = _hookmetamethod(game, "__namecall", _newcclosure(function(self, ...)
                    if NoReload.Enabled and not (_checkcaller and _checkcaller()) then
                        local m = _getnamecallmethod and _getnamecallmethod() or ""
                        if m == "FireServer" or m == "InvokeServer" then
                            if typeof(self) == "Instance" then
                                local n = self.Name:lower()
                                if n:find("reload") then return nil end
                            end
                        end
                        if m == "Play" or m == "LoadAnimation" then
                            local ok, parent = pcall(function() return self.Parent end)
                            if ok and parent then
                                local pn = (self.Name or ""):lower()
                                if pn:find("reload") then return nil end
                            end
                        end
                    end
                    return oldNc(self, ...)
                end))
            end)
        end
        local cachedValues = {}
        local cachedAttrs = {}
        local function nameLooksAmmo(n)
            n = n:lower()
            return (n:find("ammo") or n:find("bullet") or n:find("mag") or n:find("clip") or n:find("round")) and not (n:find("max") and not n:find("mag"))
        end
        local function tryCacheValue(d)
            pcall(function()
                if (d:IsA("IntValue") or d:IsA("NumberValue")) and nameLooksAmmo(d.Name) then
                    cachedValues[d] = true
                end
            end)
        end
        local function tryCacheAttrs(inst)
            pcall(function()
                if not inst.GetAttributes then return end
                for an, av in pairs(inst:GetAttributes()) do
                    local lan = an:lower()
                    if type(av) == "number" and (lan:find("ammo") or lan:find("bullet") or lan:find("mag") or lan:find("clip") or lan:find("round")) and not lan:find("max") then
                        cachedAttrs[inst] = cachedAttrs[inst] or {}
                        cachedAttrs[inst][an] = true
                    end
                end
            end)
        end
        local function scanRoot(root)
            if not root then return end
            pcall(function()
                for _, d in pairs(root:GetDescendants()) do
                    tryCacheValue(d); tryCacheAttrs(d)
                end
                tryCacheAttrs(root)
                table.insert(NoReloadHooks, root.DescendantAdded:Connect(function(d)
                    tryCacheValue(d); tryCacheAttrs(d)
                end))
            end)
        end
        local function rebuild()
            cachedValues = {}; cachedAttrs = {}
            for _, c in pairs(NoReloadHooks) do pcall(function() c:Disconnect() end) end
            NoReloadHooks = {}
            scanRoot(LocalPlayer.Character)
            scanRoot(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
            scanRoot(LocalPlayer:FindFirstChildOfClass("Backpack"))

            local ps = LocalPlayer:FindFirstChildOfClass("PlayerScripts")
            if ps then
                local mods = ps:FindFirstChild("Modules")
                if mods then
                    local vm = mods:FindFirstChild("ViewModels")
                    if vm then scanRoot(vm) end
                    scanRoot(mods)
                else
                    scanRoot(ps)
                end
            end
            tryCacheAttrs(LocalPlayer)
        end
        rebuild()
        table.insert(NoReloadHooks, LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5); if NoReload.Enabled then rebuild() end end))

        NoReloadConn = task.spawn(function()
            while NoReload.Enabled do
                for v, _ in pairs(cachedValues) do
                    local ok, alive = pcall(function() return v and v.Parent ~= nil end)
                    if ok and alive then
                        pcall(function() if v.Value < 999 then v.Value = 999 end end)
                    else
                        cachedValues[v] = nil
                    end
                end
                for inst, attrs in pairs(cachedAttrs) do
                    local ok, alive = pcall(function() return inst and inst.Parent ~= nil end)
                    if ok and alive then
                        for an, _ in pairs(attrs) do
                            pcall(function()
                                local cur = inst:GetAttribute(an)
                                if type(cur) == "number" and cur < 999 then inst:SetAttribute(an, 999) end
                            end)
                        end
                    else
                        cachedAttrs[inst] = nil
                    end
                end
                task.wait(0.2)
            end
        end)
    end
end

local LemonFarm = {Enabled=false, AutoFruit=true, AutoOrchard=true, AutoBuy=false, AutoUpgrade=false, Delay=1, Status="Not detected", LastBuyResult="", LastUpgradeResult=""}
local LemonFarmConn = nil
local _fireclickdetector = _getFunc("fireclickdetector")
local _fireproximityprompt = _getFunc("fireproximityprompt")

local function GetMyTycoon()
    for _, inst in pairs(workspace:GetChildren()) do
        if inst.Name:match("^Tycoon%d+$") then
            local owner = inst:FindFirstChild("Owner")
            if owner and owner:IsA("ObjectValue") and owner.Value == LocalPlayer then
                return inst
            end
        end
    end
    return nil
end

local function _lemonCollectFruit(tycoon)
    if not _fireclickdetector then return end
    local constant = tycoon:FindFirstChild("Constant")
    local trees = constant and constant:FindFirstChild("Trees")
    if not trees then return end
    for _, cd in pairs(trees:GetDescendants()) do
        if cd:IsA("ClickDetector") then
            pcall(_fireclickdetector, cd)
        end
    end
end

local function _lemonOrchard(tycoon)
    if not _fireproximityprompt then return end
    local orchard = tycoon:FindFirstChild("Orchard")
    local plots = orchard and orchard:FindFirstChild("Plots")
    if not plots then return end
    for _, plot in pairs(plots:GetChildren()) do
        local pp = plot:FindFirstChild("PromptPart")
        local prompt = pp and pp:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            pcall(_fireproximityprompt, prompt)
        end
    end
end

local function _instPos(inst)
    local ok, cf = pcall(function() return inst:GetPivot() end)
    if ok and cf then return cf.Position end
    if inst:IsA("BasePart") then return inst.Position end
    return nil
end

local function _invokeWithTimeout(remote, timeout)
    local done, result, resultErr = false, nil, nil
    task.spawn(function()
        local ok, err = pcall(function() return remote:InvokeServer() end)
        result, resultErr, done = ok, err, true
    end)
    local t = 0
    while not done and t < timeout do task.wait(0.05); t = t + 0.05 end
    if not done then return false, "timeout (no server response)" end
    if not result then return false, tostring(resultErr) end
    return true, resultErr
end

local _lemonDenyCooldown = setmetatable({}, {__mode = "k"})

local function _lemonRunRemotes(tycoon, remoteName, manual)
    local purchases = tycoon:FindFirstChild("Purchases")
    if not purchases then
        return 0, 0, 0, 0, "No Purchases folder found in "..tycoon.Name
    end
    local c = LocalPlayer.Character
    local rp = c and GetRootPart(c)
    local origCF = rp and rp.CFrame
    local ok_n, fail_n, skip_n, deny_n, firstErr = 0, 0, 0, 0, nil
    local now = tick()
    for _, inst in pairs(purchases:GetDescendants()) do
        if inst:IsA("RemoteFunction") and inst.Name == remoteName then
            local parent = inst.Parent
            local skip = false
            if remoteName == "Purchase" then
                local en = parent and parent:GetAttribute("Enabled")
                if en == false then skip = true end
            elseif remoteName == "Upgrade" then
                local hasBoost = (parent and parent:GetAttribute("BoostProductName")) or inst:GetAttribute("BoostProductName")
                if hasBoost then skip = true end
            end
            if not skip then
                local cd = _lemonDenyCooldown[inst]
                if cd and now < cd then skip = true end
            end
            if skip then
                skip_n = skip_n + 1
            else
                local pos = _instPos(parent)
                if pos and rp then
                    pcall(function() rp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)) end)
                    task.wait(0.1)
                end
                local ok, result = _invokeWithTimeout(inst, 3)
                if ok then
                    if result == false or result == nil then
                        -- invoked fine but denied server-side (most likely: can't afford it yet)
                        _lemonDenyCooldown[inst] = now + 8
                        deny_n = deny_n + 1
                    else
                        _lemonDenyCooldown[inst] = nil
                        ok_n = ok_n + 1
                    end
                else
                    fail_n = fail_n + 1
                    firstErr = firstErr or (inst:GetFullName()..": "..tostring(result))
                end
            end
        end
    end
    if rp and origCF then pcall(function() rp.CFrame = origCF end) end
    if ok_n == 0 and fail_n == 0 and skip_n == 0 and deny_n == 0 then
        return 0, 0, 0, 0, "No "..remoteName.." buttons found under "..tycoon.Name..".Purchases"
    end
    return ok_n, fail_n, skip_n, deny_n, firstErr
end

local SELL_LEMONS_PLACEID = 79268393072444

local function SetLemonFarm(e)
    if e and game.PlaceId ~= SELL_LEMONS_PLACEID then
        NotifyError("Lemon Farm","This only works in Sell Lemons",3)
        return
    end
    LemonFarm.Enabled = e
    if LemonFarmConn then pcall(task.cancel, LemonFarmConn); LemonFarmConn = nil end
    if not e then return end
    LemonFarmConn = task.spawn(function()
        while LemonFarm.Enabled do
            local tycoon = GetMyTycoon()
            if tycoon then
                LemonFarm.Status = "Farming: "..tycoon.Name
                if LemonFarm.AutoFruit then pcall(_lemonCollectFruit, tycoon) end
                if LemonFarm.AutoOrchard then pcall(_lemonOrchard, tycoon) end
                if LemonFarm.AutoBuy then
                    local ok_n, fail_n, skip_n, deny_n, err = _lemonRunRemotes(tycoon, "Purchase", false)
                    LemonFarm.LastBuyResult = string.format("Buy: %d bought / %d too expensive / %d locked / %d error%s", ok_n, deny_n, skip_n, fail_n, err and (" | "..err) or "")
                end
                if LemonFarm.AutoUpgrade then
                    local ok_n, fail_n, skip_n, deny_n, err = _lemonRunRemotes(tycoon, "Upgrade", false)
                    LemonFarm.LastUpgradeResult = string.format("Upgrade: %d ok / %d failed / %d paid-boost skipped%s", ok_n, fail_n, skip_n, err and (" | "..err) or "")
                end
            else
                LemonFarm.Status = "Tycoon not found (not claimed yet?)"
            end
            task.wait(LemonFarm.Delay)
        end
    end)
end

local KEYBOARD_UNIVERSE_ID = 9584852943
local TreadmillFarm = {Enabled=false, Target="Treadmill", Status="Not started"}
local TreadmillFarmConn = nil
local TreadmillPurchaseConn1, TreadmillPurchaseConn2 = nil, nil
local _keypress = _getFunc("keypress")
local _keyrelease = _getFunc("keyrelease")
local VK_W, VK_S = 0x57, 0x53
local MarketplaceService = game:GetService("MarketplaceService")

local function _findTreadmill(name)
    local folder = workspace:FindFirstChild("Treadmill")
    if not folder then return nil end
    for _, inst in pairs(folder:GetChildren()) do
        if inst.Name == name and inst:IsA("Model") then
            return inst
        end
    end
    return nil
end

local function SetTreadmillFarm(e)
    if e and game.GameId ~= KEYBOARD_UNIVERSE_ID then
        NotifyError("Speed Farm","This only works in 1 Speed Keyboard Escape",3)
        return
    end
    TreadmillFarm.Enabled = e
    if TreadmillFarmConn then pcall(task.cancel, TreadmillFarmConn); TreadmillFarmConn = nil end
    if TreadmillPurchaseConn1 then TreadmillPurchaseConn1:Disconnect(); TreadmillPurchaseConn1 = nil end
    if TreadmillPurchaseConn2 then TreadmillPurchaseConn2:Disconnect(); TreadmillPurchaseConn2 = nil end
    if not _keypress or not _keyrelease then
        if e then NotifyError("Speed Farm","Executor doesn't support keypress/keyrelease",3) end
        TreadmillFarm.Enabled = false
        return
    end
    if not e then
        pcall(_keyrelease, VK_W); pcall(_keyrelease, VK_S)
        return
    end
    local function onPurchasePrompt()
        if TreadmillFarm.Enabled then
            TreadmillFarm.Status = "Stopped: a real purchase prompt appeared (tier probably not owned)"
            NotifyError("Speed Farm","A Roblox purchase popup appeared — automation stopped automatically. Nothing was bought for you.",6)
            SetTreadmillFarm(false)
        end
    end
    pcall(function() TreadmillPurchaseConn1 = MarketplaceService.PromptProductPurchaseFinished:Connect(onPurchasePrompt) end)
    pcall(function() TreadmillPurchaseConn2 = MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPurchasePrompt) end)
    TreadmillFarmConn = task.spawn(function()
        while TreadmillFarm.Enabled do
            local pad = _findTreadmill(TreadmillFarm.Target)
            if not pad then
                TreadmillFarm.Status = "Treadmill '"..TreadmillFarm.Target.."' not found"
                task.wait(2)
            else
                local c = LocalPlayer.Character
                local rp = c and GetRootPart(c)
                if rp then
                    local padPos = pad:GetPivot().Position
                    local dist = (rp.Position - padPos).Magnitude
                    if dist > 10 then
                        TreadmillFarm.Status = "Walking to "..TreadmillFarm.Target.."..."
                        local hum = c:FindFirstChildOfClass("Humanoid")
                        if hum then
                            pcall(function() hum:MoveTo(padPos) end)
                            local waited = 0
                            while TreadmillFarm.Enabled and waited < 8 do
                                task.wait(0.2)
                                waited = waited + 0.2
                                local rp2 = c and GetRootPart(c)
                                if not rp2 then break end
                                if (rp2.Position - padPos).Magnitude < 10 then break end
                            end
                        else
                            task.wait(0.5)
                        end
                    end
                    if not TreadmillFarm.Enabled then break end
                    TreadmillFarm.Status = "Walking on "..TreadmillFarm.Target
                    pcall(_keypress, VK_W)
                    task.wait(0.35)
                    pcall(_keyrelease, VK_W)
                    task.wait(0.1)
                    pcall(_keypress, VK_S)
                    task.wait(0.35)
                    pcall(_keyrelease, VK_S)
                    task.wait(0.1)
                else
                    task.wait(1)
                end
            end
        end
        pcall(_keyrelease, VK_W); pcall(_keyrelease, VK_S)
    end)
end

local ItemESPObjects = {}
local ItemESPEnabled = false
local ItemESPConn = nil
local ItemESPScanConn = nil
local ITEM_ESP_DEFAULT = {color=Color3.fromRGB(80,220,255), label="ITEM"}
local function _classifyItemName(name)
    local n = name:lower()
    if n:find("gold") then return {color=Color3.fromRGB(255,215,0), label="GOLD KEY"} end
    if n:find("secret") then return {color=Color3.fromRGB(200,80,255), label="SECRET KEY"} end
    return ITEM_ESP_DEFAULT
end
local function _findSpecialKeysFolder()
    for _, inst in pairs(Workspace:GetChildren()) do
        if inst:IsA("Folder") or inst:IsA("Model") then
            local n = inst.Name:lower()
            if n:find("special") and n:find("key") then
                return inst
            end
        end
    end
    return nil
end
local function _createItemESP(inst, info)
    if ItemESPObjects[inst] then return end
    local target = inst
    if inst:IsA("Model") then
        target = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
    end
    if not target then return end
    local ok = pcall(function()
        local hl = Instance.new("Highlight")
        hl.FillColor = info.color; hl.OutlineColor = info.color
        hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = inst
        hl.Parent = target
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0,160,0,36)
        bb.StudsOffset = Vector3.new(0,2,0)
        bb.AlwaysOnTop = true
        bb.Adornee = target
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1
        tl.Font = Enum.Font.GothamBold; tl.TextSize = 13
        tl.TextColor3 = info.color; tl.TextStrokeTransparency = 0
        tl.Text = info.label.." - "..inst.Name
        tl.Parent = bb
        bb.Parent = target
        ItemESPObjects[inst] = {Highlight=hl, Billboard=bb}
    end)
end
local function _removeItemESP(inst)
    local d = ItemESPObjects[inst]
    if not d then return end
    pcall(function() d.Highlight:Destroy() end)
    pcall(function() d.Billboard:Destroy() end)
    ItemESPObjects[inst] = nil
end
local function _scanForItems()
    local folder = _findSpecialKeysFolder()
    if not folder then return 0 end
    local yieldCounter = 0
    for _, obj in pairs(folder:GetDescendants()) do
        if (obj:IsA("BasePart") or obj:IsA("Model")) and not ItemESPObjects[obj] then
            local info = _classifyItemName(obj.Name)
            _createItemESP(obj, info)
        end
        yieldCounter = yieldCounter + 1
        if yieldCounter % 150 == 0 then task.wait() end
    end
    return 1
end
local function SetItemESP(e)
    if e and game.GameId ~= KEYBOARD_UNIVERSE_ID then
        NotifyError("Item ESP","This only works in 1 Speed Keyboard Escape",3)
        return
    end
    ItemESPEnabled = e
    if ItemESPScanConn then pcall(task.cancel, ItemESPScanConn); ItemESPScanConn = nil end
    if ItemESPConn then ItemESPConn:Disconnect(); ItemESPConn = nil end
    if not e then
        for inst in pairs(ItemESPObjects) do _removeItemESP(inst) end
        return
    end
    local folder = _findSpecialKeysFolder()
    if not folder then
        NotifyError("Item ESP","No 'Special Keys' folder found in Workspace right now",4)
        ItemESPEnabled = false
        return
    end
    _scanForItems()
    ItemESPConn = Workspace.DescendantAdded:Connect(function(obj)
        if not ItemESPEnabled then return end
        if not (obj:IsA("BasePart") or obj:IsA("Model")) then return end
        local f = _findSpecialKeysFolder()
        if not f or not obj:IsDescendantOf(f) then return end
        local info = _classifyItemName(obj.Name)
        _createItemESP(obj, info)
    end)
    ItemESPScanConn = task.spawn(function()
        while ItemESPEnabled do
            task.wait(5)
            if ItemESPEnabled then
                _scanForItems()
                for inst in pairs(ItemESPObjects) do
                    if not inst.Parent then _removeItemESP(inst) end
                end
            end
        end
    end)
    local n = 0
    for _ in pairs(ItemESPObjects) do n = n + 1 end
    Notify("Item ESP","ESP'ing everything in '"..folder.Name.."' ("..n.." found so far, updates every 5s)",4)
end
local function _findNearestSpecialKey()
    local folder = _findSpecialKeysFolder()
    if not folder then return nil, nil end
    local c = LocalPlayer.Character
    local rp = c and GetRootPart(c)
    local myPos = rp and rp.Position
    local best, bestDist = nil, math.huge
    for _, obj in pairs(folder:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local target = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)) or obj
            if target then
                local dist = myPos and (target.Position - myPos).Magnitude or 0
                if dist < bestDist then bestDist = dist; best = target end
            end
        end
    end
    return best, bestDist
end
local function TeleportToNearestSpecialKey()
    if game.GameId ~= KEYBOARD_UNIVERSE_ID then
        NotifyError("Item ESP","This only works in 1 Speed Keyboard Escape",3)
        return
    end
    local target, dist = _findNearestSpecialKey()
    if not target then
        NotifyError("Item ESP","No items found in the Special Keys folder right now",4)
        return
    end
    TeleportTo(target.CFrame + Vector3.new(0,3,0))
    Notify("Item ESP","Teleported to "..target.Name.." ("..math.floor(dist).." studs away)",4)
end

_G._Funcs = {
    SetHitboxExpander=SetHitboxExpander, SendChatMessage=SendChatMessage,
    SetChatSpam=SetChatSpam, SetRemoteSpam=SetRemoteSpam, SetToolSpam=SetToolSpam,
    FlingAllPlayers=FlingAllPlayers, GetNearestPlayer=GetNearestPlayer, FEFling=FEFling,
    AnimationsList=AnimationsList, PlayAnimation=PlayAnimation, StopAnimation=StopAnimation,
    FindAllFunctions=FindAllFunctions, GetFunctionNames=GetFunctionNames, ExecuteFunction=ExecuteFunction,
    SoundList=SoundList, PlayFESound=PlayFESound, StopFESound=StopFESound,
    SetNoClip=SetNoClip, SetFullbright=SetFullbright, SetFly=SetFly, TeleportTo=TeleportTo,
    SetCustomSpeed=SetCustomSpeed, CustomSpeed=CustomSpeed,
    SetInfiniteJump=SetInfiniteJump, SetAntiFall=SetAntiFall,
    SetCustomScale=SetCustomScale, UpdateCustomScale=UpdateCustomScale, CustomScale=CustomScale,
    SetRandomRagdoll=SetRandomRagdoll, DoRagdoll=DoRagdoll,
    SetKillAura=SetKillAura, SetGodMode=SetGodMode, SetOneHitKill=SetOneHitKill,
    SetNoReload=SetNoReload, NoReload=NoReload,
    Fullbright=Fullbright, selectedFunction=nil,
    SetFreecam=SetFreecam, FreecamState=FreecamState,
    ClearFreecamBlocks=ClearFreecamBlocks, SetFreecamBlockSize=function(v) FreecamBlockSize=v end,
    ClearFreecamDrawing=ClearFreecamDrawing,
    SetFreecamCornerThickness=function(v) FreecamCornerThickness=v end,
    SetLemonFarm=SetLemonFarm, LemonFarm=LemonFarm, GetMyTycoon=GetMyTycoon, LemonRunRemotes=_lemonRunRemotes,
    SetTreadmillFarm=SetTreadmillFarm, TreadmillFarm=TreadmillFarm,
    SetItemESP=SetItemESP, TeleportToNearestSpecialKey=TeleportToNearestSpecialKey,
    SetMovementRecord=SetMovementRecord, SetMovementPlay=SetMovementPlay, MovementRecorder=MovementRecorder,
    SaveMovementRecordingToFile=SaveMovementRecordingToFile, LoadMovementRecordingFromFile=LoadMovementRecordingFromFile
}
end)()

local ACCENT = Color3.fromRGB(150, 150, 158)
local ACCENT_GLOW = Color3.fromRGB(200, 200, 208)
local ACCENT_DIM = Color3.fromRGB(70, 70, 76)
local ACCENT_SOFT = Color3.fromRGB(110, 110, 118)
local BG_PANEL = Color3.fromRGB(10, 10, 11)
local BG_TAB = Color3.fromRGB(13, 13, 14)
local BG_ROW = Color3.fromRGB(19, 19, 21)
local BG_ROW_HOVER = Color3.fromRGB(28, 28, 31)
local BG_INPUT = Color3.fromRGB(15, 15, 16)
local TEXT_WHITE = Color3.fromRGB(215, 215, 218)
local TEXT_BRIGHT = Color3.fromRGB(250, 250, 252)
local TEXT_DIM = Color3.fromRGB(120, 120, 126)
local TEXT_SECTION = ACCENT
local TOGGLE_OFF = Color3.fromRGB(38, 38, 42)
local TOGGLE_ON = ACCENT
local DIVIDER_COL = Color3.fromRGB(34, 34, 38)
local FONT = Enum.Font.Gotham
local FONT_BOLD = Enum.Font.GothamBold
local FONT_MED = Enum.Font.GothamMedium
local FONT_SEMI = Enum.Font.GothamSemibold

;(function()
ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScreenGui"..tostring(math.random(10000,99999)); ScreenGui.ResetOnSpawn = false; ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; ScreenGui.DisplayOrder = 999; ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
_G._PhazeScreenGui = ScreenGui

local LoadingScreen=Instance.new("Frame"); LoadingScreen.Name="LoadingScreen"; LoadingScreen.Size=UDim2.new(1,0,1,0); LoadingScreen.BackgroundColor3=Color3.fromRGB(8,8,9); LoadingScreen.BackgroundTransparency=0; LoadingScreen.BorderSizePixel=0; LoadingScreen.ZIndex=1000; LoadingScreen.Parent=ScreenGui
local LoadingGrad=Instance.new("UIGradient",LoadingScreen); LoadingGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(12,12,14)),ColorSequenceKeypoint.new(1,Color3.fromRGB(6,6,7))}); LoadingGrad.Rotation=90

local LoadAvatarRing=Instance.new("Frame",LoadingScreen); LoadAvatarRing.Size=UDim2.new(0,96,0,96); LoadAvatarRing.AnchorPoint=Vector2.new(0.5,0.5); LoadAvatarRing.Position=UDim2.new(0.5,0,0.5,-70); LoadAvatarRing.BackgroundColor3=Color3.fromRGB(18,18,20); LoadAvatarRing.BorderSizePixel=0; LoadAvatarRing.ZIndex=1001
Instance.new("UICorner",LoadAvatarRing).CornerRadius=UDim.new(1,0)
local LoadAvatarStroke=Instance.new("UIStroke",LoadAvatarRing); LoadAvatarStroke.Color=ACCENT; LoadAvatarStroke.Thickness=2; LoadAvatarStroke.Transparency=0.15
local LoadAvatarImg=Instance.new("ImageLabel",LoadAvatarRing); LoadAvatarImg.Size=UDim2.new(1,-8,1,-8); LoadAvatarImg.AnchorPoint=Vector2.new(0.5,0.5); LoadAvatarImg.Position=UDim2.new(0.5,0,0.5,0); LoadAvatarImg.BackgroundTransparency=1; LoadAvatarImg.Image=""; LoadAvatarImg.ScaleType=Enum.ScaleType.Fit; LoadAvatarImg.ZIndex=1002
Instance.new("UICorner",LoadAvatarImg).CornerRadius=UDim.new(1,0)

local LoadTitle=Instance.new("TextLabel",LoadingScreen); LoadTitle.Size=UDim2.new(0,300,0,26); LoadTitle.AnchorPoint=Vector2.new(0.5,0.5); LoadTitle.Position=UDim2.new(0.5,0,0.5,-10); LoadTitle.BackgroundTransparency=1; LoadTitle.Text="PHAZE"; LoadTitle.Font=FONT_BOLD; LoadTitle.TextSize=22; LoadTitle.TextColor3=TEXT_BRIGHT; LoadTitle.ZIndex=1001
local LoadName=Instance.new("TextLabel",LoadingScreen); LoadName.Size=UDim2.new(0,300,0,16); LoadName.AnchorPoint=Vector2.new(0.5,0.5); LoadName.Position=UDim2.new(0.5,0,0.5,14); LoadName.BackgroundTransparency=1; LoadName.Text=LocalPlayer.DisplayName.." (@"..LocalPlayer.Name..")"; LoadName.Font=FONT_MED; LoadName.TextSize=12; LoadName.TextColor3=TEXT_DIM; LoadName.ZIndex=1001

local LoadBarBg=Instance.new("Frame",LoadingScreen); LoadBarBg.Size=UDim2.new(0,220,0,4); LoadBarBg.AnchorPoint=Vector2.new(0.5,0.5); LoadBarBg.Position=UDim2.new(0.5,0,0.5,42); LoadBarBg.BackgroundColor3=Color3.fromRGB(28,28,31); LoadBarBg.BorderSizePixel=0; LoadBarBg.ZIndex=1001
Instance.new("UICorner",LoadBarBg).CornerRadius=UDim.new(1,0)
local LoadBarFill=Instance.new("Frame",LoadBarBg); LoadBarFill.Size=UDim2.new(0,0,1,0); LoadBarFill.BackgroundColor3=ACCENT_GLOW; LoadBarFill.BorderSizePixel=0; LoadBarFill.ZIndex=1002
Instance.new("UICorner",LoadBarFill).CornerRadius=UDim.new(1,0)

local LoadStatus=Instance.new("TextLabel",LoadingScreen); LoadStatus.Size=UDim2.new(0,300,0,14); LoadStatus.AnchorPoint=Vector2.new(0.5,0.5); LoadStatus.Position=UDim2.new(0.5,0,0.5,64); LoadStatus.BackgroundTransparency=1; LoadStatus.Text="Loading..."; LoadStatus.Font=FONT; LoadStatus.TextSize=11; LoadStatus.TextColor3=TEXT_DIM; LoadStatus.ZIndex=1001

TweenService:Create(LoadBarFill,TweenInfo.new(0.6,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,90,1,0)}):Play()

task.spawn(function()
    local ok, content = pcall(function()
        local c, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        return c
    end)
    if ok and content then LoadAvatarImg.Image = content end
end)

local NotifHolder = Instance.new("Frame"); NotifHolder.Size=UDim2.new(0,220,1,0); NotifHolder.Position=UDim2.new(1,-230,0,0); NotifHolder.BackgroundTransparency=1; NotifHolder.Parent=ScreenGui
local NL=Instance.new("UIListLayout",NotifHolder); NL.SortOrder=Enum.SortOrder.LayoutOrder; NL.Padding=UDim.new(0,4); NL.VerticalAlignment=Enum.VerticalAlignment.Top
Instance.new("UIPadding",NotifHolder).PaddingTop=UDim.new(0,10)

Notify = function(title,content,dur,isError)
    dur=dur or 3
    local accentCol = isError and Color3.fromRGB(235,80,80) or ACCENT_GLOW
    local titleCol = isError and Color3.fromRGB(240,100,100) or TEXT_BRIGHT
    local n=Instance.new("Frame"); n.Size=UDim2.new(1,0,0,0); n.AutomaticSize=Enum.AutomaticSize.Y; n.BackgroundColor3=Color3.fromRGB(11,11,12); n.BorderSizePixel=0; n.BackgroundTransparency=1; n.ClipsDescendants=true; n.Parent=NotifHolder
    Instance.new("UICorner",n).CornerRadius=UDim.new(0,8)
    local stroke=Instance.new("UIStroke",n); stroke.Color=isError and Color3.fromRGB(90,40,40) or Color3.fromRGB(50,50,54); stroke.Thickness=1; stroke.Transparency=0.35
    local pad=Instance.new("UIPadding",n); pad.PaddingTop=UDim.new(0,7); pad.PaddingBottom=UDim.new(0,9); pad.PaddingLeft=UDim.new(0,9); pad.PaddingRight=UDim.new(0,9)
    local tl=Instance.new("TextLabel",n); tl.Size=UDim2.new(1,0,0,12); tl.BackgroundTransparency=1; tl.Text=(isError and "! " or "")..string.upper(title); tl.Font=FONT_BOLD; tl.TextSize=9; tl.TextColor3=titleCol; tl.TextXAlignment=Enum.TextXAlignment.Left
    local cl=Instance.new("TextLabel",n); cl.Size=UDim2.new(1,0,0,0); cl.AutomaticSize=Enum.AutomaticSize.Y; cl.Position=UDim2.new(0,0,0,13); cl.BackgroundTransparency=1; cl.Text=content; cl.Font=FONT; cl.TextSize=10; cl.TextColor3=TEXT_DIM; cl.TextXAlignment=Enum.TextXAlignment.Left; cl.TextWrapped=true
    local timerBg=Instance.new("Frame",n); timerBg.Size=UDim2.new(1,4,0,2); timerBg.Position=UDim2.new(0,-2,1,4); timerBg.BackgroundColor3=Color3.fromRGB(26,26,28); timerBg.BorderSizePixel=0
    local timerFill=Instance.new("Frame",timerBg); timerFill.Size=UDim2.new(1,0,1,0); timerFill.BackgroundColor3=accentCol; timerFill.BorderSizePixel=0
    TweenService:Create(n,TweenInfo.new(0.35,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundTransparency=0.06}):Play()
    TweenService:Create(timerFill,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,1,0)}):Play()
    task.delay(dur,function() TweenService:Create(n,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play(); task.wait(0.3); n:Destroy() end)
end

NotifyError = function(title,content,dur)
    Notify(title,content,dur or 4,true)
end

local SIDEBAR_W = 152
local TOPBAR_H = 44
local STATUSBAR_H = 24

Panel = Instance.new("Frame"); Panel.Name="Panel"; Panel.Size=UDim2.new(0,560,0,440); Panel.Position=UDim2.new(0.5,-280,0.5,-220); Panel.BackgroundColor3=BG_PANEL; Panel.BackgroundTransparency=0.04; Panel.BorderSizePixel=0; Panel.ClipsDescendants=true; Panel.Parent=ScreenGui; Panel.Visible=false
Instance.new("UICorner",Panel).CornerRadius=UDim.new(0,14)
local PS=Instance.new("UIStroke",Panel); PS.Color=Color3.fromRGB(46,46,50); PS.Thickness=1; PS.Transparency=0.25
local Glow=Instance.new("ImageLabel"); Glow.Size=UDim2.new(1,90,1,90); Glow.Position=UDim2.new(0,-45,0,-45); Glow.BackgroundTransparency=1; Glow.Image="rbxassetid://6014261993"; Glow.ImageColor3=Color3.fromRGB(60,60,64); Glow.ImageTransparency=0.82; Glow.ScaleType=Enum.ScaleType.Slice; Glow.SliceCenter=Rect.new(49,49,450,450); Glow.ZIndex=-1; Glow.Parent=Panel

local TopBar=Instance.new("Frame"); TopBar.Name="TopBar"; TopBar.Size=UDim2.new(1,0,0,TOPBAR_H); TopBar.BackgroundColor3=Color3.fromRGB(13,13,14); TopBar.BackgroundTransparency=0; TopBar.BorderSizePixel=0; TopBar.Parent=Panel
local TopBarGrad=Instance.new("UIGradient",TopBar); TopBarGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(20,20,22)),ColorSequenceKeypoint.new(1,Color3.fromRGB(13,13,14))}); TopBarGrad.Rotation=90

local LogoDot=Instance.new("Frame",TopBar); LogoDot.Size=UDim2.new(0,26,0,26); LogoDot.Position=UDim2.new(0,14,0.5,-13); LogoDot.BackgroundColor3=Color3.fromRGB(30,30,33); LogoDot.BorderSizePixel=0; LogoDot.ClipsDescendants=true; Instance.new("UICorner",LogoDot).CornerRadius=UDim.new(0,8)
local LogoDotStroke=Instance.new("UIStroke",LogoDot); LogoDotStroke.Color=Color3.fromRGB(70,70,75); LogoDotStroke.Thickness=1; LogoDotStroke.Transparency=0.3
local LogoImg=Instance.new("ImageLabel",LogoDot); LogoImg.Size=UDim2.new(1,0,1,0); LogoImg.BackgroundTransparency=1; LogoImg.BorderSizePixel=0; LogoImg.ScaleType=Enum.ScaleType.Fit
local LogoLbl=Instance.new("TextLabel",LogoDot); LogoLbl.Size=UDim2.new(1,0,1,0); LogoLbl.BackgroundTransparency=1; LogoLbl.Text="P"; LogoLbl.Font=FONT_BOLD; LogoLbl.TextSize=14; LogoLbl.TextColor3=TEXT_BRIGHT
local _logoUrl = "https://github.com/Mtokyo/trigger1/blob/main/phaze-logo-9eKZTHF8.png?raw=true"
local _getcustomasset = _getFunc("getcustomasset") or _getFunc("getsynasset")
if _getcustomasset then
    task.spawn(function() pcall(function()
        local _request = _getFunc("request") or _getFunc("http_request") or _getFunc("syn.request") or (syn and syn.request) or http_request or request
        if _request then
            local resp = _request({Url=_logoUrl, Method="GET"})
            if resp and resp.Body then
                writefile("phaze_logo.png", resp.Body)
                LogoImg.Image = _getcustomasset("phaze_logo.png")
                if LogoImg.Image ~= "" then LogoLbl.Visible = false end
            end
        end
    end) end)
end

local BT=Instance.new("TextLabel",TopBar); BT.Size=UDim2.new(0,140,0,16); BT.Position=UDim2.new(0,50,0,10); BT.BackgroundTransparency=1; BT.Text="PHAZE"; BT.Font=FONT_BOLD; BT.TextSize=15; BT.TextColor3=TEXT_BRIGHT; BT.TextXAlignment=Enum.TextXAlignment.Left
local BSub=Instance.new("TextLabel",TopBar); BSub.Size=UDim2.new(0,140,0,12); BSub.Position=UDim2.new(0,50,0,24); BSub.BackgroundTransparency=1; BSub.Text="PRIVATE BUILD"; BSub.Font=FONT; BSub.TextSize=8; BSub.TextColor3=TEXT_DIM; BSub.TextXAlignment=Enum.TextXAlignment.Left

local CloseBtn=Instance.new("TextButton",TopBar); CloseBtn.Size=UDim2.new(0,28,0,28); CloseBtn.Position=UDim2.new(1,-38,0.5,-14); CloseBtn.BackgroundColor3=Color3.fromRGB(24,24,26); CloseBtn.BackgroundTransparency=0.2; CloseBtn.BorderSizePixel=0; CloseBtn.Text="X"; CloseBtn.Font=FONT_BOLD; CloseBtn.TextSize=12; CloseBtn.TextColor3=TEXT_DIM
Instance.new("UICorner",CloseBtn).CornerRadius=UDim.new(0,7)
CloseBtn.MouseEnter:Connect(function() TweenService:Create(CloseBtn,TweenInfo.new(0.15),{BackgroundTransparency=0,BackgroundColor3=Color3.fromRGB(60,26,26),TextColor3=Color3.fromRGB(235,120,120)}):Play() end)
CloseBtn.MouseLeave:Connect(function() TweenService:Create(CloseBtn,TweenInfo.new(0.15),{BackgroundTransparency=0.2,BackgroundColor3=Color3.fromRGB(24,24,26),TextColor3=TEXT_DIM}):Play() end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local MinBtn=Instance.new("TextButton",TopBar); MinBtn.Size=UDim2.new(0,28,0,28); MinBtn.Position=UDim2.new(1,-70,0.5,-14); MinBtn.BackgroundColor3=Color3.fromRGB(24,24,26); MinBtn.BackgroundTransparency=0.2; MinBtn.BorderSizePixel=0; MinBtn.Text="—"; MinBtn.Font=FONT_BOLD; MinBtn.TextSize=12; MinBtn.TextColor3=TEXT_DIM
Instance.new("UICorner",MinBtn).CornerRadius=UDim.new(0,7)
MinBtn.MouseEnter:Connect(function() TweenService:Create(MinBtn,TweenInfo.new(0.15),{BackgroundTransparency=0,BackgroundColor3=BG_ROW_HOVER,TextColor3=TEXT_BRIGHT}):Play() end)
MinBtn.MouseLeave:Connect(function() TweenService:Create(MinBtn,TweenInfo.new(0.15),{BackgroundTransparency=0.2,BackgroundColor3=Color3.fromRGB(24,24,26),TextColor3=TEXT_DIM}):Play() end)

local TopBarLine=Instance.new("Frame",TopBar); TopBarLine.Size=UDim2.new(1,0,0,1); TopBarLine.Position=UDim2.new(0,0,1,-1); TopBarLine.BackgroundColor3=DIVIDER_COL; TopBarLine.BackgroundTransparency=0.2; TopBarLine.BorderSizePixel=0

local Body=Instance.new("Frame"); Body.Size=UDim2.new(1,0,1,-TOPBAR_H-STATUSBAR_H); Body.Position=UDim2.new(0,0,0,TOPBAR_H); Body.BackgroundTransparency=1; Body.BorderSizePixel=0; Body.Parent=Panel

local Sidebar=Instance.new("Frame"); Sidebar.Name="Sidebar"; Sidebar.Size=UDim2.new(0,SIDEBAR_W,1,0); Sidebar.BackgroundColor3=BG_TAB; Sidebar.BackgroundTransparency=0.1; Sidebar.BorderSizePixel=0; Sidebar.Parent=Body
local SidebarLine=Instance.new("Frame",Sidebar); SidebarLine.Size=UDim2.new(0,1,1,0); SidebarLine.Position=UDim2.new(1,-1,0,0); SidebarLine.BackgroundColor3=DIVIDER_COL; SidebarLine.BackgroundTransparency=0.2; SidebarLine.BorderSizePixel=0
local SearchBox=Instance.new("TextBox",Sidebar); SearchBox.Size=UDim2.new(1,-16,0,26); SearchBox.Position=UDim2.new(0,8,0,6); SearchBox.BackgroundColor3=BG_INPUT; SearchBox.BorderSizePixel=0; SearchBox.PlaceholderText="Search..."; SearchBox.PlaceholderColor3=Color3.fromRGB(70,70,80); SearchBox.Text=""; SearchBox.Font=FONT; SearchBox.TextSize=11; SearchBox.TextColor3=TEXT_BRIGHT; SearchBox.ClearTextOnFocus=false
Instance.new("UICorner",SearchBox).CornerRadius=UDim.new(0,6)
local SearchStroke=Instance.new("UIStroke",SearchBox); SearchStroke.Color=DIVIDER_COL; SearchStroke.Thickness=1; SearchStroke.Transparency=0.3
Instance.new("UIPadding",SearchBox).PaddingLeft=UDim.new(0,8)
SearchBox.Focused:Connect(function() TweenService:Create(SearchStroke,TweenInfo.new(0.15),{Color=ACCENT}):Play() end)
SearchBox.FocusLost:Connect(function() TweenService:Create(SearchStroke,TweenInfo.new(0.15),{Color=DIVIDER_COL}):Play() end)
local CatScroll=Instance.new("ScrollingFrame",Sidebar); CatScroll.Size=UDim2.new(1,0,1,-38); CatScroll.Position=UDim2.new(0,0,0,38); CatScroll.BackgroundTransparency=1; CatScroll.BorderSizePixel=0; CatScroll.ScrollBarThickness=2; CatScroll.ScrollBarImageColor3=Color3.fromRGB(60,60,64); CatScroll.CanvasSize=UDim2.new(0,0,0,0); CatScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; CatScroll.ScrollingDirection=Enum.ScrollingDirection.Y
local CatLayout=Instance.new("UIListLayout",CatScroll); CatLayout.FillDirection=Enum.FillDirection.Vertical; CatLayout.SortOrder=Enum.SortOrder.LayoutOrder; CatLayout.Padding=UDim.new(0,3)
Instance.new("UIPadding",CatScroll).PaddingLeft=UDim.new(0,8); CatScroll.UIPadding.PaddingRight=UDim.new(0,8)

local ContentArea=Instance.new("Frame"); ContentArea.Size=UDim2.new(1,-SIDEBAR_W,1,0); ContentArea.Position=UDim2.new(0,SIDEBAR_W,0,0); ContentArea.BackgroundColor3=BG_PANEL; ContentArea.BackgroundTransparency=0.2; ContentArea.BorderSizePixel=0; ContentArea.Parent=Body

local ContentHeader=Instance.new("Frame"); ContentHeader.Size=UDim2.new(1,0,0,34); ContentHeader.BackgroundTransparency=1; ContentHeader.Parent=ContentArea
local ContentTitle=Instance.new("TextLabel",ContentHeader); ContentTitle.Size=UDim2.new(1,-20,1,0); ContentTitle.Position=UDim2.new(0,16,0,0); ContentTitle.BackgroundTransparency=1; ContentTitle.Text=""; ContentTitle.Font=FONT_BOLD; ContentTitle.TextSize=13; ContentTitle.TextColor3=TEXT_BRIGHT; ContentTitle.TextXAlignment=Enum.TextXAlignment.Left
local ContentHeaderLine=Instance.new("Frame",ContentHeader); ContentHeaderLine.Size=UDim2.new(1,-16,0,1); ContentHeaderLine.Position=UDim2.new(0,16,1,-1); ContentHeaderLine.BackgroundColor3=DIVIDER_COL; ContentHeaderLine.BackgroundTransparency=0.3; ContentHeaderLine.BorderSizePixel=0

local TabContent=Instance.new("ScrollingFrame"); TabContent.Name="Content"; TabContent.Size=UDim2.new(1,-8,1,-34); TabContent.Position=UDim2.new(0,8,0,34); TabContent.BackgroundTransparency=1; TabContent.BorderSizePixel=0; TabContent.ScrollBarThickness=2; TabContent.ScrollBarImageColor3=Color3.fromRGB(60,60,64); TabContent.CanvasSize=UDim2.new(0,0,0,0); TabContent.AutomaticCanvasSize=Enum.AutomaticSize.Y; TabContent.Parent=ContentArea
local ContentLayout=Instance.new("UIListLayout",TabContent); ContentLayout.SortOrder=Enum.SortOrder.LayoutOrder; ContentLayout.Padding=UDim.new(0,6)
Instance.new("UIPadding",TabContent).PaddingTop=UDim.new(0,8); TabContent.UIPadding.PaddingBottom=UDim.new(0,12)

local StatusBar=Instance.new("Frame"); StatusBar.Size=UDim2.new(1,0,0,STATUSBAR_H); StatusBar.Position=UDim2.new(0,0,1,-STATUSBAR_H); StatusBar.BackgroundColor3=Color3.fromRGB(13,13,14); StatusBar.BackgroundTransparency=0; StatusBar.BorderSizePixel=0; StatusBar.Parent=Panel
local StatusLine=Instance.new("Frame",StatusBar); StatusLine.Size=UDim2.new(1,0,0,1); StatusLine.Position=UDim2.new(0,0,0,0); StatusLine.BackgroundColor3=DIVIDER_COL; StatusLine.BackgroundTransparency=0.2; StatusLine.BorderSizePixel=0
local StatusDot=Instance.new("Frame",StatusBar); StatusDot.Size=UDim2.new(0,5,0,5); StatusDot.Position=UDim2.new(0,12,0.5,-2); StatusDot.BackgroundColor3=Color3.fromRGB(90,220,130); StatusDot.BorderSizePixel=0; Instance.new("UICorner",StatusDot).CornerRadius=UDim.new(1,0)
local StatusLeft=Instance.new("TextLabel",StatusBar); StatusLeft.Size=UDim2.new(0.55,0,1,0); StatusLeft.Position=UDim2.new(0,22,0,0); StatusLeft.BackgroundTransparency=1; StatusLeft.Text="K: Menu"; StatusLeft.Font=FONT; StatusLeft.TextSize=9; StatusLeft.TextColor3=TEXT_DIM; StatusLeft.TextXAlignment=Enum.TextXAlignment.Left
local StatusRight=Instance.new("TextLabel",StatusBar); StatusRight.Size=UDim2.new(0.4,-10,1,0); StatusRight.Position=UDim2.new(0.6,0,0,0); StatusRight.BackgroundTransparency=1; StatusRight.Text=""; StatusRight.Font=FONT; StatusRight.TextSize=9; StatusRight.TextColor3=TEXT_DIM; StatusRight.TextXAlignment=Enum.TextXAlignment.Right
task.spawn(function()
    while Panel.Parent do
        StatusRight.Text = #Players:GetPlayers().." players | "..math.floor(1/RunService.RenderStepped:Wait()).." fps"
        local parts = {"K: Menu"}
        local nc = KeybindStates["Player:NoClip Keybind"]; if nc and nc~="None" then table.insert(parts, nc..": Clip") end
        local fk = KeybindStates["Player:Fly Keybind"]; if fk and fk~="None" then table.insert(parts, fk..": Fly") end
        local fc = KeybindStates["Player:Freecam Keybind"]; if fc and fc~="None" then table.insert(parts, fc..": Cam") end
        StatusLeft.Text = table.concat(parts, "  |  ")
        task.wait(2)
    end
end)

local dragging,dragInput,dragStart,startPos
TopBar.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=true; dragStart=inp.Position; startPos=Panel.Position; inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
TopBar.InputChanged:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then dragInput=inp end end)
UserInputService.InputChanged:Connect(function(inp) if inp==dragInput and dragging then local d=inp.Position-dragStart; Panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)

local guiVisible=true
UserInputService.InputBegan:Connect(function(inp,gpe) if gpe then return end; if inp.KeyCode==Enum.KeyCode.K then guiVisible=not guiVisible; Panel.Visible=guiVisible end end)

task.spawn(function()
    task.wait(1.1)
    LoadStatus.Text="Ready"
    TweenService:Create(LoadBarFill,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(1,0,1,0)}):Play()
    task.wait(0.25)
    Panel.Visible=true
    TweenService:Create(LoadingScreen,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
    for _,d in pairs(LoadingScreen:GetDescendants()) do
        if d:IsA("TextLabel") then TweenService:Create(d,TweenInfo.new(0.3),{TextTransparency=1}):Play()
        elseif d:IsA("ImageLabel") then TweenService:Create(d,TweenInfo.new(0.3),{ImageTransparency=1}):Play()
        elseif d:IsA("UIStroke") then TweenService:Create(d,TweenInfo.new(0.3),{Transparency=1}):Play()
        elseif d:IsA("Frame") then TweenService:Create(d,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play() end
    end
    task.wait(0.4)
    LoadingScreen:Destroy()
end)

ActiveCat=nil; local CatButtons={}; local CatLabels={}; local CatIndicators={}; local CatPages={}

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = SearchBox.Text:lower()
    for name,btn in pairs(CatButtons) do
        btn.Visible = (q=="" or name:lower():find(q,1,true)~=nil)
    end
end)

local PanelFullSize = Panel.Size
local minimized = false
local ResizeHandle
local function SetMinimized(v)
    if minimized == v then return end
    minimized = v
    if ResizeHandle then ResizeHandle.Visible = not v end
    if v then
        TweenService:Create(Panel,TweenInfo.new(0.22,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Size=UDim2.new(PanelFullSize.X.Scale,PanelFullSize.X.Offset,0,TOPBAR_H)}):Play()
        TweenService:Create(MinBtn,TweenInfo.new(0.2),{Rotation=180}):Play()
    else
        TweenService:Create(Panel,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=PanelFullSize}):Play()
        TweenService:Create(MinBtn,TweenInfo.new(0.2),{Rotation=0}):Play()
    end
end
MinBtn.MouseButton1Click:Connect(function() SetMinimized(not minimized) end)

ResizeHandle=Instance.new("TextButton",Panel); ResizeHandle.Size=UDim2.new(0,18,0,18); ResizeHandle.Position=UDim2.new(1,-18,1,-18); ResizeHandle.BackgroundTransparency=1; ResizeHandle.Text=""; ResizeHandle.ZIndex=10; ResizeHandle.AutoButtonColor=false
local ResizeIcon=Instance.new("TextLabel",ResizeHandle); ResizeIcon.Size=UDim2.new(1,0,1,0); ResizeIcon.BackgroundTransparency=1; ResizeIcon.Text="⋰"; ResizeIcon.Font=FONT_BOLD; ResizeIcon.TextSize=16; ResizeIcon.TextColor3=TEXT_DIM; ResizeIcon.ZIndex=10
ResizeHandle.MouseEnter:Connect(function() TweenService:Create(ResizeIcon,TweenInfo.new(0.12),{TextColor3=ACCENT_GLOW}):Play() end)
ResizeHandle.MouseLeave:Connect(function() TweenService:Create(ResizeIcon,TweenInfo.new(0.12),{TextColor3=TEXT_DIM}):Play() end)
local resizing,resizeStart,resizeSizeStart=false,nil,nil
ResizeHandle.InputBegan:Connect(function(inp)
    if minimized then return end
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
        resizing=true; resizeStart=inp.Position; resizeSizeStart=Panel.Size
        inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then resizing=false end end)
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if resizing and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
        local d=inp.Position-resizeStart
        local newW=math.clamp(resizeSizeStart.X.Offset+d.X,420,900)
        local newH=math.clamp(resizeSizeStart.Y.Offset+d.Y,300,700)
        Panel.Size=UDim2.new(0,newW,0,newH)
        PanelFullSize=Panel.Size
    end
end)
ToggleRegistry = {}
ToggleStates = {}
SliderStates = {}
DropdownStates = {}
KeybindStates = {}
KeybindRegistry = {}
KeybindActions = {}
local function ClearContent() for _,ch in pairs(TabContent:GetChildren()) do if ch:IsA("Frame") or ch:IsA("TextButton") then ch:Destroy() end end end
function RenderCategory(catName)
    if ActiveCat==catName then return end; ActiveCat=catName; ClearContent()
    ContentTitle.Text = string.upper(catName)
    for name,btn in pairs(CatButtons) do
        local ind = CatIndicators[name]
        local lbl = CatLabels[name]
        if name==catName then
            TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundTransparency=0.55,BackgroundColor3=BG_ROW_HOVER}):Play()
            if lbl then TweenService:Create(lbl,TweenInfo.new(0.2),{TextColor3=TEXT_BRIGHT}):Play() end
            if ind then TweenService:Create(ind,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{Size=UDim2.new(0,2,0,16),BackgroundTransparency=0}):Play() end
        else
            TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundTransparency=1}):Play()
            if lbl then TweenService:Create(lbl,TweenInfo.new(0.2),{TextColor3=TEXT_DIM}):Play() end
            if ind then TweenService:Create(ind,TweenInfo.new(0.15),{Size=UDim2.new(0,2,0,0),BackgroundTransparency=1}):Play() end
        end
    end
    for i,item in ipairs(CatPages[catName] or {}) do item.Build(TabContent,i) end
    TabContent.CanvasPosition=Vector2.new(0,0)
end

function AddCategory(catName,order)
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,0,0,32); btn.BackgroundColor3=BG_ROW_HOVER; btn.BackgroundTransparency=1; btn.BorderSizePixel=0; btn.Text=""; btn.LayoutOrder=order or 0; btn.Parent=CatScroll
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,7)
    local indicator=Instance.new("Frame",btn); indicator.Size=UDim2.new(0,2,0,0); indicator.Position=UDim2.new(0,0,0.5,0); indicator.AnchorPoint=Vector2.new(0,0.5); indicator.BackgroundColor3=TEXT_BRIGHT; indicator.BackgroundTransparency=1; indicator.BorderSizePixel=0
    Instance.new("UICorner",indicator).CornerRadius=UDim.new(1,0)
    local lbl=Instance.new("TextLabel",btn); lbl.Size=UDim2.new(1,-16,1,0); lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1; lbl.Text=catName; lbl.Font=FONT_MED; lbl.TextSize=12; lbl.TextColor3=TEXT_DIM; lbl.TextXAlignment=Enum.TextXAlignment.Left
    CatButtons[catName]=btn; CatLabels[catName]=lbl; CatIndicators[catName]=indicator; CatPages[catName]={}
    btn.MouseEnter:Connect(function() if ActiveCat~=catName then TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundTransparency=0.5}):Play(); TweenService:Create(lbl,TweenInfo.new(0.12),{TextColor3=TEXT_WHITE}):Play() end end)
    btn.MouseLeave:Connect(function() if ActiveCat~=catName then TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundTransparency=1}):Play(); TweenService:Create(lbl,TweenInfo.new(0.12),{TextColor3=TEXT_DIM}):Play() end end)
    btn.MouseButton1Click:Connect(function() RenderCategory(catName) end)
    local api={}

    function api:AddSection(sectionName)
        table.insert(CatPages[catName],{Build=function(parent,idx)
            local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,28); row.BackgroundColor3=Color3.fromRGB(10,10,12); row.BackgroundTransparency=0.3; row.BorderSizePixel=0; row.LayoutOrder=idx; row.Parent=parent
            local accentBar=Instance.new("Frame",row); accentBar.Size=UDim2.new(0,3,0,12); accentBar.Position=UDim2.new(0,8,0.5,-6); accentBar.BackgroundColor3=ACCENT; accentBar.BorderSizePixel=0; Instance.new("UICorner",accentBar).CornerRadius=UDim.new(0,2)
            local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-24,1,0); lbl.Position=UDim2.new(0,18,0,1); lbl.BackgroundTransparency=1; lbl.Text=string.upper(sectionName); lbl.Font=FONT_BOLD; lbl.TextSize=10; lbl.TextColor3=ACCENT_GLOW; lbl.TextXAlignment=Enum.TextXAlignment.Left
            local line=Instance.new("Frame",row); line.Size=UDim2.new(1,-16,0,1); line.Position=UDim2.new(0,8,1,-1); line.BackgroundColor3=ACCENT_DIM; line.BackgroundTransparency=0.5; line.BorderSizePixel=0
        end})
    end

    function api:AddToggle(label,default,callback)
        local toggleKey = catName..":"..label
        if ToggleStates[toggleKey] == nil then ToggleStates[toggleKey] = default or false end
        table.insert(CatPages[catName],{Build=function(parent,idx)
            local state = ToggleStates[toggleKey]
            local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,32); row.BackgroundColor3=BG_ROW; row.BackgroundTransparency=0.4; row.BorderSizePixel=0; row.LayoutOrder=idx; row.Parent=parent
            Instance.new("UICorner",row).CornerRadius=UDim.new(0,4)
            local leftBar=Instance.new("Frame",row); leftBar.Size=UDim2.new(0,2,0,16); leftBar.Position=UDim2.new(0,4,0.5,-8); leftBar.BackgroundColor3=state and ACCENT or TOGGLE_OFF; leftBar.BorderSizePixel=0; Instance.new("UICorner",leftBar).CornerRadius=UDim.new(0,1)
            local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-80,1,0); lbl.Position=UDim2.new(0,14,0,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.Font=FONT_MED; lbl.TextSize=12; lbl.TextColor3=TEXT_WHITE; lbl.TextXAlignment=Enum.TextXAlignment.Left
            local pill=Instance.new("Frame",row); pill.Size=UDim2.new(0,36,0,18); pill.Position=UDim2.new(1,-48,0.5,-9); pill.BackgroundColor3=state and ACCENT or TOGGLE_OFF; pill.BorderSizePixel=0; Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
            local circle=Instance.new("Frame",pill); circle.Size=UDim2.new(0,14,0,14); circle.Position=state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7); circle.BackgroundColor3=TEXT_BRIGHT; circle.BorderSizePixel=0; Instance.new("UICorner",circle).CornerRadius=UDim.new(1,0)
            local cb=Instance.new("TextButton",row); cb.Size=UDim2.new(1,0,1,0); cb.BackgroundTransparency=1; cb.Text=""
            local div=Instance.new("Frame",row); div.Size=UDim2.new(1,-16,0,1); div.Position=UDim2.new(0,8,1,-1); div.BackgroundColor3=DIVIDER_COL; div.BackgroundTransparency=0.6; div.BorderSizePixel=0
            cb.MouseEnter:Connect(function() TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=BG_ROW_HOVER,BackgroundTransparency=0.2}):Play(); TweenService:Create(lbl,TweenInfo.new(0.15),{TextColor3=TEXT_BRIGHT}):Play() end)
            cb.MouseLeave:Connect(function() TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=BG_ROW,BackgroundTransparency=0.4}):Play(); TweenService:Create(lbl,TweenInfo.new(0.15),{TextColor3=TEXT_WHITE}):Play() end)

            local function setVisual(val)
                state = val
                ToggleStates[toggleKey] = val
                TweenService:Create(pill,TweenInfo.new(0.2),{BackgroundColor3=state and ACCENT or TOGGLE_OFF}):Play()
                TweenService:Create(circle,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}):Play()
                TweenService:Create(leftBar,TweenInfo.new(0.2),{BackgroundColor3=state and ACCENT or TOGGLE_OFF}):Play()
            end

            cb.MouseButton1Click:Connect(function()
                state=not state
                ToggleStates[toggleKey] = state
                setVisual(state)
                if callback then callback(state) end
            end)

            ToggleRegistry[toggleKey] = {SetVisual=setVisual, pill=pill, circle=circle}
        end})
    end

    function api:AddSlider(label,min,max,default,increment,suffix,callback)
        suffix=suffix or ""
        local sliderKey = catName..":"..label
        if SliderStates[sliderKey] == nil then SliderStates[sliderKey] = default or min end
        table.insert(CatPages[catName],{Build=function(parent,idx)
            local value = SliderStates[sliderKey] or default or min or 0
            if type(value) ~= "number" then value = min or 0 end
            if type(min) ~= "number" then min = 0 end
            if type(max) ~= "number" then max = 100 end
            local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=BG_ROW; row.BackgroundTransparency=0.4; row.BorderSizePixel=0; row.LayoutOrder=idx; row.Parent=parent
            Instance.new("UICorner",row).CornerRadius=UDim.new(0,4)
            local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0.4,-10,1,0); lbl.Position=UDim2.new(0,14,0,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.Font=FONT_MED; lbl.TextSize=12; lbl.TextColor3=TEXT_WHITE; lbl.TextXAlignment=Enum.TextXAlignment.Left
            local vl=Instance.new("TextLabel",row); vl.Size=UDim2.new(0,50,1,0); vl.Position=UDim2.new(0.4,-5,0,0); vl.BackgroundTransparency=1; vl.Text=tostring(value)..suffix; vl.Font=FONT_BOLD; vl.TextSize=11; vl.TextColor3=ACCENT_GLOW; vl.TextXAlignment=Enum.TextXAlignment.Right
            local sbg=Instance.new("Frame",row); sbg.Size=UDim2.new(0,100,0,6); sbg.Position=UDim2.new(1,-114,0.5,-3); sbg.BackgroundColor3=Color3.fromRGB(45,45,50); sbg.BackgroundTransparency=0.2; sbg.BorderSizePixel=0; Instance.new("UICorner",sbg).CornerRadius=UDim.new(0,3)
            local fill=Instance.new("Frame",sbg); fill.Size=UDim2.new((value-min)/(max-min),0,1,0); fill.BackgroundColor3=ACCENT; fill.BorderSizePixel=0; Instance.new("UICorner",fill).CornerRadius=UDim.new(0,3)
            local fillGrad=Instance.new("UIGradient",fill); fillGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,ACCENT_DIM),ColorSequenceKeypoint.new(1,ACCENT_GLOW)}); fillGrad.Rotation=0
            local thumb=Instance.new("Frame",fill); thumb.Size=UDim2.new(0,10,0,10); thumb.Position=UDim2.new(1,-5,0.5,-5); thumb.BackgroundColor3=TEXT_BRIGHT; thumb.BorderSizePixel=0; thumb.ZIndex=5; Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)
            local sh=Instance.new("TextButton",row); sh.Size=UDim2.new(0,110,1,0); sh.Position=UDim2.new(1,-118,0,0); sh.BackgroundTransparency=1; sh.Text=""
            local div=Instance.new("Frame",row); div.Size=UDim2.new(1,-16,0,1); div.Position=UDim2.new(0,8,1,-1); div.BackgroundColor3=DIVIDER_COL; div.BackgroundTransparency=0.6; div.BorderSizePixel=0
            local sliding=false
            local function upd(x) local pct=math.clamp((x-sbg.AbsolutePosition.X)/sbg.AbsoluteSize.X,0,1); local raw=min+(max-min)*pct; if increment then raw=math.floor(raw/increment+0.5)*increment end; value=math.clamp(raw,min,max); SliderStates[sliderKey]=value; local p2=(value-min)/(max-min); fill.Size=UDim2.new(p2,0,1,0); vl.Text=tostring(value)..suffix; if callback then callback(value) end end
            sh.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true; upd(inp.Position.X) end end)
            sh.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end end)
            UserInputService.InputChanged:Connect(function(inp) if sliding and inp.UserInputType==Enum.UserInputType.MouseMovement then upd(inp.Position.X) end end)
        end})
    end

    function api:AddButton(label,callback)
        table.insert(CatPages[catName],{Build=function(parent,idx)
            local row=Instance.new("TextButton"); row.Size=UDim2.new(1,0,0,32); row.BackgroundColor3=BG_ROW; row.BackgroundTransparency=0.4; row.BorderSizePixel=0; row.Text=""; row.LayoutOrder=idx; row.Parent=parent
            Instance.new("UICorner",row).CornerRadius=UDim.new(0,4)
            local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-40,1,0); lbl.Position=UDim2.new(0,14,0,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.Font=FONT_MED; lbl.TextSize=12; lbl.TextColor3=TEXT_WHITE; lbl.TextXAlignment=Enum.TextXAlignment.Left
            local ar=Instance.new("TextLabel",row); ar.Size=UDim2.new(0,20,1,0); ar.Position=UDim2.new(1,-26,0,0); ar.BackgroundTransparency=1; ar.Text=">"; ar.Font=FONT_BOLD; ar.TextSize=11; ar.TextColor3=TEXT_DIM
            local div=Instance.new("Frame",row); div.Size=UDim2.new(1,-16,0,1); div.Position=UDim2.new(0,8,1,-1); div.BackgroundColor3=DIVIDER_COL; div.BackgroundTransparency=0.6; div.BorderSizePixel=0
            row.MouseEnter:Connect(function() TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=BG_ROW_HOVER,BackgroundTransparency=0.2}):Play(); TweenService:Create(lbl,TweenInfo.new(0.15),{TextColor3=TEXT_BRIGHT}):Play(); TweenService:Create(ar,TweenInfo.new(0.15),{TextColor3=ACCENT_GLOW}):Play() end)
            row.MouseLeave:Connect(function() TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=BG_ROW,BackgroundTransparency=0.4}):Play(); TweenService:Create(lbl,TweenInfo.new(0.15),{TextColor3=TEXT_WHITE}):Play(); TweenService:Create(ar,TweenInfo.new(0.15),{TextColor3=TEXT_DIM}):Play() end)
            row.MouseButton1Click:Connect(function() TweenService:Create(row,TweenInfo.new(0.05),{BackgroundColor3=ACCENT_DIM,BackgroundTransparency=0.1}):Play(); task.wait(0.06); TweenService:Create(row,TweenInfo.new(0.2),{BackgroundColor3=BG_ROW,BackgroundTransparency=0.4}):Play(); if callback then callback() end end)
        end})
    end

    function api:AddDropdown(label,options,default,callback)
        local dropKey = catName..":"..label
        if DropdownStates[dropKey] == nil then DropdownStates[dropKey] = default or options[1] or "" end
        table.insert(CatPages[catName],{Build=function(parent,idx)
            local sel = DropdownStates[dropKey]
            local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,32); row.BackgroundColor3=BG_ROW; row.BackgroundTransparency=0.4; row.BorderSizePixel=0; row.LayoutOrder=idx; row.ClipsDescendants=true; row.Parent=parent
            Instance.new("UICorner",row).CornerRadius=UDim.new(0,4)
            local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0.5,-10,0,32); lbl.Position=UDim2.new(0,14,0,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.Font=FONT_MED; lbl.TextSize=12; lbl.TextColor3=TEXT_WHITE; lbl.TextXAlignment=Enum.TextXAlignment.Left
            local selFrame=Instance.new("Frame",row); selFrame.Size=UDim2.new(0.5,-16,0,22); selFrame.Position=UDim2.new(0.5,4,0,5); selFrame.BackgroundColor3=BG_INPUT; selFrame.BorderSizePixel=0; Instance.new("UICorner",selFrame).CornerRadius=UDim.new(0,5)
            local selStroke=Instance.new("UIStroke",selFrame); selStroke.Color=DIVIDER_COL; selStroke.Thickness=1; selStroke.Transparency=0.3
            local sl=Instance.new("TextLabel",selFrame); sl.Size=UDim2.new(1,-20,1,0); sl.Position=UDim2.new(0,8,0,0); sl.BackgroundTransparency=1; sl.Text=tostring(sel); sl.Font=FONT_MED; sl.TextSize=11; sl.TextColor3=ACCENT_GLOW; sl.TextXAlignment=Enum.TextXAlignment.Left
            local arrow=Instance.new("TextLabel",selFrame); arrow.Size=UDim2.new(0,12,1,0); arrow.Position=UDim2.new(1,-14,0,0); arrow.BackgroundTransparency=1; arrow.Text="v"; arrow.Font=FONT; arrow.TextSize=10; arrow.TextColor3=TEXT_DIM
            local div=Instance.new("Frame",row); div.Size=UDim2.new(1,-16,0,1); div.Position=UDim2.new(0,8,0,31); div.BackgroundColor3=DIVIDER_COL; div.BackgroundTransparency=0.6; div.BorderSizePixel=0
            local opened=false; local obs={}
            for oi,opt in ipairs(options) do
                local ob=Instance.new("TextButton",row); ob.Size=UDim2.new(1,-16,0,26); ob.Position=UDim2.new(0,8,0,32+(oi-1)*28); ob.BackgroundColor3=Color3.fromRGB(22,22,26); ob.BackgroundTransparency=0.2; ob.BorderSizePixel=0; ob.Text=tostring(opt); ob.Font=FONT; ob.TextSize=11; ob.TextColor3=TEXT_DIM; Instance.new("UICorner",ob).CornerRadius=UDim.new(0,5)
                ob.MouseEnter:Connect(function() TweenService:Create(ob,TweenInfo.new(0.1),{BackgroundColor3=BG_ROW_HOVER,TextColor3=TEXT_BRIGHT}):Play() end)
                ob.MouseLeave:Connect(function() TweenService:Create(ob,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(22,22,26),TextColor3=TEXT_DIM}):Play() end)
                ob.MouseButton1Click:Connect(function() sel=opt; DropdownStates[dropKey]=opt; sl.Text=tostring(opt); opened=false; arrow.Text="v"; TweenService:Create(row,TweenInfo.new(0.15,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=UDim2.new(1,0,0,32)}):Play(); if callback then callback({opt}) end end)
                table.insert(obs,ob)
            end
            local hb=Instance.new("TextButton",row); hb.Size=UDim2.new(1,0,0,32); hb.BackgroundTransparency=1; hb.Text=""
            hb.MouseButton1Click:Connect(function() opened=not opened; arrow.Text=opened and "^" or "v"; local h=opened and (32+#obs*28+6) or 32; TweenService:Create(row,TweenInfo.new(0.2,Enum.EasingStyle.Back,opened and Enum.EasingDirection.Out or Enum.EasingDirection.In),{Size=UDim2.new(1,0,0,h)}):Play() end)
        end})
    end

    function api:AddInput(label,placeholder,callback)
        table.insert(CatPages[catName],{Build=function(parent,idx)
            local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,32); row.BackgroundColor3=BG_ROW; row.BackgroundTransparency=0.4; row.BorderSizePixel=0; row.LayoutOrder=idx; row.Parent=parent
            Instance.new("UICorner",row).CornerRadius=UDim.new(0,4)
            local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0,90,1,0); lbl.Position=UDim2.new(0,14,0,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.Font=FONT_MED; lbl.TextSize=12; lbl.TextColor3=TEXT_WHITE; lbl.TextXAlignment=Enum.TextXAlignment.Left
            local box=Instance.new("TextBox",row); box.Size=UDim2.new(1,-120,0,20); box.Position=UDim2.new(0,106,0.5,-10); box.BackgroundColor3=BG_INPUT; box.BorderSizePixel=0; box.PlaceholderText=placeholder or ""; box.PlaceholderColor3=Color3.fromRGB(70,70,80); box.Text=""; box.Font=FONT; box.TextSize=11; box.TextColor3=TEXT_BRIGHT; box.ClearTextOnFocus=false; Instance.new("UICorner",box).CornerRadius=UDim.new(0,5); Instance.new("UIPadding",box).PaddingLeft=UDim.new(0,8)
            local boxStroke=Instance.new("UIStroke",box); boxStroke.Color=DIVIDER_COL; boxStroke.Thickness=1; boxStroke.Transparency=0.3
            local div=Instance.new("Frame",row); div.Size=UDim2.new(1,-16,0,1); div.Position=UDim2.new(0,8,1,-1); div.BackgroundColor3=DIVIDER_COL; div.BackgroundTransparency=0.6; div.BorderSizePixel=0
            box.Focused:Connect(function() TweenService:Create(boxStroke,TweenInfo.new(0.15),{Color=ACCENT}):Play() end)
            box.FocusLost:Connect(function() TweenService:Create(boxStroke,TweenInfo.new(0.15),{Color=DIVIDER_COL}):Play(); if callback then callback(box.Text) end end)
        end})
    end

    function api:AddKeybind(label,defaultKey,callback)
        local bindKey = catName..":"..label
        if KeybindStates[bindKey] == nil then KeybindStates[bindKey] = defaultKey or "None" end
        table.insert(CatPages[catName],{Build=function(parent,idx)
            local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,32); row.BackgroundColor3=BG_ROW; row.BackgroundTransparency=0.4; row.BorderSizePixel=0; row.LayoutOrder=idx; row.Parent=parent
            Instance.new("UICorner",row).CornerRadius=UDim.new(0,4)
            local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-100,1,0); lbl.Position=UDim2.new(0,14,0,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.Font=FONT_MED; lbl.TextSize=12; lbl.TextColor3=TEXT_WHITE; lbl.TextXAlignment=Enum.TextXAlignment.Left
            local keyBtn=Instance.new("TextButton",row); keyBtn.Size=UDim2.new(0,72,0,22); keyBtn.Position=UDim2.new(1,-84,0.5,-11); keyBtn.BackgroundColor3=BG_INPUT; keyBtn.BorderSizePixel=0; keyBtn.Text=KeybindStates[bindKey]; keyBtn.Font=FONT_BOLD; keyBtn.TextSize=11; keyBtn.TextColor3=ACCENT_GLOW; Instance.new("UICorner",keyBtn).CornerRadius=UDim.new(0,5)
            local keyStroke=Instance.new("UIStroke",keyBtn); keyStroke.Color=DIVIDER_COL; keyStroke.Thickness=1; keyStroke.Transparency=0.3
            local div=Instance.new("Frame",row); div.Size=UDim2.new(1,-16,0,1); div.Position=UDim2.new(0,8,1,-1); div.BackgroundColor3=DIVIDER_COL; div.BackgroundTransparency=0.6; div.BorderSizePixel=0
            local listening=false
            keyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening=true
                keyBtn.Text="..."
                TweenService:Create(keyStroke,TweenInfo.new(0.15),{Color=ACCENT}):Play()
                local conn
                conn = UserInputService.InputBegan:Connect(function(inp,gpe)
                    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    listening=false
                    conn:Disconnect()
                    local name = inp.KeyCode.Name
                    if inp.KeyCode == Enum.KeyCode.Backspace then name = "None" end
                    KeybindStates[bindKey] = name
                    keyBtn.Text = name
                    TweenService:Create(keyStroke,TweenInfo.new(0.15),{Color=DIVIDER_COL}):Play()
                end)
            end)
            KeybindRegistry[bindKey] = {SetKey=function(name) KeybindStates[bindKey]=name; keyBtn.Text=name end}
        end})
        table.insert(KeybindActions,{bindKey=bindKey,action=callback})
    end

    function api:AddCustom(buildFn)
        table.insert(CatPages[catName],{Build=buildFn})
    end

    return api
end
end)()

;(function()
do local AC=AddCategory("Anti-Cheat",1)
AC:AddSection("Scanner")
AC:AddButton("Scan For Anti-Cheat",function() local c=ScanForAntiCheat(); local d=GetProtectionDetails(); Notify("Scan","Found "..c.." items | Risk: "..d.RiskLevel,4) end)
AC:AddButton("View Scripts (F9)",function() print("=== SCRIPTS ==="); for i,s in pairs(AntiCheatDetection.DetectedScripts) do print(i..". "..s.Name.." - "..s.Path) end; Notify("Scripts","Found "..#AntiCheatDetection.DetectedScripts,3) end)
AC:AddButton("View Remotes (F9)",function() print("=== REMOTES ==="); for i,r in pairs(AntiCheatDetection.DetectedRemotes) do print(i..". "..r.Name.." - "..r.Path) end; Notify("Remotes","Found "..#AntiCheatDetection.DetectedRemotes,3) end)
AC:AddSection("Protection")
AC:AddToggle("Lite Bypass (Safe)",false,function(v)
    if v then
        _BypassError = nil
        Notify("Bypass","Anti-kick + Anti-idle...",2)
        SetupLiteBypass()
        task.spawn(function()
            while _bypassRunning do task.wait(0.1) end
            if IsBypassInitialized then
                Notify("Bypass","Lite bypass active!",3)
            elseif _BypassError then
                NotifyError("Bypass", _BypassError, 5)
            end
        end)
    end
end)
AC:AddToggle("Full Bypass (Risky)",false,function(v)
    if v then
        _BypassError = nil
        Notify("Bypass","Setting up metatable hooks...",2)
        SetupFullBypass()
        task.spawn(function()
            while _bypassRunning do task.wait(0.2) end
            task.wait(0.5)
            while _bypassRunning do task.wait(0.2) end
            if _fullBypassDone and not _BypassError then
                Notify("Bypass","Full bypass active! (gamepass/spoof)",3)
            elseif _BypassError then
                NotifyError("Bypass", _BypassError, 5)
            end
        end)
    end
end)
do
local GamepassBypassConnections = {}

local function CleanupGamepassBypass()
    for _, c in pairs(GamepassBypassConnections) do pcall(function() c:Disconnect() end) end
    GamepassBypassConnections = {}
end

local function SetupGamepassBypass()
    CleanupGamepassBypass()
    if not AntiCheatBypass.SpoofMonetization then return end

    SetupFullBypass()

    if _hookfunction then
        pcall(function()
            local origOwns = MarketplaceService.UserOwnsGamePassAsync
            _hookfunction(MarketplaceService.UserOwnsGamePassAsync, _newcclosure(function(self, userId, gamePassId)
                if AntiCheatBypass.SpoofMonetization then
                    _cachedGamepasses[gamePassId] = true
                    return true
                end
                return origOwns(self, userId, gamePassId)
            end))
        end)

        pcall(function()
            local origAsset = MarketplaceService.PlayerOwnsAsset
            _hookfunction(MarketplaceService.PlayerOwnsAsset, _newcclosure(function(self, player, assetId)
                if AntiCheatBypass.SpoofMonetization then return true end
                return origAsset(self, player, assetId)
            end))
        end)

        pcall(function()
            local origInfo = MarketplaceService.GetProductInfo
            _hookfunction(MarketplaceService.GetProductInfo, _newcclosure(function(self, assetId, infoType)
                if AntiCheatBypass.SpoofMonetization then
                    local info = {IsForSale=true,ProductId=assetId,Name="Bypassed",PriceInRobux=0,Creator={Id=1,Name="Roblox"}}
                    pcall(function() local real = origInfo(self, assetId, infoType); info.Name = real.Name or info.Name end)
                    return info
                end
                return origInfo(self, assetId, infoType)
            end))
        end)

        pcall(function()
            local origPrompt = MarketplaceService.PromptGamePassPurchase
            _hookfunction(MarketplaceService.PromptGamePassPurchase, _newcclosure(function(self, player, gamePassId)
                if AntiCheatBypass.SpoofMonetization and player == LocalPlayer then
                    _cachedGamepasses[gamePassId] = true
                    task.defer(function()
                        FireGamepassRemotes(gamePassId)
                        Notify("Gamepass","Bypassed gamepass #"..tostring(gamePassId),2)
                    end)
                    return
                end
                return origPrompt(self, player, gamePassId)
            end))
        end)

        pcall(function()
            local origProduct = MarketplaceService.PromptProductPurchase
            _hookfunction(MarketplaceService.PromptProductPurchase, _newcclosure(function(self, player, productId, ...)
                if AntiCheatBypass.SpoofMonetization and player == LocalPlayer then
                    task.defer(function()
                        FireGamepassRemotes(productId)
                        Notify("Gamepass","Bypassed product #"..tostring(productId),2)
                    end)
                    return
                end
                return origProduct(self, player, productId, ...)
            end))
        end)

        pcall(function()
            local origPurchase = MarketplaceService.PromptPurchase
            _hookfunction(MarketplaceService.PromptPurchase, _newcclosure(function(self, player, assetId, ...)
                if AntiCheatBypass.SpoofMonetization and player == LocalPlayer then
                    task.defer(function() FireGamepassRemotes(assetId) end)
                    return
                end
                return origPurchase(self, player, assetId, ...)
            end))
        end)
    end

    table.insert(GamepassBypassConnections, MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
        if player == LocalPlayer and AntiCheatBypass.SpoofMonetization then
            _cachedGamepasses[gamePassId] = true
            FireGamepassRemotes(gamePassId)
        end
    end))

    table.insert(GamepassBypassConnections, MarketplaceService.PromptPurchaseFinished:Connect(function(player, assetId, wasPurchased)
        if player == LocalPlayer and AntiCheatBypass.SpoofMonetization then
            FireGamepassRemotes(assetId)
        end
    end))

    local layers = {}
    if IsBypassInitialized then table.insert(layers, "namecall hook") end
    if _hookfunction then table.insert(layers, "direct function hooks") end
    table.insert(layers, "event listeners")
    Notify("Gamepass", "Bypass active: "..table.concat(layers, " + "), 3)
end

_G._GamepassBypass = {Setup=SetupGamepassBypass, Cleanup=CleanupGamepassBypass}
end

AC:AddToggle("Robux/Gamepass Bypass",false,function(v)
    AntiCheatBypass.SpoofMonetization=v
    if v then
        if _G._GamepassBypass then _G._GamepassBypass.Setup() end
    else
        if _G._GamepassBypass then _G._GamepassBypass.Cleanup() end
    end
end)
AC:AddToggle("Anti-Kick",false,function(v)
    AntiCheatBypass.AntiKick=v
    if v then SetupLiteBypass(); Notify("Anti-Kick","Blocks forced Kick() + place-teleport kicks",3) end
end)
AC:AddToggle("Anti-TP Detection",false,function(v)
    AntiCheatBypass.AntiTeleportDetection=v
    SetupAntiTeleportDetection()
    if v then Notify("Anti-TP","Smooths script teleports so they don't look instant",3) end
    if _BypassError then NotifyError("Bypass",_BypassError,5) end
end)
AC:AddToggle("Anti-Speed Detection",false,function(v)
    AntiCheatBypass.AntiSpeedDetection=v
    SetupAntiSpeedDetection()
    if v then Notify("Anti-Speed","Caps reported root velocity so Fly/Speed reads normal",3) end
    if _BypassError then NotifyError("Bypass",_BypassError,5) end
end)
AC:AddToggle("Spoof WalkSpeed",false,function(v) AntiCheatBypass.SpoofWalkSpeed=v; SetupAntiSpeedDetection(); if _BypassError then NotifyError("Bypass",_BypassError,5) end end)
AC:AddToggle("Spoof JumpPower",false,function(v) AntiCheatBypass.SpoofJumpPower=v; SetupAntiSpeedDetection(); if _BypassError then NotifyError("Bypass",_BypassError,5) end end)
AC:AddToggle("Hide From Admins",false,function(v)
    AntiCheatBypass.HideFromAdmins=v
    SetupHideFromAdmins()
    if v then Notify("Hide Admins","DisplayName spoofed, re-applies on respawn",3) end
end)
AC:AddToggle("Anti-Rubberband",false,function(v) AntiCheatBypass.AntiRubberband=v; SetAntiRubberband(v); if v then Notify("Anti-RB","Blocks server position resets",3) end end)
AC:AddToggle("Anti-AFK Kick",false,function(v)
    AntiCheatBypass.AntiAFK=v
    if v then SetupLiteBypass(); Notify("Anti-AFK","Simulates input on idle to avoid AFK kicks",3) end
end)
AC:AddSection("Anti-Detection")
AC:AddToggle("Anti-Detect (Hide Objects)",false,function(v)
    SetAntiDetect(v)
    if v then Notify("Anti-Detect","Rotating GUI name/parent to dodge simple scans",3) end
end)
AC:AddToggle("Auto Re-Scan on Respawn",false,function(v)
    SetAutoRescan(v)
    if v then Notify("Auto-Scan","Will re-scan for anti-cheat after each respawn",3) end
end)
AC:AddButton("Block Flagged Remotes",function() BlockFlaggedRemotes() end)
AC:AddButton("Status / Diagnostics",function()
    local caps = {}
    table.insert(caps, "namecall:"..(_hookmetamethod and "Y" or "N"))
    table.insert(caps, "hookfn:"..(_hookfunction and "Y" or "N"))
    table.insert(caps, "lite:"..(IsBypassInitialized and "Y" or "N"))
    table.insert(caps, "full:"..(_fullBypassDone and "Y" or "N"))
    Notify("Diagnostics", table.concat(caps, "  "), 5)
    print("[Phaze] Protection status:", table.concat(caps, " "))
end)

end

do local ESPColors = {
    ["Red"]=Color3.fromRGB(255,50,50), ["Green"]=Color3.fromRGB(50,255,50),
    ["Blue"]=Color3.fromRGB(50,150,255), ["White"]=Color3.fromRGB(255,255,255),
    ["Yellow"]=Color3.fromRGB(255,255,50), ["Purple"]=Color3.fromRGB(180,80,255),
    ["Cyan"]=Color3.fromRGB(50,255,255), ["Orange"]=Color3.fromRGB(255,150,30),
    ["Pink"]=Color3.fromRGB(255,100,200)
}
local ES=AddCategory("ESP",2)
ES:AddSection("Player ESP")
ES:AddToggle("Enable ESP",false,function(v) ESP.Enabled=v; if v then RefreshAllESP() end end)
ES:AddToggle("Show Name",true,function(v) ESP.ShowName=v end)
ES:AddToggle("Show Health",true,function(v) ESP.ShowHealth=v end)
ES:AddToggle("Show Distance",true,function(v) ESP.ShowDistance=v end)
ES:AddToggle("Team Check",false,function(v) ESP.TeamCheck=v end)
ES:AddToggle("Wall Check",false,function(v) ESP.WallCheck=v end)
ES:AddSlider("Max Distance",100,2000,1000,50,"m",function(v) ESP.MaxDistance=v end)
ES:AddSection("Chams")
ES:AddToggle("Chams (Fill Through Walls)",false,function(v) ESP.FillTransparency = v and 0.55 or 1 end)
ES:AddSlider("Chams Opacity",10,90,45,5,"%",function(v) if ESP.FillTransparency < 1 then ESP.FillTransparency = 1 - (v/100) end end)
ES:AddSection("Colors")
ES:AddDropdown("Behind Wall",{"White","Red","Green","Blue","Yellow","Purple","Cyan","Orange","Pink"},"White",function(o)
    local c = ESPColors[o[1]]
    if c then ESP.HighlightColor = c end
end)
ES:AddDropdown("Visible",{"Green","Red","Blue","White","Yellow","Cyan","Orange","Pink","Purple"},"Green",function(o)
    local c = ESPColors[o[1]]
    if c then ESP.VisibleColor = c end
end)
ES:AddSection("Skeleton ESP")
ES:AddToggle("Show Skeleton",false,function(v) ESP.ShowSkeleton=v end)
ES:AddDropdown("Skeleton Color",{"White","Red","Green","Blue","Yellow","Purple","Cyan","Orange","Pink"},"White",function(o)
    local c = ESPColors[o[1]]
    if c then ESP.SkeletonColor = c end
end)
ES:AddSection("Tracers")
ES:AddToggle("Show Tracers",false,function(v) ESP.ShowTracers=v; UpdateAllTracers(); for p,_ in pairs(ESPObjects) do RemoveESP(p) end; if ESP.Enabled then RefreshAllESP() end end)
ES:AddSlider("Tracer Thickness",1,5,2,1,"",function(v) ESP.TracerThickness=v; UpdateAllTracers() end)
ES:AddDropdown("Tracer Origin",{"Bottom","Center"},"Bottom",function(o) ESP.TracerOrigin=o[1] end)
ES:AddDropdown("Tracer Color",{"White","Red","Green","Blue","Yellow","Purple","Cyan","Orange","Pink"},"White",function(o)
    local c = ESPColors[o[1]]
    if c then ESP.TracerColor = c; UpdateAllTracers() end
end)

end

do local AI=AddCategory("Aimbot",3)
AI:AddSection("Aimbot")
AI:AddToggle("Enable Aimbot",false,function(v) Aimbot.Enabled=v; if _G._SetAimbot then _G._SetAimbot(v) end end)
AI:AddToggle("Auto Shoot",false,function(v) Aimbot.TriggerBot=v end)
AI:AddSlider("Smoothness",1,100,20,1,"%",function(v) Aimbot.Smoothness=v/100 end)
AI:AddDropdown("Aim Part",{"Head","UpperTorso","Torso","HumanoidRootPart"},"Head",function(o) Aimbot.AimPart=o[1] end)
AI:AddSlider("Prediction",0,100,0,5,"%",function(v) Aimbot.Prediction=(v/100)*0.3 end)
AI:AddSection("FOV Circle")
AI:AddToggle("Show FOV",true,function(v) Aimbot.ShowFOV=v; if FOVCircle then FOVCircle.Visible=v end end)
AI:AddSlider("FOV Radius",10,500,100,10,"px",function(v) Aimbot.FOV=v; if FOVCircle then FOVCircle.Radius=v end end)
AI:AddSlider("FOV Thickness",1,5,2,1,"px",function(v) if FOVCircle then FOVCircle.Thickness=v end end)
local FOVColors = {
    ["White"]=Color3.fromRGB(255,255,255), ["Red"]=Color3.fromRGB(255,50,50),
    ["Green"]=Color3.fromRGB(50,255,50), ["Blue"]=Color3.fromRGB(50,150,255),
    ["Yellow"]=Color3.fromRGB(255,255,50), ["Purple"]=Color3.fromRGB(180,80,255),
    ["Cyan"]=Color3.fromRGB(50,255,255), ["Orange"]=Color3.fromRGB(255,150,30)
}
AI:AddDropdown("FOV Color",{"White","Red","Green","Blue","Yellow","Purple","Cyan","Orange"},"White",function(o)
    local c = FOVColors[o[1]]
    if c then Aimbot.FOVColor=c; if FOVCircle then FOVCircle.Color=c end end
end)
AI:AddToggle("Visibility Check",true,function(v) Aimbot.VisibilityCheck=v end)
AI:AddToggle("Team Check",false,function(v) Aimbot.TeamCheck=v end)

AI:AddButton("DEBUG: Why aimbot wont lock", function()
    print("===== AIMBOT DEBUG =====")
    print("Enabled:", Aimbot.Enabled)
    print("FOV:", Aimbot.FOV, "Smoothness:", Aimbot.Smoothness, "AimPart:", Aimbot.AimPart)
    print("TeamCheck:", Aimbot.TeamCheck, "VisCheck:", Aimbot.VisibilityCheck)
    print("Connection:", AimbotConnection and "ACTIVE" or "NIL")
    local n_total, n_alive, n_visible, n_inFOV = 0, 0, 0, 0
    local nearest, nearestDist = nil, math.huge
    local cx, cy = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            n_total = n_total + 1
            if p.Character then
                local alive = IsAlive(p.Character)
                if alive then
                    n_alive = n_alive + 1
                    local ap = GetAimPart(p.Character, Aimbot.AimPart)
                    if ap then
                        local sp, on = Camera:WorldToViewportPoint(ap.Position)
                        if on then
                            n_visible = n_visible + 1
                            local d = (Vector2.new(sp.X,sp.Y)-Vector2.new(cx,cy)).Magnitude
                            if d < Aimbot.FOV then n_inFOV = n_inFOV + 1 end
                            if d < nearestDist then nearestDist = d; nearest = p.Name end
                        end
                    end
                end
            end
        end
    end
    print("Players total:", n_total, "alive:", n_alive, "on-screen:", n_visible, "in-FOV:", n_inFOV)
    print("Nearest to crosshair:", nearest or "NONE", "at", math.floor(nearestDist), "px")
    print("Your FOV is", Aimbot.FOV, "px - need <", math.floor(nearestDist), "to lock nearest")
    print("===== END =====")
    Notify("Aimbot","alive:"..n_alive.." inFOV:"..n_inFOV.." nearest:"..math.floor(nearestDist).."px",6)
end)

AI:AddSection("Magic Bullet")
AI:AddToggle("Silent Aim",false,function(v) MagicBullet.SilentAim=v; if _G._MagicBullet then _G._MagicBullet.SetSilentAim(v) end end)
AI:AddToggle("Bullet TP",false,function(v) MagicBullet.BulletTP=v; if _G._MagicBullet then _G._MagicBullet.SetBulletTP(v) end end)
AI:AddToggle("Curve Bullet",false,function(v) MagicBullet.CurveBullet=v; if _G._MagicBullet then _G._MagicBullet.SetCurveBullet(v) end end)
AI:AddDropdown("Magic Aim Part",{"Head","UpperTorso","Torso","HumanoidRootPart"},"Head",function(o) MagicBullet.AimPart=o[1] end)
AI:AddButton("Debug: Check Raycast Hook",function()
    local before = _G._MagicBullet and _G._MagicBullet.GetCallCount() or 0
    Notify("Magic Bullet","Fire a shot in the next 3 seconds...",3)
    task.delay(3,function()
        local after = _G._MagicBullet and _G._MagicBullet.GetCallCount() or 0
        local delta = after - before
        if delta > 0 then
            Notify("Magic Bullet","Raycast hook saw "..delta.." call(s) - hook is intercepting this game's shots. If Silent Aim still doesn't land, the server is likely re-validating hits itself (server-authoritative), which client-side redirect can't beat.",10)
        else
            NotifyError("Magic Bullet","0 raycast calls seen. This game's shooting doesn't go through Workspace:Raycast/FindPartOnRay - it likely uses a RemoteEvent to report hits directly, which this hook can't intercept.",10)
        end
    end)
end)
AI:AddButton("Info: Bullet TP / Curve Bullet",function()
    Notify("Magic Bullet","These only work on games with a REAL flying bullet Part (velocity>100 studs/s) in Workspace. If the game's guns are instant-hit (hitscan/laser, no visible travel time), there is no physical bullet to grab and these can never work - only Silent Aim (raycast redirect) can apply to hitscan weapons.",10)
end)
end

do local HB=AddCategory("Hitbox",4)
HB:AddToggle("Enable Hitbox",false,function(v) HitboxExpander.Enabled=v; _G._Funcs.SetHitboxExpander(v) end)
HB:AddSlider("Size",2,50,10,1," studs",function(v) HitboxExpander.Size=v end)
HB:AddSlider("Transparency",0,100,50,5,"%",function(v) HitboxExpander.Transparency=v/100 end)

end

do local PL=AddCategory("Player",5)
PL:AddToggle("NoClip [N]",false,function(v) NoClip.Enabled=v; _G._Funcs.SetNoClip(v) end)
PL:AddKeybind("NoClip Keybind","N",function()
    NoClip.Enabled = not NoClip.Enabled; _G._Funcs.SetNoClip(NoClip.Enabled)
    ToggleStates["Player:NoClip [N]"] = NoClip.Enabled
    local reg = ToggleRegistry["Player:NoClip [N]"]; if reg then reg.SetVisual(NoClip.Enabled) end
end)
PL:AddToggle("Fly [F]",false,function(v) Fly.Enabled=v; _G._Funcs.SetFly(v) end)
PL:AddKeybind("Fly Keybind","F",function()
    Fly.Enabled = not Fly.Enabled; _G._Funcs.SetFly(Fly.Enabled)
    ToggleStates["Player:Fly [F]"] = Fly.Enabled
    local reg = ToggleRegistry["Player:Fly [F]"]; if reg then reg.SetVisual(Fly.Enabled) end
end)
PL:AddSlider("Fly Speed",10,900,50,5,"",function(v) Fly.Speed=v end)
PL:AddSection("Custom Speed")
PL:AddToggle("Custom Speed",false,function(v) _G._Funcs.SetCustomSpeed(v) end)
PL:AddSlider("Speed",16,1000,50,2,"",function(v) _G._Funcs.CustomSpeed.Speed=v end)
PL:AddSection("Movement")
PL:AddToggle("Infinite Jump",false,function(v) _G._Funcs.SetInfiniteJump(v) end)
PL:AddToggle("Anti-Fall (Void Save)",false,function(v) _G._Funcs.SetAntiFall(v) end)
PL:AddToggle("Fullbright",false,function(v) _G._Funcs.Fullbright.Enabled=v; _G._Funcs.SetFullbright(v) end)
PL:AddSection("Freecam")
PL:AddToggle("Freecam",false,function(v) _G._Funcs.SetFreecam(v) end)
PL:AddKeybind("Freecam Keybind","None",function()
    local newState = not (ToggleStates["Player:Freecam"] or false)
    _G._Funcs.SetFreecam(newState)
    ToggleStates["Player:Freecam"] = newState
    local reg = ToggleRegistry["Player:Freecam"]; if reg then reg.SetVisual(newState) end
end)
PL:AddSlider("Freecam Speed",10,500,50,10,"",function(v) _G._Funcs.FreecamState.Speed=v end)
PL:AddSlider("Build Platform Size",4,40,12,2,"studs",function(v) _G._Funcs.SetFreecamBlockSize(v) end)
PL:AddSlider("Corner Build Min Thickness",1,10,2,1,"studs",function(v) _G._Funcs.SetFreecamCornerThickness(v) end)
PL:AddButton("Clear My Freecam Platforms",function() _G._Funcs.ClearFreecamBlocks(); Notify("Freecam","Platforms cleared",2) end)
PL:AddButton("Clear Freecam Draw Path",function() _G._Funcs.ClearFreecamDrawing(); Notify("Freecam","Draw path cleared",2) end)
PL:AddButton("Freecam Build Modes Info",function()
    Notify("Freecam","←→ cycles: Teleport / Build (single platform) / Corner Build (click 2 corners to build a custom-sized block between them, any shape — floor, wall, or pillar). Backspace cancels a pending Corner A.",8)
end)

PL:AddSection("Movement Recorder")
local _movStatusLabel = nil
PL:AddCustom(function(parent)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,24)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(200,200,208)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "Idle"
    lbl.Parent = parent
    _movStatusLabel = lbl
    task.spawn(function()
        while parent.Parent do
            pcall(function() lbl.Text = _G._Funcs.MovementRecorder.Status end)
            task.wait(0.3)
        end
    end)
end)
PL:AddToggle("Record Movement",false,function(v) _G._Funcs.SetMovementRecord(v) end)
PL:AddToggle("Play Recording",false,function(v) _G._Funcs.SetMovementPlay(v) end)
PL:AddToggle("Loop Playback",false,function(v) _G._Funcs.MovementRecorder.LoopPlayback = v end)
local _movFileName = "default"
PL:AddInput("Recording Name","e.g. run1",function(text) if text ~= "" then _movFileName = text end end)
PL:AddButton("Save Recording To File",function()
    local ok, err = _G._Funcs.SaveMovementRecordingToFile(_movFileName)
    if ok then Notify("Movement Recorder","Saved as '".._movFileName.."'",3)
    else NotifyError("Movement Recorder","Save failed: "..tostring(err),4) end
end)
PL:AddButton("Load Recording From File",function()
    local ok, err = _G._Funcs.LoadMovementRecordingFromFile(_movFileName)
    if ok then Notify("Movement Recorder","Loaded '".._movFileName.."' ("..#_G._Funcs.MovementRecorder.Frames.." frames)",3)
    else NotifyError("Movement Recorder","Load failed: "..tostring(err),4) end
end)
PL:AddButton("Info: Movement Recorder",function()
    Notify("Movement Recorder","Records your character's exact position every frame while you move. Playback replays it via CFrame at the exact recorded timing - smooth and accurate, but it's a direct position set rather than real WASD-driven movement, so it won't add to movement/speed stats and heavily-monitored games may flag it like any scripted teleport. Save/Load needs an executor with writefile/readfile support.",9)
end)

end

do local TP=AddCategory("Teleport",6)
local selectedTPPlayer=nil
local function GetPlayerList() local n={"Select Player"}; for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer then table.insert(n,p.Name) end end; return n end
TP:AddDropdown("Player",GetPlayerList(),"Select Player",function(o) selectedTPPlayer=Players:FindFirstChild(o[1]) end)
TP:AddButton("Teleport To",function() if selectedTPPlayer and selectedTPPlayer.Character then local r=GetRootPart(selectedTPPlayer.Character); if r then _G._Funcs.TeleportTo(r.CFrame+Vector3.new(0,3,0)) end else Notify("Error","Select a player!",2) end end)
TP:AddButton("Bring Player (FE)",function()
    if not selectedTPPlayer or not selectedTPPlayer.Character then Notify("Error","Select a player!",2); return end
    local c = LocalPlayer.Character; if not c then return end
    local myRoot = GetRootPart(c); local theirRoot = GetRootPart(selectedTPPlayer.Character)
    if not myRoot or not theirRoot then return end
    local savedPos = myRoot.CFrame
    local hum = GetHumanoid(c)
    Notify("Bring","Bringing "..selectedTPPlayer.Name.."...",3)
    task.spawn(function()
        for _, part in pairs(c:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.CanCollide = false; part.Massless = true end) end
        end
        pcall(function() if hum then hum.PlatformStand = true end end)
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = myRoot
        local bg = Instance.new("BodyAngularVelocity")
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.AngularVelocity = Vector3.new(0, 0, 0)
        bg.Parent = myRoot
        for i = 1, 200 do
            if not selectedTPPlayer or not selectedTPPlayer.Character then break end
            theirRoot = GetRootPart(selectedTPPlayer.Character)
            if not theirRoot then break end
            local targetCF = theirRoot.CFrame
            myRoot.CFrame = targetCF + (savedPos.Position - targetCF.Position).Unit * 2
            bv.Velocity = (savedPos.Position - targetCF.Position).Unit * 300
            bg.AngularVelocity = Vector3.new(0, 50, 0)
            task.wait()
            myRoot.CFrame = targetCF
            bv.Velocity = Vector3.new(0, 0, 0)
            task.wait()
        end
        bv:Destroy(); bg:Destroy()
        for _, part in pairs(c:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.CanCollide = true; part.Massless = false end) end
        end
        pcall(function() if hum then hum.PlatformStand = false end end)
        task.wait(0.1)
        myRoot.CFrame = savedPos
        myRoot.Velocity = Vector3.new(0, 0, 0)
        Notify("Bring","Done!",2)
    end)
end)
local BringActive = false
TP:AddToggle("Continuous Bring (FE)",false,function(v)
    if BringLoopConnection then BringLoopConnection:Disconnect(); BringLoopConnection=nil end
    BringActive = v
    if v then
        local c = LocalPlayer.Character; if not c then return end
        local myRoot = GetRootPart(c); if not myRoot then return end
        local savedPos = myRoot.CFrame
        local hum = GetHumanoid(c)
        for _, part in pairs(c:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.CanCollide = false; part.Massless = true end) end
        end
        pcall(function() if hum then hum.PlatformStand = true end end)
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Name = "BringBV"
        bv.Parent = myRoot
        BringLoopConnection = RunService.Heartbeat:Connect(function()
            if not BringActive or not selectedTPPlayer or not selectedTPPlayer.Character or not LocalPlayer.Character then return end
            local mr = GetRootPart(LocalPlayer.Character)
            local tr = GetRootPart(selectedTPPlayer.Character)
            if not mr or not tr then return end
            local dir = (savedPos.Position - tr.Position)
            if dir.Magnitude > 1 then dir = dir.Unit else dir = Vector3.new(1,0,0) end
            mr.CFrame = tr.CFrame + dir * 1.5
            bv.Velocity = dir * 250
            task.defer(function()
                if mr and tr and BringActive then
                    mr.CFrame = tr.CFrame
                    bv.Velocity = Vector3.new(0, 0, 0)
                end
            end)
        end)
    else
        local c = LocalPlayer.Character
        if c then
            local hum = GetHumanoid(c)
            pcall(function() if hum then hum.PlatformStand = false end end)
            for _, part in pairs(c:GetDescendants()) do
                if part:IsA("BasePart") then pcall(function() part.CanCollide = true; part.Massless = false end) end
            end
            local myRoot = GetRootPart(c)
            if myRoot then
                pcall(function() local bv = myRoot:FindFirstChild("BringBV"); if bv then bv:Destroy() end end)
                myRoot.Velocity = Vector3.new(0, 0, 0)
            end
        end
    end
end)

TP:AddSection("Click Teleport")
local ClickTPConn = nil
local function SetClickTeleport(e)
    if ClickTPConn then ClickTPConn:Disconnect(); ClickTPConn = nil end
    if not e then return end
    ClickTPConn = UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe or inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if FreecamActive then return end
        pcall(function()
            local mouseLoc = UserInputService:GetMouseLocation()
            local unitRay = Camera:ViewportPointToRay(mouseLoc.X, mouseLoc.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            local c = LocalPlayer.Character
            params.FilterDescendantsInstances = c and {c} or {}
            local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 2000, params)
            if result then
                TeleportTo(CFrame.new(result.Position + Vector3.new(0,3,0)))
                Notify("Click Teleport","Teleported!",1.5)
            end
        end)
    end)
end
_G._Funcs.SetClickTeleport = SetClickTeleport
TP:AddToggle("Click Teleport (Hold nothing, just click)",false,function(v) SetClickTeleport(v) end)

TP:AddSection("Waypoints")
local WaypointStore = {}
local WaypointNames = {"No Waypoints Yet"}
local selectedWaypoint = nil
local _wpNameInput = ""
local _wpWrite = _getFunc("writefile")
local _wpRead = _getFunc("readfile")
local _wpIsFile = _getFunc("isfile")
local _wpHttp = game:GetService("HttpService")
local _wpFile = "Phaze_Waypoints_"..tostring(game.PlaceId)..".json"

local function _saveWaypointsToFile()
    if not _wpWrite then return end
    pcall(function()
        local data = {}
        for name, cf in pairs(WaypointStore) do data[name] = {cf:GetComponents()} end
        _wpWrite(_wpFile, _wpHttp:JSONEncode(data))
    end)
end

local function _loadWaypointsFromFile()
    if not _wpRead or not _wpIsFile or not _wpIsFile(_wpFile) then return end
    pcall(function()
        local data = _wpHttp:JSONDecode(_wpRead(_wpFile))
        for name, comps in pairs(data) do
            WaypointStore[name] = CFrame.new(unpack(comps))
            if WaypointNames[1] == "No Waypoints Yet" and #WaypointNames == 1 then
                WaypointNames[1] = name
            else
                table.insert(WaypointNames, name)
            end
        end
    end)
end
_loadWaypointsFromFile()

local function _refreshTeleportTab()
    local cur = ActiveCat
    ActiveCat = nil
    RenderCategory(cur or "Teleport")
end

TP:AddInput("Waypoint Name","e.g. Base",function(text) _wpNameInput = text end)
TP:AddButton("Save Waypoint Here",function()
    local c = LocalPlayer.Character
    if not c then Notify("Waypoint","No character!",2); return end
    local rp = GetRootPart(c)
    if not rp then return end
    local name = (_wpNameInput ~= "" and _wpNameInput) or ("WP"..tostring(#WaypointNames+1))
    if WaypointStore[name] == nil then
        if WaypointNames[1] == "No Waypoints Yet" and #WaypointNames == 1 then
            WaypointNames[1] = name
        else
            table.insert(WaypointNames, name)
        end
    end
    WaypointStore[name] = rp.CFrame
    _saveWaypointsToFile()
    Notify("Waypoint","Saved '"..name.."'",2)
    _refreshTeleportTab()
end)
TP:AddDropdown("Saved Waypoints",WaypointNames,WaypointNames[1],function(o) selectedWaypoint = o[1] end)
TP:AddButton("Teleport To Waypoint",function()
    if not selectedWaypoint or not WaypointStore[selectedWaypoint] then Notify("Waypoint","No waypoint selected",2); return end
    _G._Funcs.TeleportTo(WaypointStore[selectedWaypoint])
    Notify("Waypoint","Teleported to '"..selectedWaypoint.."'",2)
end)
TP:AddButton("Delete Selected Waypoint",function()
    if not selectedWaypoint or not WaypointStore[selectedWaypoint] then Notify("Waypoint","No waypoint selected",2); return end
    WaypointStore[selectedWaypoint] = nil
    for i,n in ipairs(WaypointNames) do if n == selectedWaypoint then table.remove(WaypointNames, i); break end end
    if #WaypointNames == 0 then table.insert(WaypointNames, "No Waypoints Yet") end
    selectedWaypoint = nil
    _saveWaypointsToFile()
    _refreshTeleportTab()
end)

end

do local TG=AddCategory("Target",7)
local _tgSelected = nil
local _tgPlayerNames = {"Select Player"}
local function _tgRefreshList()
    for i=#_tgPlayerNames,1,-1 do table.remove(_tgPlayerNames, i) end
    table.insert(_tgPlayerNames, "Select Player")
    for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer then table.insert(_tgPlayerNames, p.Name) end end
end
_tgRefreshList()
TG:AddSection("Target Player")
TG:AddDropdown("Player",_tgPlayerNames,"Select Player",function(o) _tgSelected = Players:FindFirstChild(o[1]) end)
TG:AddButton("Refresh Player List",function()
    _tgRefreshList()
    local cur = ActiveCat; ActiveCat = nil; RenderCategory(cur or "Target")
end)

TG:AddSection("Spectate")
local _spectating = false
local _spectateConn = nil
TG:AddButton("Spectate Target",function()
    if not _tgSelected or not _tgSelected.Character then Notify("Spectate","Select a player first!",2); return end
    local hum = GetHumanoid(_tgSelected.Character)
    if not hum then Notify("Spectate","Target has no humanoid",2); return end
    pcall(function() Camera.CameraType = Enum.CameraType.Custom; Camera.CameraSubject = hum end)
    _spectating = true
    if _spectateConn then _spectateConn:Disconnect() end
    _spectateConn = RunService.Heartbeat:Connect(function()
        if not _spectating then return end
        if not _tgSelected or not _tgSelected.Parent or not _tgSelected.Character then
            _spectating = false
            local c = LocalPlayer.Character
            pcall(function() Camera.CameraType = Enum.CameraType.Custom; if c then local h=GetHumanoid(c); if h then Camera.CameraSubject=h end end end)
            return
        end
    end)
    Notify("Spectate","Watching ".._tgSelected.Name,2)
end)
TG:AddButton("Stop Spectating",function()
    _spectating = false
    if _spectateConn then _spectateConn:Disconnect(); _spectateConn = nil end
    local c = LocalPlayer.Character
    pcall(function() Camera.CameraType = Enum.CameraType.Custom; if c then local h=GetHumanoid(c); if h then Camera.CameraSubject=h end end end)
    Notify("Spectate","Stopped",2)
end)

TG:AddSection("Appearance")
TG:AddButton("Copy Outfit",function()
    if not _tgSelected or not _tgSelected.Character then Notify("Copy Outfit","Select a player first!",2); return end
    local myChar, theirChar = LocalPlayer.Character, _tgSelected.Character
    if not myChar then Notify("Copy Outfit","No character!",2); return end
    local copied = 0
    pcall(function()
        local theirBC = theirChar:FindFirstChildOfClass("BodyColors")
        if theirBC then
            local myBC = myChar:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors", myChar)
            myBC.HeadColor3=theirBC.HeadColor3; myBC.TorsoColor3=theirBC.TorsoColor3
            myBC.LeftArmColor3=theirBC.LeftArmColor3; myBC.RightArmColor3=theirBC.RightArmColor3
            myBC.LeftLegColor3=theirBC.LeftLegColor3; myBC.RightLegColor3=theirBC.RightLegColor3
            copied = copied + 1
        end
    end)
    for _, cls in pairs({"Shirt","Pants"}) do
        pcall(function()
            local theirItem = theirChar:FindFirstChildOfClass(cls)
            if theirItem then
                local myItem = myChar:FindFirstChildOfClass(cls) or Instance.new(cls, myChar)
                if cls == "Shirt" then myItem.ShirtTemplate = theirItem.ShirtTemplate else myItem.PantsTemplate = theirItem.PantsTemplate end
                copied = copied + 1
            end
        end)
    end
    pcall(function()
        local myHead, theirHead = myChar:FindFirstChild("Head"), theirChar:FindFirstChild("Head")
        local theirFace = theirHead and theirHead:FindFirstChildOfClass("Decal")
        if myHead and theirFace then
            local myFace = myHead:FindFirstChildOfClass("Decal") or Instance.new("Decal", myHead)
            myFace.Name = "face"; myFace.Texture = theirFace.Texture
            copied = copied + 1
        end
    end)
    pcall(function()
        for _, acc in pairs(myChar:GetChildren()) do if acc:IsA("Accessory") then acc:Destroy() end end
        for _, acc in pairs(theirChar:GetChildren()) do
            if acc:IsA("Accessory") then pcall(function() acc:Clone().Parent = myChar end); copied = copied + 1 end
        end
    end)
    Notify("Copy Outfit","Copied "..copied.." item(s) — visible to you only",3)
end)
TG:AddButton("Reset My Outfit (Respawn)",function()
    local ok = pcall(function() LocalPlayer:LoadCharacter() end)
    if ok then Notify("Reset Outfit","Respawned with default outfit",2) else NotifyError("Reset Outfit","LoadCharacter not permitted here",3) end
end)

TG:AddSection("Info & Local Troll")
TG:AddButton("Show Player Info",function()
    if not _tgSelected then Notify("Player Info","Select a player first!",2); return end
    local t = _tgSelected
    local ok, accAge = pcall(function() return t.AccountAge end)
    local dist = "N/A"
    pcall(function()
        local myChar, theirChar = LocalPlayer.Character, t.Character
        if myChar and theirChar then
            local myRoot, theirRoot = GetRootPart(myChar), GetRootPart(theirChar)
            if myRoot and theirRoot then dist = math.floor((myRoot.Position-theirRoot.Position).Magnitude).."m" end
        end
    end)
    local teamName = "None"
    pcall(function() if t.Team then teamName = t.Team.Name end end)
    local msg = "UID: "..t.UserId.." | Age: "..(ok and tostring(accAge) or "?").."d | Team: "..teamName.." | Dist: "..dist
    Notify("Player Info: "..t.Name, msg, 6)
    print("[Phaze] Player Info — Name:"..t.Name.." Display:"..t.DisplayName.." "..msg)
end)
local _hiddenPlayers = {}
TG:AddButton("Toggle Hide (Local Only)",function()
    if not _tgSelected or not _tgSelected.Character then Notify("Hide Player","Select a player first!",2); return end
    local t = _tgSelected
    local hidden = _hiddenPlayers[t]
    for _, p in pairs(t.Character:GetDescendants()) do
        if p:IsA("BasePart") or p:IsA("Decal") then pcall(function() p.LocalTransparencyModifier = hidden and 0 or 1 end) end
    end
    _hiddenPlayers[t] = not hidden
    Notify("Hide Player",(not hidden and "Hidden " or "Unhidden ")..t.Name.." (your view only)",2)
end)

TG:AddSection("Prank (server-visible)")
TG:AddButton("Ragdoll/Spin Target (FE)",function()
    if not _tgSelected or not _tgSelected.Character then Notify("Ragdoll","Select a player first!",2); return end
    local t = _tgSelected
    Fling.TargetPlayer = t
    Fling.Enabled = true
    local started = _G._Funcs.FEFling(t)
    if started then
        Notify("Ragdoll","Spinning "..t.Name.."! (real physics push — not guaranteed on every game)",4)
        task.delay(3, function() Fling.Enabled = false end)
    else
        Fling.Enabled = false
        NotifyError("Ragdoll","Couldn't reach that player",2)
    end
end)

end

do local CB=AddCategory("Combat",8)
CB:AddToggle("Kill Aura",false,function(v) KillAura.Enabled=v; _G._Funcs.SetKillAura(v) end)
CB:AddSlider("KA Range",5,30,15,1," studs",function(v) KillAura.Range=v end)
CB:AddToggle("God Mode",false,function(v) AntiCheatBypass.GodMode=v; _G._Funcs.SetGodMode(v) end)
CB:AddToggle("One Hit Kill",false,function(v) OneHitKill.Enabled=v; _G._Funcs.SetOneHitKill(v) end)
CB:AddToggle("No Reload",false,function(v) _G._Funcs.SetNoReload(v) end)
CB:AddSection("Fling")
CB:AddToggle("Enable Fling",false,function(v) Fling.Enabled=v end)
CB:AddSlider("Fling Power",250,2000,750,50,"",function(v) Fling.Power=v end)
CB:AddButton("Execute Fling",function() if not Fling.Enabled then Notify("Error","Enable Fling first!",2); return end; local t=Fling.TargetPlayer or _G._Funcs.GetNearestPlayer(); if t then _G._Funcs.FEFling(t); Notify("Fling","Flinging "..t.Name,2) end end)
CB:AddButton("Fling All",function() _G._Funcs.FlingAllPlayers() end)

end

do local TR=AddCategory("Troll",9)
TR:AddInput("Message","Enter message",function(t) ServerTroll.ChatMessage=t end)
TR:AddToggle("Chat Spam",false,function(v) ServerTroll.ChatSpam=v; _G._Funcs.SetChatSpam(v) end)
TR:AddButton("Send Once",function() SendChatMessage(ServerTroll.ChatMessage) end)
TR:AddToggle("Remote Spam",false,function(v) ServerTroll.RemoteSpam=v; _G._Funcs.SetRemoteSpam(v) end)
TR:AddToggle("Tool Spam",false,function(v) ServerTroll.ToolSpam=v; _G._Funcs.SetToolSpam(v) end)
TR:AddSection("Self Prank (everyone in the server sees this)")
TR:AddToggle("Giant/Tiny Size",false,function(v) _G._Funcs.SetCustomScale(v) end)
TR:AddSlider("Size",30,300,100,10,"%",function(v) _G._Funcs.UpdateCustomScale(v/100) end)
TR:AddToggle("Random Ragdoll",false,function(v) _G._Funcs.SetRandomRagdoll(v) end)
TR:AddButton("Ragdoll Now (test)",function()
    local c = LocalPlayer.Character
    if not c then Notify("Ragdoll","No character!",2); return end
    _G._Funcs.DoRagdoll(c, true)
    Notify("Ragdoll","Ragdolled! Auto-recovers in 2.5s",2)
    task.delay(2.5, function() if c.Parent then _G._Funcs.DoRagdoll(c, false) end end)
end)
TR:AddSlider("Ragdoll Interval",2,30,5,1,"s",function(v) RandomRagdoll.Interval=v end)

end

do local AN=AddCategory("Anim",10)
for _,name in pairs({"Wave","Point","Dance","Dance2","Dance3","Laugh","Cheer"}) do AN:AddButton(name,function() _G._Funcs.PlayAnimation(_G._Funcs.AnimationsList[name],false) end) end
for _,name in pairs({"Ninja Run","Zombie","Astronaut","Robot","Floss","Default Dance","Spin"}) do AN:AddButton(name,function() _G._Funcs.PlayAnimation(_G._Funcs.AnimationsList[name],true) end) end
AN:AddButton("Stop Animation",function() _G._Funcs.StopAnimation() end)
end

do local RE=AddCategory("Remote",11)
RE:AddButton("Find Functions",function() local f=_G._Funcs.FindAllFunctions(); Notify("Remotes","Found "..(#f.RemoteEvents+#f.RemoteFunctions),3) end)
RE:AddDropdown("Select",{"Find first"},"Find first",function(o) for _,f in pairs(FoundFunctions.RemoteEvents) do if f.Name.." ["..f.Parent.."]"==o[1] then _G._Funcs.selectedFunction=f; break end end end)
local arg1=""
RE:AddInput("Arg 1","Argument",function(t) arg1=tonumber(t) or t end)
RE:AddButton("Execute",function() if _G._Funcs.selectedFunction then _G._Funcs.ExecuteFunction({arg1}) end end)
RE:AddButton("Refresh List",function() local f=_G._Funcs.FindAllFunctions(); local names=_G._Funcs.GetFunctionNames(); Notify("Remotes","Refreshed: "..#names.." found",3) end)

RE:AddSection("Remote Browser (Solara-Safe)")

local _rb_all = {}
local _rb_filtered = {}
local _rb_selected = nil
local _rb_filter = ""
local _rb_category = "all"
local _rb_writefile_local = _getFunc("writefile")

local _rb_categories = {
    combat   = {"shoot","fire","hit","damage","kill","bullet","attack","gun","weapon","melee","stab","punch"},
    reload   = {"reload","ammo","magazine","mag","clip","refill"},
    equip    = {"equip","unequip","tool","switch","select","inventory","backpack","hotbar"},
    movement = {"jump","run","sprint","dash","teleport","walk","speed","stamina"},
    health   = {"heal","health","revive","respawn","death","died","damage"},
    chat     = {"chat","say","message","whisper"},
    purchase = {"buy","purchase","shop","money","cash","coin","credit","gem"},
    network  = {"replicate","sync","update","sender","relay","stream"},
}

local function _rb_classify(name)
    local ln = name:lower()
    local hits = {}
    for cat, pats in pairs(_rb_categories) do
        for _, p in ipairs(pats) do
            if ln:find(p, 1, true) then hits[#hits+1] = cat; break end
        end
    end
    return hits
end

local function _rb_pathOf(inst)
    local path = ""
    local p = inst
    local depth = 0
    pcall(function()
        while p and depth < 8 do
            path = (path == "" and p.Name or (p.Name.."."..path))
            p = p.Parent
            depth = depth + 1
        end
    end)
    return path
end

local function _rb_scan()
    _rb_all = {}
    local seen = {}
    local yieldCounter = 0
    local function visit(root)
        pcall(function()
            for _, o in ipairs(root:GetDescendants()) do
                if not seen[o] then
                    local cls = ""
                    pcall(function() cls = o.ClassName end)
                    if cls == "RemoteEvent" or cls == "RemoteFunction" or cls == "UnreliableRemoteEvent" then
                        seen[o] = true
                        local nm = ""
                        pcall(function() nm = o.Name end)
                        _rb_all[#_rb_all+1] = {
                            ref = o, name = nm, class = cls,
                            path = _rb_pathOf(o),
                            cats = _rb_classify(nm),
                        }
                    end
                end
                yieldCounter = yieldCounter + 1
                if yieldCounter % 200 == 0 then task.wait() end
            end
        end)
    end
    visit(ReplicatedStorage)
    pcall(function() visit(game:GetService("ReplicatedFirst")) end)
    pcall(function() visit(workspace) end)
    pcall(function() visit(game:GetService("Players")) end)

    table.sort(_rb_all, function(a,b) return a.name:lower() < b.name:lower() end)
end

local function _rb_applyFilter()
    _rb_filtered = {}
    local f = _rb_filter:lower()
    for _, r in ipairs(_rb_all) do
        local catOk = (_rb_category == "all")
        if not catOk then
            for _, c in ipairs(r.cats) do if c == _rb_category then catOk = true; break end end
        end
        if catOk then
            if f == "" or r.name:lower():find(f, 1, true) then
                _rb_filtered[#_rb_filtered+1] = r
            end
        end
    end
end

local function _rb_print(maxN)
    if #_rb_filtered == 0 then Notify("Remote","No matches",2); return end
    print("===== PHAZE REMOTE BROWSER ===== ("..#_rb_filtered.." matches, cat="..tostring(_rb_category)..", filter='".._rb_filter.."')")
    local lim = math.min(maxN or 40, #_rb_filtered)
    for i = 1, lim do
        local r = _rb_filtered[i]
        local catStr = #r.cats > 0 and (" {"..table.concat(r.cats, ",").."}") or ""
        print(string.format("%d. [%s] %s%s", i, r.class:sub(1,12), r.path, catStr))
    end
    print("===== END (showing "..lim.."/"..#_rb_filtered..") =====")
end

local function _rb_parseArgs(text)

    if not text or text == "" then return {} end

    local tokens = {}
    local buf, depth, inStr = "", 0, false
    for i = 1, #text do
        local c = text:sub(i,i)
        if c == '"' then inStr = not inStr; buf = buf..c
        elseif not inStr and (c == "(" or c == "{") then depth = depth + 1; buf = buf..c
        elseif not inStr and (c == ")" or c == "}") then depth = depth - 1; buf = buf..c
        elseif not inStr and depth == 0 and c == "," then tokens[#tokens+1] = buf; buf = ""
        else buf = buf..c end
    end
    if buf ~= "" then tokens[#tokens+1] = buf end
    local out = {}
    for _, token in ipairs(tokens) do
        local t = token:match("^%s*(.-)%s*$")
        if t == "" then

        elseif t == "nil" then out[#out+1] = nil
        elseif t == "true" then out[#out+1] = true
        elseif t == "false" then out[#out+1] = false
        elseif t == "lp" then out[#out+1] = LocalPlayer
        elseif t == "char" then out[#out+1] = LocalPlayer.Character
        elseif t == "hrp" then
            local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            out[#out+1] = h
        elseif t == "mouse" then
            out[#out+1] = LocalPlayer:GetMouse().Hit.Position
        elseif t:sub(1,4) == "vec(" then
            local x,y,z = t:match("vec%(([^,]+),([^,]+),([^,]+)%)")
            if x then out[#out+1] = Vector3.new(tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0) end
        elseif t:sub(1,1) == '"' and t:sub(-1) == '"' then
            out[#out+1] = t:sub(2,-2)
        elseif tonumber(t) then
            out[#out+1] = tonumber(t)
        else
            out[#out+1] = t
        end
    end
    return out
end

local _rb_argText = ""
local _rb_lastReturn = nil
local _spyLog = {}
local _spyEnabled = false
local _spyHooked = false
local _spyFilter = ""

task.spawn(function() _rb_scan(); _rb_applyFilter() end)

RE:AddButton("Rescan Remotes", function()
    _rb_scan()
    _rb_applyFilter()
    Notify("Remote","Found "..#_rb_all.." remotes ("..#_rb_filtered.." after filter)",3)
end)

RE:AddDropdown("Category", {"all","combat","reload","equip","movement","health","chat","purchase","network"}, "all", function(o)
    _rb_category = o[1] or "all"
    _rb_applyFilter()
    Notify("Remote",#_rb_filtered.." match cat="..tostring(_rb_category),3)
end)

RE:AddInput("Name contains", "", function(t)
    _rb_filter = t or ""
    _rb_applyFilter()
end)

RE:AddButton("Print Matches", function()
    _rb_print(40)
    Notify("Remote","Printed "..math.min(40,#_rb_filtered).." to F9",3)
end)

RE:AddButton("Save Matches to File", function()
    if #_rb_filtered == 0 then NotifyError("Remote","No matches",3); return end
    if not _rb_writefile_local then NotifyError("Remote","writefile not available",3); return end
    local lines = {}
    for i, r in ipairs(_rb_filtered) do
        local catStr = #r.cats > 0 and (" {"..table.concat(r.cats, ",").."}") or ""
        lines[i] = string.format("%d. [%s] %s%s", i, r.class, r.path, catStr)
    end
    local fname = "Phaze_Remotes_"..tostring(game.PlaceId)..".txt"
    pcall(_rb_writefile_local, fname, table.concat(lines, "\n"))
    Notify("Remote","Saved "..#lines.." to "..fname, 4)
end)

RE:AddSection("Select & Fire")

local _rb_selectIdx = 1
RE:AddInput("Select by # (from Print Matches)", "1", function(t)
    local n = tonumber(t)
    if n and _rb_filtered[n] then
        _rb_selectIdx = n
        _rb_selected = _rb_filtered[n]
        Notify("Remote","Selected: ".._rb_selected.path, 4)
    else
        NotifyError("Remote","No match at #"..tostring(t),3)
    end
end)

RE:AddButton("Pick First Match", function()
    if #_rb_filtered == 0 then NotifyError("Remote","No matches",3); return end
    _rb_selected = _rb_filtered[1]
    _rb_selectIdx = 1
    Notify("Remote","Selected: ".._rb_selected.path, 4)
end)

RE:AddButton("Show Selected Info", function()
    if not _rb_selected then NotifyError("Remote","Nothing selected",3); return end
    print("===== SELECTED REMOTE =====")
    print("Path : ".._rb_selected.path)
    print("Class: ".._rb_selected.class)
    print("Cats : "..(#_rb_selected.cats > 0 and table.concat(_rb_selected.cats, ", ") or "none"))
    print("==========================")
    Notify("Remote",_rb_selected.name.." ["..tostring(_rb_selected.class).."]",4)
end)

RE:AddInput("Args (e.g.  lp, mouse, 100, \"head\", vec(0,5,0))", "", function(t)
    _rb_argText = t or ""
end)

local function _rb_fire(extraArgs)
    if not _rb_selected then NotifyError("Remote","Nothing selected",3); return end
    local args = _rb_parseArgs(_rb_argText)
    if extraArgs then
        for _, v in ipairs(extraArgs) do args[#args+1] = v end
    end
    local r = _rb_selected.ref
    local cls = _rb_selected.class
    local ok, err = pcall(function()
        if cls == "RemoteFunction" then
            _rb_lastReturn = r:InvokeServer(table.unpack(args))
        else
            r:FireServer(table.unpack(args))
        end
    end)
    if ok then
        Notify("Remote","Fired ".._rb_selected.name.." ("..#args.." args)", 3)
        if cls == "RemoteFunction" then
            print("[Phaze RB] return = ", _rb_lastReturn)
        end
    else
        NotifyError("Remote","Fail: "..tostring(err), 5)
    end
end

RE:AddButton("Fire / Invoke (with args)", function() _rb_fire(nil) end)
RE:AddButton("Fire (no args)", function()
    if not _rb_selected then NotifyError("Remote","Nothing selected",3); return end
    local r = _rb_selected.ref; local cls = _rb_selected.class
    local ok, err = pcall(function()
        if cls == "RemoteFunction" then _rb_lastReturn = r:InvokeServer() else r:FireServer() end
    end)
    if ok then Notify("Remote","Fired (empty)",2) else NotifyError("Remote",tostring(err),4) end
end)

RE:AddButton("Fire 10x rapid", function()
    if not _rb_selected then NotifyError("Remote","Nothing selected",3); return end
    local r = _rb_selected.ref; local cls = _rb_selected.class
    local args = _rb_parseArgs(_rb_argText)
    task.spawn(function()
        for i = 1, 10 do
            pcall(function()
                if cls == "RemoteFunction" then r:InvokeServer(table.unpack(args))
                else r:FireServer(table.unpack(args)) end
            end)
            task.wait(0.05)
        end
        Notify("Remote","10 fires sent",2)
    end)
end)

RE:AddButton("Fire on every player (target=lp slot)", function()
    if not _rb_selected then NotifyError("Remote","Nothing selected",3); return end

    local r = _rb_selected.ref; local cls = _rb_selected.class
    local raw = _rb_argText
    local count = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then

            local subbed = raw
            local args = {}
            for token in subbed:gmatch("[^,]+") do
                local t = token:match("^%s*(.-)%s*$")
                if t == "lp" then args[#args+1] = plr
                elseif t == "char" then args[#args+1] = plr.Character
                elseif t == "hrp" then args[#args+1] = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                else

                    local one = _rb_parseArgs(t)
                    if one[1] ~= nil then args[#args+1] = one[1] end
                end
            end
            pcall(function()
                if cls == "RemoteFunction" then r:InvokeServer(table.unpack(args))
                else r:FireServer(table.unpack(args)) end
            end)
            count = count + 1
        end
    end
    Notify("Remote","Fired on "..count.." players",3)
end)

RE:AddSection("Decompile (find combat payloads)")

local _decompile = _getFunc("decompile")
local _getscripts = _getFunc("getscripts") or _getFunc("get_scripts")
local _getnilinstances = _getFunc("getnilinstances")
local _rb_decompKeyword = "Replicate"

RE:AddInput("Search scripts for keyword", "Replicate:FireServer", function(t)
    _rb_decompKeyword = t or ""
end)

RE:AddButton("Find Scripts Using Keyword", function()
    if not _decompile then NotifyError("Decompile","decompile() not available on this exec",5); return end
    if not _getscripts then NotifyError("Decompile","getscripts() not available",5); return end
    if _rb_decompKeyword == "" then NotifyError("Decompile","Enter a keyword first",3); return end
    local hits = {}
    local scripts = {}
    pcall(function() scripts = _getscripts() end)
    print("===== DECOMPILE SEARCH ===== keyword='".._rb_decompKeyword.."' ("..#scripts.." scripts)")
    local kw = _rb_decompKeyword:lower()
    local checked = 0
    task.spawn(function()
        for i, s in ipairs(scripts) do
            checked = checked + 1
            pcall(function()
                if s and (s.ClassName == "LocalScript" or s.ClassName == "ModuleScript") then
                    local src = _decompile(s)
                    if src and src:lower():find(kw, 1, true) then
                        local path = ""
                        pcall(function() path = s:GetFullName() end)
                        hits[#hits+1] = {script = s, path = path, src = src}
                        print("HIT #"..#hits..": "..path.." (size="..#src..")")
                    end
                end
            end)
            if i % 20 == 0 then task.wait() end
        end
        _G._rb_decompHits = hits
        print("===== DONE: "..#hits.." matches out of "..checked.." scripts =====")
        Notify("Decompile","Found "..#hits.." scripts. Use 'Dump Hit #N'",5)
    end)
end)

local _rb_dumpIdx = 1
RE:AddInput("Dump hit # (after search)", "1", function(t) _rb_dumpIdx = tonumber(t) or 1 end)

RE:AddButton("Dump Hit # to File", function()
    local hits = _G._rb_decompHits
    if not hits or #hits == 0 then NotifyError("Decompile","No hits. Search first.",3); return end
    local h = hits[_rb_dumpIdx]
    if not h then NotifyError("Decompile","No hit #".._rb_dumpIdx,3); return end
    if not _rb_writefile_local then NotifyError("Decompile","writefile not available",3); return end
    local fname = "Phaze_Decomp_"..tostring(_rb_dumpIdx).."_"..tostring(game.PlaceId)..".lua"
    pcall(_rb_writefile_local, fname, "-- "..h.path.."\n\n"..h.src)
    Notify("Decompile","Saved "..fname.." ("..#h.src.." bytes)",5)
    print("[Decompile] Saved hit #".._rb_dumpIdx.." ("..h.path..") to "..fname)
end)

RE:AddButton("Print Hit # Lines Containing Keyword", function()
    local hits = _G._rb_decompHits
    if not hits or #hits == 0 then NotifyError("Decompile","No hits. Search first.",3); return end
    local h = hits[_rb_dumpIdx]
    if not h then NotifyError("Decompile","No hit #".._rb_dumpIdx,3); return end
    local kw = _rb_decompKeyword:lower()
    print("===== ".._rb_dumpIdx..": "..h.path.." -- lines with '".._rb_decompKeyword.."' =====")
    local lineNum = 0
    local shown = 0
    for line in h.src:gmatch("[^\n]+") do
        lineNum = lineNum + 1
        if line:lower():find(kw, 1, true) then
            shown = shown + 1
            print(string.format("L%d: %s", lineNum, line))
            if shown >= 50 then print("(stopped at 50)") break end
        end
    end
    print("===== END =====")
    Notify("Decompile","Printed "..shown.." lines",4)
end)

RE:AddButton("List All Hits", function()
    local hits = _G._rb_decompHits
    if not hits or #hits == 0 then NotifyError("Decompile","No hits. Search first.",3); return end
    print("===== HITS =====")
    for i, h in ipairs(hits) do print(i..". "..h.path.." ("..#h.src.." bytes)") end
    print("===== END =====")
end)

RE:AddButton("Search PlayerScripts ONLY", function()
    if not _decompile then NotifyError("Decompile","decompile() not available",4); return end
    if _rb_decompKeyword == "" then NotifyError("Decompile","Enter keyword",3); return end
    local roots = {}
    pcall(function() roots[#roots+1] = LocalPlayer:WaitForChild("PlayerScripts", 2) end)
    pcall(function() roots[#roots+1] = LocalPlayer:WaitForChild("PlayerGui", 2) end)
    pcall(function() roots[#roots+1] = ReplicatedStorage end)
    pcall(function() roots[#roots+1] = game:GetService("ReplicatedFirst") end)
    local scripts = {}
    for _, r in ipairs(roots) do
        if r then
            pcall(function()
                for _, d in ipairs(r:GetDescendants()) do
                    if d:IsA("LocalScript") or d:IsA("ModuleScript") then
                        scripts[#scripts+1] = d
                    end
                end
            end)
        end
    end
    print("===== SEARCH PlayerScripts/PlayerGui/RS ===== keyword='".._rb_decompKeyword.."' ("..#scripts.." scripts)")
    local kw = _rb_decompKeyword:lower()
    local hits = {}
    task.spawn(function()
        for i, s in ipairs(scripts) do
            pcall(function()
                local src = _decompile(s)
                if src and src:lower():find(kw, 1, true) then
                    local path = ""
                    pcall(function() path = s:GetFullName() end)
                    hits[#hits+1] = {script = s, path = path, src = src}
                    print("HIT #"..#hits..": "..path.." (size="..#src..")")
                end
            end)
            if i % 15 == 0 then task.wait() end
        end
        _G._rb_decompHits = hits
        print("===== DONE: "..#hits.." matches =====")
        Notify("Decompile","PlayerScripts done: "..#hits.." hits",5)
    end)
end)

RE:AddButton("Check Mouse APIs (for aimbot)", function()
    local apis = {"mousemoverel","mouse_moverel","mousemoveabs","mouse_move","setmouseposition","mouse1click","mouse1press","mouse1release"}
    print("===== MOUSE API CHECK =====")
    for _, n in ipairs(apis) do
        local f = _getFunc(n)
        print("  "..n..":", f and "YES" or "NO")
    end
    print("===== END =====")
    local has = _getFunc("mousemoverel") or _getFunc("mouse_moverel")
    Notify("API", has and "mousemoverel: YES (Rivals aimbot possible)" or "mousemoverel: NO (cant aim in Rivals)", 6)
end)

RE:AddButton("Check Decompile Available", function()
    print("decompile():", _decompile and "YES" or "NO")
    print("getscripts():", _getscripts and "YES" or "NO")
    print("getnilinstances():", _getnilinstances and "YES" or "NO")
    print("writefile():", _rb_writefile_local and "YES" or "NO")
    Notify("Decompile","decomp:"..(_decompile and "Y" or "N").." scripts:".. (_getscripts and "Y" or "N"),4)
end)

RE:AddSection("Help (arg syntax)")
RE:AddButton("Print Arg Syntax Help", function()
    print("===== PHAZE REMOTE BROWSER - ARG SYNTAX =====")
    print('  Comma-separated. Examples:')
    print('  lp                 -> LocalPlayer')
    print('  char               -> LocalPlayer.Character')
    print('  hrp                -> LocalPlayer HumanoidRootPart')
    print('  mouse              -> Mouse.Hit.Position (Vector3)')
    print('  vec(0,5,10)        -> Vector3(0,5,10)')
    print('  "Head"             -> string "Head"')
    print('  42  3.14  true  false  nil')
    print('  Bare word          -> raw string')
    print('Example:  lp, "Head", 100, vec(0,0,0)')
    print('=============================================')
    Notify("Remote","Help printed to F9",3)
end)

if false then
local function _spyLogCall(kind, remote, args)
    if not _spyEnabled then return end

    local ok, name = pcall(function() return remote.Name end)
    if not ok then return end
    if _spyFilter ~= "" and not name:lower():find(_spyFilter:lower(), 1, true) then return end

    local path = name
    pcall(function()
        local p = remote.Parent
        local depth = 0
        while p and depth < 5 do
            path = p.Name.."."..path
            p = p.Parent
            depth = depth + 1
        end
    end)
    local parts = {}
    for i = 1, #args do parts[i] = _spyFormat(args[i]) end
    local line = "["..kind.."] "..path.."("..table.concat(parts, ", ")..")"
    table.insert(_spyLog, 1, line)
    if #_spyLog > 50 then table.remove(_spyLog) end
    pcall(function() print("[Phaze Spy]", line) end)
end
local function _installSpy()
    if _spyHooked then return true end
    if not _newcclosure then return false end

    if _hookmetamethod then
        local ok = pcall(function()
            local oldNc
            oldNc = _hookmetamethod(game, "__namecall", _newcclosure(function(self, ...)
                if not _spyEnabled then return oldNc(self, ...) end
                local m = _getnamecallmethod and _getnamecallmethod() or ""

                if m ~= "FireServer" and m ~= "InvokeServer" then return oldNc(self, ...) end
                if _checkcaller and _checkcaller() then return oldNc(self, ...) end

                _spyQueue = _spyQueue or {}
                if #_spyQueue < 100 then
                    _spyQueue[#_spyQueue + 1] = {m = m, self = self, args = {...}}
                end
                return oldNc(self, ...)
            end))
        end)
        if ok then
            _spyHooked = true

            task.spawn(function()
                while _spyHooked do
                    if _spyQueue and #_spyQueue > 0 then
                        local batch = _spyQueue
                        _spyQueue = {}
                        for _, e in ipairs(batch) do
                            pcall(function()
                                if typeof(e.self) == "Instance" then
                                    local cls = e.self.ClassName
                                    if cls == "RemoteEvent" or cls == "RemoteFunction" or cls == "UnreliableRemoteEvent" then
                                        _spyLogCall(e.m, e.self, e.args)
                                    end
                                end
                            end)
                        end
                    end
                    task.wait(0.1)
                end
            end)
            return true
        end
    end

    if _hookfunction then
        local ok = pcall(function()

            local tmpEv = Instance.new("RemoteEvent")
            local oldFire
            oldFire = _hookfunction(tmpEv.FireServer, _newcclosure(function(self, ...)
                local args = {...}
                if _spyEnabled and not (_checkcaller and _checkcaller()) then
                    pcall(function()
                        if typeof(self) == "Instance" then _spyLogCall("FireServer", self, args) end
                    end)
                end
                return oldFire(self, ...)
            end))
            tmpEv:Destroy()

            local tmpFn = Instance.new("RemoteFunction")
            local oldInv
            oldInv = _hookfunction(tmpFn.InvokeServer, _newcclosure(function(self, ...)
                local args = {...}
                if _spyEnabled and not (_checkcaller and _checkcaller()) then
                    pcall(function()
                        if typeof(self) == "Instance" then _spyLogCall("InvokeServer", self, args) end
                    end)
                end
                return oldInv(self, ...)
            end))
            tmpFn:Destroy()

            pcall(function()
                local tmpU = Instance.new("UnreliableRemoteEvent")
                local oldU
                oldU = _hookfunction(tmpU.FireServer, _newcclosure(function(self, ...)
                    local args = {...}
                    if _spyEnabled and not (_checkcaller and _checkcaller()) then
                        pcall(function()
                            if typeof(self) == "Instance" then _spyLogCall("FireServer(Unreliable)", self, args) end
                        end)
                    end
                    return oldU(self, ...)
                end))
                tmpU:Destroy()
            end)
        end)
        if ok then _spyHooked = true; return true end
    end

    return false
end
RE:AddToggle("Enable Remote Spy", false, function(v)
    _spyEnabled = v
    if v then
        if not _installSpy() then
            local diag = "hookmeta:"..(_hookmetamethod and "Y" or "N").." newcc:"..(_newcclosure and "Y" or "N")
            NotifyError("Spy", diag, 6)
            print("[Phaze Spy] Hook unavailable. "..diag)
            return
        end
        Notify("Spy","Logging to console + buffer",3)
    end
end)
RE:AddInput("Filter (name contains)", "", function(t) _spyFilter = t or "" end)
RE:AddButton("Print Last 20", function()
    if #_spyLog == 0 then Notify("Spy","Log is empty",2); return end
    print("===== PHAZE REMOTE SPY ===== ("..#_spyLog.." entries)")
    for i = 1, math.min(20, #_spyLog) do print(i..". ".._spyLog[i]) end
    Notify("Spy","Printed "..math.min(20,#_spyLog).." to console",3)
end)
RE:AddButton("Copy Log to Clipboard", function()
    if #_spyLog == 0 then NotifyError("Spy","Log is empty - shoot/reload first!",4); return end
    local text = table.concat(_spyLog, "\n")

    local apis = {"setclipboard","toclipboard","set_clipboard","writeclipboard","Clipboard"}
    local copied = false
    for _, n in pairs(apis) do
        local sc = _getFunc(n)
        if sc then
            local ok = pcall(sc, text)
            if ok then copied = true; break end
        end
    end

    pcall(function() if syn and syn.write_clipboard then syn.write_clipboard(text); copied = true end end)
    pcall(function() if Solara and Solara.setclipboard then Solara.setclipboard(text); copied = true end end)

    pcall(function()
        if _writefile then _writefile("Phaze_SpyLog.txt", text) end
    end)
    print("===== PHAZE SPY LOG ("..#_spyLog.." entries) =====")
    for i = 1, #_spyLog do print(i..". ".._spyLog[i]) end
    print("===== END =====")
    if copied then
        Notify("Spy","Copied "..#_spyLog.." lines + saved to Phaze_SpyLog.txt + F9",4)
    else
        Notify("Spy","Clipboard blocked - saved to Phaze_SpyLog.txt + printed to F9 instead",5)
    end
end)
RE:AddButton("Clear Log", function() _spyLog = {}; Notify("Spy","Cleared",2) end)
RE:AddButton("LIST EXECUTOR APIs", function()
    print("===== EXECUTOR API DUMP =====")
    local found = {}
    local function scan(tbl, label)
        if not tbl then return end
        pcall(function()
            for k, v in pairs(tbl) do
                if type(v) == "function" and type(k) == "string" then
                    local lk = k:lower()
                    if lk:find("hook") or lk:find("meta") or lk:find("namecall") or lk:find("closure") or lk:find("clip") or lk:find("file") or lk:find("readonly") then
                        if not found[k] then found[k] = label end
                    end
                end
            end
        end)
    end
    pcall(function() scan(getgenv(), "getgenv") end)
    pcall(function() scan(_G, "_G") end)
    pcall(function() scan(getfenv(), "getfenv") end)
    for k, v in pairs(found) do print("  "..k.." ["..v.."]") end
    print("===== END =====")
    Notify("API","Dumped "..(next(found) and "found APIs" or "NO APIs").." to F9",4)
end)
RE:AddButton("TEST HOOK (self-test)", function()
    if not _spyEnabled then NotifyError("Spy","Enable spy first",3); return end
    local prevFilter = _spyFilter
    _spyFilter = ""
    local tested = false
    pcall(function()
        local r = Instance.new("RemoteEvent")
        r.Name = "PhazeSpyTest"
        r.Parent = ReplicatedStorage
        local before = #_spyLog
        r:FireServer("test_arg_1", 42, Vector3.new(1,2,3))
        task.wait(0.1)
        local after = #_spyLog
        tested = after > before
        r:Destroy()
        print("[Phaze Spy] Self-test: hook caught", after-before, "events. Total log:", after)
        if tested then
            Notify("Spy","HOOK WORKING - caught test event",4)
        else
            NotifyError("Spy","Hook DEAD - Xeno doesn't intercept namecall via hookfunction",6)
            print("[Phaze Spy] Hook does NOT intercept :FireServer() namecall on this executor.")
            print("[Phaze Spy] You need an executor with hookmetamethod for remote spying.")
        end
    end)
    _spyFilter = prevFilter
end)
end
end

do local SN=AddCategory("Sound",12)
local selectedSound="Nuke Alarm"
local _soundLoop = false
SN:AddDropdown("Sound",{"Nuke Alarm","Bruh","Oof","Windows XP","Vine Boom","Discord Ping","Rickroll","Scary","Nokia","Siren"},"Nuke Alarm",function(o) selectedSound=o[1] end)
SN:AddSlider("Volume",0,100,50,5,"%",function(v) FESounds.Volume=v/100 end)
SN:AddToggle("Loop (server hears it non-stop)",false,function(v) _soundLoop=v end)
SN:AddButton("Play",function() local id=_G._Funcs.SoundList[selectedSound]; if id then _G._Funcs.PlayFESound(id,FESounds.Volume,FESounds.PlaybackSpeed,_soundLoop) end end)
SN:AddButton("Stop",function() _G._Funcs.StopFESound() end)
end

do local IT=AddCategory("Items",13)
IT:AddButton("Give All Items (FE)",function()
    local c=0
    local seen={}
    local function sc(p)
        if not p then return end
        for _,o in pairs(p:GetDescendants()) do
            if (o:IsA("Tool") or o:IsA("HopperBin")) and not seen[o] then
                seen[o]=true
                pcall(function() o:Clone().Parent=LocalPlayer.Backpack; c=c+1 end)
            end
        end
    end
    sc(ReplicatedStorage); sc(game:GetService("Lighting")); sc(workspace)
    pcall(function() sc(Players:FindFirstChild("StarterPack") or game:GetService("StarterPack")) end)
    for _, p in pairs(Players:GetPlayers()) do
        pcall(function() sc(p.Backpack) end)
        if p.Character then sc(p.Character) end
    end
    if c > 0 then
        Notify("Items","Got "..c.." item(s) — visible to you only, others can't see you holding them (client-cloned tools never replicate)",5)
    else
        NotifyError("Items","Found 0 tools anywhere client-visible. This game likely keeps its real tools in ServerStorage, which no client script can ever read — that's not fixable from here.",6)
    end
end)
IT:AddButton("Get Workspace Tools",function()
    local c = 0
    local yieldCounter = 0
    for _, o in pairs(workspace:GetDescendants()) do
        if o:IsA("Tool") then
            pcall(function() o:Clone().Parent = LocalPlayer.Backpack; c = c + 1 end)
        end
        yieldCounter = yieldCounter + 1
        if yieldCounter % 150 == 0 then task.wait() end
    end
    if c > 0 then Notify("Items", c.." tool(s) — visible to you only", 3)
    else NotifyError("Items", "No tools found in Workspace", 3) end
end)
end

do local PT=AddCategory("Paint",14)

PT:AddSection("Face Changer (real FE — everyone sees this)")
local _faceIdInput = ""
PT:AddInput("Decal/Image Asset ID","e.g. 123456789 or full rbxassetid://...",function(text) _faceIdInput = text end)
PT:AddButton("Apply as Face",function()
    local raw = _faceIdInput
    if not raw or raw == "" then Notify("Face","Paste a Roblox decal/image asset ID first",3); return end
    local assetUri = raw
    if not raw:match("^rbxassetid://") then
        local digits = raw:match("%d+")
        if not digits then Notify("Face","That doesn't look like a valid asset ID",3); return end
        assetUri = "rbxassetid://"..digits
    end
    local c = LocalPlayer.Character
    if not c then Notify("Face","No character!",2); return end
    local head = c:FindFirstChild("Head")
    if not head then Notify("Face","No head found!",2); return end
    local ok = pcall(function()
        local decal = head:FindFirstChildOfClass("Decal")
        if not decal then decal = Instance.new("Decal"); decal.Name="face"; decal.Parent=head end
        decal.Texture = assetUri
    end)
    if ok then Notify("Face","Applied! This is a real property change on your own character — the whole server sees it.",5)
    else NotifyError("Face","Failed to apply",3) end
end)
PT:AddButton("Reset Face (Respawn)",function()
    local ok = pcall(function() LocalPlayer:LoadCharacter() end)
    if ok then Notify("Face","Respawned with default face",2) else NotifyError("Face","LoadCharacter not permitted here",3) end
end)

local CANVAS_RES = 128
local _paintImg = nil
local _paintOk = pcall(function()
    _paintImg = Instance.new("EditableImage")
    _paintImg.Size = Vector2.new(CANVAS_RES, CANVAS_RES)
end)
if _paintOk then
    pcall(function()
        local white = {}
        for i=1,CANVAS_RES*CANVAS_RES*4 do white[i] = 255 end
        _paintImg:WritePixels(Vector2.new(0,0), Vector2.new(CANVAS_RES,CANVAS_RES), white)
    end)
end

local _paintColor = Color3.fromRGB(20,20,20)
local _brushSize = 4
local _painting = false

local function _paintDab(px, py)
    if not _paintOk then return end
    local half = math.floor(_brushSize/2)
    local x0 = math.clamp(px-half, 0, CANVAS_RES-1)
    local y0 = math.clamp(py-half, 0, CANVAS_RES-1)
    local w = math.clamp(_brushSize, 1, CANVAS_RES-x0)
    local h = math.clamp(_brushSize, 1, CANVAS_RES-y0)
    local pixels = {}
    local r,g,b = math.floor(_paintColor.R*255), math.floor(_paintColor.G*255), math.floor(_paintColor.B*255)
    for i=1,w*h do
        pixels[#pixels+1]=r; pixels[#pixels+1]=g; pixels[#pixels+1]=b; pixels[#pixels+1]=255
    end
    pcall(function() _paintImg:WritePixels(Vector2.new(x0,y0), Vector2.new(w,h), pixels) end)
end

if not _paintOk then
    PT:AddSection("Skin Paint (local-only freehand — unavailable)")
    PT:AddCustom(function(parent, idx)
        local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,60); row.BackgroundColor3=Color3.fromRGB(30,18,18); row.BackgroundTransparency=0.3; row.BorderSizePixel=0; row.LayoutOrder=idx; row.Parent=parent
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
        local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-20,1,0); lbl.Position=UDim2.new(0,10,0,0); lbl.BackgroundTransparency=1; lbl.TextWrapped=true; lbl.Text="Your executor doesn't support EditableImage — freehand paint isn't available here. Use Face Changer above instead (that one actually works and is real FE)."; lbl.Font=FONT_MED; lbl.TextSize=11; lbl.TextColor3=Color3.fromRGB(255,140,140)
    end)
else
    PT:AddSection("Skin Paint (local-only freehand, draws on your face)")
    PT:AddCustom(function(parent, idx)
        local wrap=Instance.new("Frame"); wrap.Size=UDim2.new(1,0,0,CANVAS_RES+8); wrap.BackgroundTransparency=1; wrap.LayoutOrder=idx; wrap.Parent=parent
        local canvasHolder=Instance.new("Frame"); canvasHolder.Size=UDim2.new(0,CANVAS_RES,0,CANVAS_RES); canvasHolder.Position=UDim2.new(0.5,-CANVAS_RES/2,0,4); canvasHolder.BackgroundColor3=Color3.fromRGB(255,255,255); canvasHolder.BorderSizePixel=0; canvasHolder.Parent=wrap
        Instance.new("UICorner",canvasHolder).CornerRadius=UDim.new(0,6)
        local canvasStroke=Instance.new("UIStroke",canvasHolder); canvasStroke.Color=DIVIDER_COL; canvasStroke.Thickness=1; canvasStroke.Transparency=0.2
        local img=Instance.new("ImageLabel",canvasHolder); img.Size=UDim2.new(1,0,1,0); img.BackgroundTransparency=1; img.Image=""; img.ScaleType=Enum.ScaleType.Stretch
        pcall(function() _paintImg.Parent = img end)
        pcall(function() if Content and Content.fromObject then img.ImageContent = Content.fromObject(_paintImg) end end)
        local hitbox=Instance.new("TextButton",canvasHolder); hitbox.Size=UDim2.new(1,0,1,0); hitbox.BackgroundTransparency=1; hitbox.Text=""; hitbox.ZIndex=5

        local function paintAt(x,y)
            local abs = img.AbsolutePosition
            local size = img.AbsoluteSize
            if size.X <= 0 or size.Y <= 0 then return end
            local u = math.clamp((x - abs.X) / size.X, 0, 1)
            local v = math.clamp((y - abs.Y) / size.Y, 0, 1)
            _paintDab(math.floor(u*CANVAS_RES), math.floor(v*CANVAS_RES))
        end

        hitbox.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                _painting = true
                paintAt(inp.Position.X, inp.Position.Y)
            end
        end)
        hitbox.InputChanged:Connect(function(inp)
            if _painting and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
                paintAt(inp.Position.X, inp.Position.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                _painting = false
            end
        end)
    end)

    PT:AddSection("Colors")
    local palette = {
        Color3.fromRGB(20,20,20), Color3.fromRGB(255,255,255), Color3.fromRGB(235,60,60),
        Color3.fromRGB(255,150,30), Color3.fromRGB(255,220,50), Color3.fromRGB(60,200,90),
        Color3.fromRGB(60,140,255), Color3.fromRGB(160,80,230), Color3.fromRGB(255,120,190),
        Color3.fromRGB(120,80,50),
    }
    PT:AddCustom(function(parent, idx)
        local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,34); row.BackgroundTransparency=1; row.LayoutOrder=idx; row.Parent=parent
        local layout=Instance.new("UIListLayout",row); layout.FillDirection=Enum.FillDirection.Horizontal; layout.Padding=UDim.new(0,6); layout.VerticalAlignment=Enum.VerticalAlignment.Center
        Instance.new("UIPadding",row).PaddingLeft=UDim.new(0,14)
        for _, col in ipairs(palette) do
            local sw=Instance.new("TextButton",row); sw.Size=UDim2.new(0,24,0,24); sw.BackgroundColor3=col; sw.Text=""; sw.BorderSizePixel=0
            Instance.new("UICorner",sw).CornerRadius=UDim.new(1,0)
            local swStroke=Instance.new("UIStroke",sw); swStroke.Color=Color3.fromRGB(90,90,95); swStroke.Thickness=1.5; swStroke.Transparency=0.2
            sw.MouseButton1Click:Connect(function() _paintColor = col end)
        end
    end)
    PT:AddSlider("Brush Size",1,12,4,1,"px",function(v) _brushSize=v end)

    PT:AddSection("Actions")
    PT:AddButton("Clear Canvas",function()
        pcall(function()
            local white = {}
            for i=1,CANVAS_RES*CANVAS_RES*4 do white[i] = 255 end
            _paintImg:WritePixels(Vector2.new(0,0), Vector2.new(CANVAS_RES,CANVAS_RES), white)
        end)
        Notify("Paint","Canvas cleared",2)
    end)
    PT:AddButton("Apply to Face",function()
        local c = LocalPlayer.Character
        if not c then Notify("Paint","No character!",2); return end
        local head = c:FindFirstChild("Head")
        if not head then Notify("Paint","No head found!",2); return end
        local ok = pcall(function()
            local decal = head:FindFirstChildOfClass("Decal")
            if not decal then decal = Instance.new("Decal"); decal.Name="face"; decal.Parent=head end
            local clone = _paintImg:Clone()
            for _, ch in pairs(decal:GetChildren()) do if ch:IsA("EditableImage") then ch:Destroy() end end
            clone.Parent = decal
            pcall(function() if Content and Content.fromObject then decal.TextureContent = Content.fromObject(clone) end end)
        end)
        if ok then Notify("Paint","Applied to your face (visible to you only — EditableImage doesn't replicate)",4)
        else NotifyError("Paint","Couldn't apply — this game/executor may block it",3) end
    end)
end
end

if game.PlaceId == 79268393072444 then
do local LF=AddCategory("Lemon Farm",15)
LF:AddSection("Status")
local _lfStatusLabel = nil
LF:AddCustom(function(parent)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,24)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(200,200,208)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "Tycoon: not detected"
    lbl.Parent = parent
    _lfStatusLabel = lbl
end)
LF:AddButton("Detect My Tycoon",function()
    local t = _G._Funcs.GetMyTycoon()
    if t then
        Notify("Lemon Farm","Found your tycoon: "..t.Name,3)
        if _lfStatusLabel then _lfStatusLabel.Text = "Tycoon: "..t.Name end
    else
        NotifyError("Lemon Farm","Couldn't find a Tycoon owned by you (claim a base first)",3)
        if _lfStatusLabel then _lfStatusLabel.Text = "Tycoon: not found" end
    end
end)

LF:AddSection("Automation")
LF:AddToggle("Enable Auto-Farm",false,function(v) _G._Funcs.SetLemonFarm(v) end)
LF:AddToggle("Auto-Collect Fruit (Click Lemons)",true,function(v) _G._Funcs.LemonFarm.AutoFruit=v end)
LF:AddToggle("Auto Plant/Harvest Orchard",true,function(v) _G._Funcs.LemonFarm.AutoOrchard=v end)
LF:AddToggle("Auto-Buy (Buildings/Decor)",false,function(v) _G._Funcs.LemonFarm.AutoBuy=v end)
LF:AddToggle("Auto-Upgrade (Stand/Trading/etc)",false,function(v) _G._Funcs.LemonFarm.AutoUpgrade=v end)
LF:AddSlider("Loop Delay",0.2,5,1,0.1,"s",function(v) _G._Funcs.LemonFarm.Delay=v end)

LF:AddSection("Debug / Test Once")
LF:AddButton("Test Buy Now (1 pass)",function()
    local t = _G._Funcs.GetMyTycoon()
    if not t then NotifyError("Lemon Farm","Tycoon not found",3); return end
    local ok_n, fail_n, skip_n, deny_n, err = _G._Funcs.LemonRunRemotes(t, "Purchase", true)
    if ok_n == 0 and fail_n == 0 and skip_n == 0 and deny_n == 0 then
        NotifyError("Lemon Farm", err or "No Purchase buttons found", 5)
    else
        Notify("Lemon Farm", string.format("Buy: %d bought, %d too expensive, %d locked, %d error%s", ok_n, deny_n, skip_n, fail_n, err and (" | "..err) or ""), 6)
    end
end)
LF:AddButton("Test Upgrade Now (1 pass)",function()
    local t = _G._Funcs.GetMyTycoon()
    if not t then NotifyError("Lemon Farm","Tycoon not found",3); return end
    local ok_n, fail_n, skip_n, deny_n, err = _G._Funcs.LemonRunRemotes(t, "Upgrade", true)
    if ok_n == 0 and fail_n == 0 and skip_n == 0 and deny_n == 0 then
        NotifyError("Lemon Farm", err or "No Upgrade buttons found", 5)
    elseif ok_n == 0 and fail_n == 0 then
        NotifyError("Lemon Farm", skip_n.." Upgrade button(s) are paid boosts (BoostProductName) — skipped, not free to automate", 6)
    else
        Notify("Lemon Farm", string.format("Upgrade: %d ok, %d failed, %d skipped(paid)%s", ok_n, fail_n, skip_n, err and (" | "..err) or ""), 6)
    end
end)

LF:AddSection("Notes")
LF:AddButton("Show Status",function()
    local lf = _G._Funcs.LemonFarm
    Notify("Lemon Farm", lf.Status or "Not running", 3)
    if _lfStatusLabel then _lfStatusLabel.Text = "Tycoon: "..(lf.Status or "?") end
    print("[Phaze][Lemon Farm]", lf.Status, "|", lf.LastBuyResult, "|", lf.LastUpgradeResult)
end)
end
end

if game.GameId == 9584852943 then
do local SF=AddCategory("Speed Farm",16)
SF:AddSection("Status")
local _sfStatusLabel = nil
SF:AddCustom(function(parent)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,24)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(200,200,208)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "Not started"
    lbl.Parent = parent
    _sfStatusLabel = lbl
end)

SF:AddSection("Automation")
SF:AddDropdown("Treadmill Tier", {"Treadmill (Free)","TreadmillGold (Robux - must already own)","TreadmillDiamond (Robux - must already own)","TreadmillCandy (Robux - must already own)"}, "Treadmill (Free)", function(v)
    local map = {["Treadmill (Free)"]="Treadmill", ["TreadmillGold (Robux - must already own)"]="TreadmillGold", ["TreadmillDiamond (Robux - must already own)"]="TreadmillDiamond", ["TreadmillCandy (Robux - must already own)"]="TreadmillCandy"}
    _G._Funcs.TreadmillFarm.Target = map[v[1]] or "Treadmill"
end)
SF:AddButton("Warning: paid tiers",function()
    Notify("Speed Farm","If you don't already own the selected paid tier, walking there triggers Roblox's real purchase popup. This script will NEVER click Buy for you — automation auto-stops if that happens.",7)
end)
SF:AddToggle("Enable Auto-Walk on Treadmill",false,function(v) _G._Funcs.SetTreadmillFarm(v) end)

SF:AddSection("Item ESP")
SF:AddToggle("Enable Special Key ESP",false,function(v) _G._Funcs.SetItemESP(v) end)
SF:AddButton("Info: Item ESP",function()
    Notify("Item ESP","Highlights the real SpecialKey_Secret / SpecialKey_Gold items only (exact name match), color-coded, with a name tag. Rescans every 5s to catch newly-spawned ones. If another special item shows up with a different name, tell me its exact name and I'll add it.",7)
end)
SF:AddButton("Teleport To Nearest Special Key",function() _G._Funcs.TeleportToNearestSpecialKey() end)

SF:AddSection("Wins Farm")
SF:AddButton("AddWin is server->client only (confirmed not exploitable)",function()
    Notify("Speed Farm","Testing confirmed firing Remotes.AddWin doesn't change your Wins stat — it's the server notifying your client's UI after a real race, not something the client can trigger. No automation possible here.",7)
end)

SF:AddSection("Notes")
SF:AddButton("Show Status",function()
    local tf = _G._Funcs.TreadmillFarm
    Notify("Speed Farm", tf.Status or "Not running", 3)
    if _sfStatusLabel then _sfStatusLabel.Text = tf.Status or "?" end
end)
SF:AddButton("Note: uses real keypress simulation",function()
    Notify("Speed Farm","This walks your character with real W/S key presses. Don't tab out of the game while it's running, or key simulation may stop working.",6)
end)
end
end

do local ST=AddCategory("Settings",17)

local _writefile = _getFunc("writefile")
local _readfile = _getFunc("readfile")
local _isfile = _getFunc("isfile")
local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "Phaze_Config_"..tostring(game.PlaceId)..".json"
local CONFIG_FILE_GLOBAL = "Phaze_Config_Global.json"

local _toggleCallbacks = {
    ["Anti-Cheat:Lite Bypass (Safe)"] = function(v) if v then SetupLiteBypass() end end,
    ["Anti-Cheat:Full Bypass (Risky)"] = function(v) if v then SetupFullBypass() end end,
    ["Anti-Cheat:Robux/Gamepass Bypass"] = function(v) AntiCheatBypass.SpoofMonetization=v; if v and _G._GamepassBypass then _G._GamepassBypass.Setup() elseif _G._GamepassBypass then _G._GamepassBypass.Cleanup() end end,
    ["Anti-Cheat:Anti-Kick"] = function(v) AntiCheatBypass.AntiKick=v; if v then SetupLiteBypass() end end,
    ["Anti-Cheat:Anti-TP Detection"] = function(v) AntiCheatBypass.AntiTeleportDetection=v; SetupAntiTeleportDetection() end,
    ["Anti-Cheat:Anti-Speed Detection"] = function(v) AntiCheatBypass.AntiSpeedDetection=v; SetupAntiSpeedDetection() end,
    ["Anti-Cheat:Spoof WalkSpeed"] = function(v) AntiCheatBypass.SpoofWalkSpeed=v; SetupAntiSpeedDetection() end,
    ["Anti-Cheat:Spoof JumpPower"] = function(v) AntiCheatBypass.SpoofJumpPower=v; SetupAntiSpeedDetection() end,
    ["Anti-Cheat:Hide From Admins"] = function(v) AntiCheatBypass.HideFromAdmins=v; SetupHideFromAdmins() end,
    ["Anti-Cheat:Anti-Rubberband"] = function(v) AntiCheatBypass.AntiRubberband=v; SetAntiRubberband(v) end,
    ["Anti-Cheat:Anti-AFK Kick"] = function(v) AntiCheatBypass.AntiAFK=v; if v then SetupLiteBypass() end end,
    ["Anti-Cheat:Anti-Detect (Hide Objects)"] = function(v) SetAntiDetect(v) end,
    ["Anti-Cheat:Auto Re-Scan on Respawn"] = function(v) SetAutoRescan(v) end,
    ["ESP:Enable ESP"] = function(v) ESP.Enabled=v; if v then RefreshAllESP() end end,
    ["ESP:Name"] = function(v) ESP.ShowName=v end,
    ["ESP:Health"] = function(v) ESP.ShowHealth=v end,
    ["ESP:Distance"] = function(v) ESP.ShowDistance=v end,
    ["ESP:Team Check"] = function(v) ESP.TeamCheck=v end,
    ["ESP:Wall Check"] = function(v) ESP.WallCheck=v end,
    ["ESP:Chams (Fill Through Walls)"] = function(v) ESP.FillTransparency = v and 0.55 or 1 end,
    ["ESP:Skeleton"] = function(v) ESP.ShowSkeleton=v end,
    ["ESP:Tracers"] = function(v) ESP.ShowTracers=v; UpdateAllTracers() end,
    ["Aimbot:Enable Aimbot"] = function(v) Aimbot.Enabled=v; if _G._SetAimbot then _G._SetAimbot(v) end end,
    ["Aimbot:Auto Shoot"] = function(v) Aimbot.TriggerBot=v end,
    ["Aimbot:Visibility Check"] = function(v) Aimbot.VisibilityCheck=v end,
    ["Aimbot:Team Check"] = function(v) Aimbot.TeamCheck=v end,
    ["Aimbot:Show FOV"] = function(v) Aimbot.ShowFOV=v end,
    ["Aimbot:Silent Aim"] = function(v) MagicBullet.SilentAim=v; if _G._MagicBullet then _G._MagicBullet.SetSilentAim(v) end end,
    ["Aimbot:Bullet TP"] = function(v) MagicBullet.BulletTP=v; if _G._MagicBullet then _G._MagicBullet.SetBulletTP(v) end end,
    ["Aimbot:Curve Bullet"] = function(v) MagicBullet.CurveBullet=v; if _G._MagicBullet then _G._MagicBullet.SetCurveBullet(v) end end,
    ["Hitbox:Enable Hitbox"] = function(v) HitboxExpander.Enabled=v; _G._Funcs.SetHitboxExpander(v) end,
    ["Player:NoClip [N]"] = function(v) NoClip.Enabled=v; _G._Funcs.SetNoClip(v) end,
    ["Player:Fly [F]"] = function(v) Fly.Enabled=v; _G._Funcs.SetFly(v) end,
    ["Player:Custom Speed"] = function(v) _G._Funcs.SetCustomSpeed(v) end,
    ["Teleport:Click Teleport (Hold nothing, just click)"] = function(v) _G._Funcs.SetClickTeleport(v) end,
    ["Player:Infinite Jump"] = function(v) _G._Funcs.SetInfiniteJump(v) end,
    ["Player:Anti-Fall (Void Save)"] = function(v) _G._Funcs.SetAntiFall(v) end,
    ["Troll:Giant/Tiny Size"] = function(v) _G._Funcs.SetCustomScale(v) end,
    ["Troll:Random Ragdoll"] = function(v) _G._Funcs.SetRandomRagdoll(v) end,
    ["Player:Fullbright"] = function(v) _G._Funcs.Fullbright.Enabled=v; _G._Funcs.SetFullbright(v) end,
    ["Player:Freecam"] = function(v) _G._Funcs.SetFreecam(v) end,
    ["Combat:Kill Aura"] = function(v) KillAura.Enabled=v; _G._Funcs.SetKillAura(v) end,
    ["Combat:God Mode"] = function(v) AntiCheatBypass.GodMode=v; _G._Funcs.SetGodMode(v) end,
    ["Combat:One Hit Kill"] = function(v) OneHitKill.Enabled=v; _G._Funcs.SetOneHitKill(v) end,
    ["Combat:No Reload"] = function(v) _G._Funcs.SetNoReload(v) end,
    ["Lemon Farm:Enable Auto-Farm"] = function(v) _G._Funcs.SetLemonFarm(v) end,
    ["Lemon Farm:Auto-Collect Fruit (Click Lemons)"] = function(v) _G._Funcs.LemonFarm.AutoFruit=v end,
    ["Lemon Farm:Auto Plant/Harvest Orchard"] = function(v) _G._Funcs.LemonFarm.AutoOrchard=v end,
    ["Lemon Farm:Auto-Buy (Buildings/Decor)"] = function(v) _G._Funcs.LemonFarm.AutoBuy=v end,
    ["Lemon Farm:Auto-Upgrade (Stand/Trading/etc)"] = function(v) _G._Funcs.LemonFarm.AutoUpgrade=v end,
}

local _dropdownCallbacks = {
    ["ESP:Behind Wall"] = function(v) local c=ESPColors[v]; if c then ESP.HighlightColor=c end end,
    ["ESP:Visible"] = function(v) local c=ESPColors[v]; if c then ESP.VisibleColor=c end end,
    ["ESP:Skeleton Color"] = function(v) local c=ESPColors[v]; if c then ESP.SkeletonColor=c end end,
    ["ESP:Tracer Color"] = function(v) local c=ESPColors[v]; if c then ESP.TracerColor=c; if UpdateAllTracers then UpdateAllTracers() end end end,
    ["ESP:Tracer Origin"] = function(v) ESP.TracerOrigin=v end,
}

local _sliderCallbacks = {
    ["Aimbot:Smoothness"] = function(v) Aimbot.Smoothness=v/100 end,
    ["Aimbot:FOV Radius"] = function(v) Aimbot.FOV=v end,
    ["Aimbot:Prediction"] = function(v) Aimbot.Prediction=(v/100)*0.3 end,
    ["Hitbox:Size"] = function(v) HitboxExpander.Size=v end,
    ["Player:Fly Speed"] = function(v) Fly.Speed=v end,
    ["Player:Speed"] = function(v) _G._Funcs.CustomSpeed.Speed=v end,
    ["Troll:Size"] = function(v) _G._Funcs.UpdateCustomScale(v/100) end,
    ["Player:Freecam Speed"] = function(v) _G._Funcs.FreecamState.Speed=v end,
    ["Player:Corner Build Min Thickness"] = function(v) _G._Funcs.SetFreecamCornerThickness(v) end,
    ["ESP:Max Distance"] = function(v) ESP.MaxDistance=v end,
    ["Combat:Kill Aura Range"] = function(v) KillAura.Range=v end,
    ["Lemon Farm:Loop Delay"] = function(v) _G._Funcs.LemonFarm.Delay=v end,
}

ST:AddSection("Config (per-game: "..tostring(game.PlaceId)..")")
local _useGlobalCfg = false
ST:AddToggle("Use Global Config (all games)", false, function(v) _useGlobalCfg = v end)
local function _cfgFile() return _useGlobalCfg and CONFIG_FILE_GLOBAL or CONFIG_FILE end
ST:AddButton("Save Config",function()
    if not _writefile then NotifyError("Config","Executor doesn't support writefile",3); return end
    local ok, err = pcall(function()
        local data = {toggles={}, sliders={}, dropdowns={}, placeId=game.PlaceId}
        for k, v in pairs(ToggleStates) do data.toggles[k] = v end
        for k, v in pairs(SliderStates) do data.sliders[k] = v end
        for k, v in pairs(DropdownStates) do data.dropdowns[k] = v end
        _writefile(_cfgFile(), HttpService:JSONEncode(data))
    end)
    if ok then Notify("Config","Saved to "..(_useGlobalCfg and "Global" or "Game "..game.PlaceId),2) else NotifyError("Config","Save failed: "..(err or ""),3) end
end)

ST:AddButton("Load Config",function()
    if not _readfile or not _isfile then NotifyError("Config","Executor doesn't support readfile",3); return end
    local ok, err = pcall(function()
        local file = _cfgFile()
        if not _isfile(file) then NotifyError("Config","No saved config found for this game",3); return end
        local raw = _readfile(file)
        local data = HttpService:JSONDecode(raw)

        if data.dropdowns then
            for k, v in pairs(data.dropdowns) do
                DropdownStates[k] = v
                if _dropdownCallbacks[k] then pcall(_dropdownCallbacks[k], v) end
            end
        end
        if data.sliders then
            for k, v in pairs(data.sliders) do
                SliderStates[k] = v
                if _sliderCallbacks[k] then pcall(_sliderCallbacks[k], v) end
            end
        end
        if data.toggles then

            for k, v in pairs(data.toggles) do
                if v and _toggleCallbacks[k] then pcall(_toggleCallbacks[k], false) end
            end

            for k, v in pairs(data.toggles) do
                ToggleStates[k] = v
                if _toggleCallbacks[k] then pcall(_toggleCallbacks[k], v) end
            end
        end

        pcall(function()
            for p, _ in pairs(ESPObjects) do RemoveESP(p) end
            if ESP.Enabled and RefreshAllESP then RefreshAllESP() end
            if UpdateAllTracers then UpdateAllTracers() end
        end)
        local cur = ActiveCat
        ActiveCat = nil
        RenderCategory(cur or "Anti-Cheat")
        Notify("Config","Loaded!",2)
    end)
    if not ok then NotifyError("Config","Load failed: "..(err or ""),3) end
end)

ST:AddButton("Reset Config",function()
    for k in pairs(ToggleStates) do
        if ToggleStates[k] then
            ToggleStates[k] = false
            if _toggleCallbacks[k] then pcall(_toggleCallbacks[k], false) end
        end
    end
    for k in pairs(SliderStates) do SliderStates[k] = nil end
    for k in pairs(DropdownStates) do DropdownStates[k] = nil end
    ESP.Enabled=false; Aimbot.Enabled=false; NoClip.Enabled=false; Fly.Enabled=false
    KillAura.Enabled=false; HitboxExpander.Enabled=false; AntiCheatBypass.GodMode=false
    MagicBullet.SilentAim=false; MagicBullet.BulletTP=false; MagicBullet.CurveBullet=false
    local cur = ActiveCat; ActiveCat = nil; RenderCategory(cur or "Anti-Cheat")
    Notify("Config","Reset to defaults!",2)
end)

ST:AddSection("World / Server Info")
ST:AddButton("Copy World/Server Info",function()
    local info = string.format("PlaceId: %s | UniverseId: %s | JobId: %s", tostring(game.PlaceId), tostring(game.GameId), tostring(game.JobId))
    local scb = _getFunc("setclipboard") or _getFunc("toclipboard") or _getFunc("setrbxclipboard")
    if scb then
        local ok = pcall(scb, info)
        if ok then Notify("Settings", "Copied: "..info, 6)
        else NotifyError("Settings", "Clipboard copy failed", 3) end
    else
        NotifyError("Settings", "Executor doesn't support clipboard copy", 3)
    end
end)

ST:AddSection("Reconnect")
ST:AddButton("Reconnect (Same Server)",function()
    local isPrivate = game.PrivateServerId ~= nil and game.PrivateServerId ~= ""
    local ok, err = pcall(function()
        if isPrivate then
            TeleportService:TeleportToPrivateServer(game.PlaceId, game.PrivateServerId, {LocalPlayer})
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end)
    if not ok then
        NotifyError("Settings", "Same-server reconnect failed ("..tostring(err)..") - server may be full/gone. Try Rejoin (New Server) instead.", 6)
    end
end)
ST:AddButton("Rejoin (New Server)",function()
    local isPrivate = game.PrivateServerId ~= nil and game.PrivateServerId ~= ""
    local ok, err = pcall(function()
        if isPrivate then
            TeleportService:TeleportToPrivateServer(game.PlaceId, game.PrivateServerId, {LocalPlayer})
        else
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
    if not ok then
        NotifyError("Settings", "Rejoin failed: "..tostring(err), 5)
    end
end)

ST:AddSection("Script")
local function UnloadPhaze()
    ESP.Enabled=false; Aimbot.Enabled=false; NoClip.Enabled=false; Fly.Enabled=false; KillAura.Enabled=false; HitboxExpander.Enabled=false; AntiCheatBypass.GodMode=false; ServerTroll.ChatSpam=false; ServerTroll.RemoteSpam=false; ServerTroll.ToolSpam=false
    _G._Funcs.SetCustomSpeed(false); _G._Funcs.SetNoClip(false); _G._Funcs.SetInfiniteJump(false); _G._Funcs.SetAntiFall(false); _G._Funcs.SetClickTeleport(false)
    _G._Funcs.SetCustomScale(false); _G._Funcs.SetRandomRagdoll(false); _G._Funcs.StopFESound()
    _G._Funcs.SetFreecam(false); _G._Funcs.ClearFreecamBlocks(); _G._Funcs.ClearFreecamDrawing(); _G._Funcs.SetLemonFarm(false); _G._Funcs.SetTreadmillFarm(false); if _G._Funcs.SetItemESP then _G._Funcs.SetItemESP(false) end
    if _G._Funcs.SetMovementRecord then _G._Funcs.SetMovementRecord(false) end
    if _G._Funcs.SetMovementPlay then _G._Funcs.SetMovementPlay(false) end
    for p,_ in pairs(ESPObjects) do RemoveESP(p) end
    if _espConn then _espConn:Disconnect() end; if AimbotConnection then AimbotConnection:Disconnect() end; if FOVCircle then pcall(function() FOVCircle:Remove() end) end; if HitboxConnection then HitboxConnection:Disconnect() end; if ChatSpamConnection then ChatSpamConnection:Disconnect() end; if RemoteSpamConnection then RemoteSpamConnection:Disconnect() end; if ToolSpamConnection then ToolSpamConnection:Disconnect() end; if NoclipConnection then NoclipConnection:Disconnect() end; if FlyConnection then FlyConnection:Disconnect() end; if FlyBodyVelocity then FlyBodyVelocity:Destroy() end; if FlyBodyGyro then FlyBodyGyro:Destroy() end; if KillAuraConnection then KillAuraConnection:Disconnect() end; if GodModeConnection then GodModeConnection:Disconnect() end; if GodModeHealthConn then GodModeHealthConn:Disconnect() end; if BringLoopConnection then BringLoopConnection:Disconnect() end; if AntiRubberbandConn then AntiRubberbandConn:Disconnect() end
    SetAntiDetect(false); SetAutoRescan(false); AntiCheatBypass.HideFromAdmins=false; SetupHideFromAdmins()
    local ch=LocalPlayer.Character; if ch then local h=GetHumanoid(ch); if h then h.PlatformStand=false end end
    pcall(function() ScreenGui:Destroy() end)
    print("Phaze Unloaded.")
end
_G._Funcs.Unload = UnloadPhaze

ST:AddButton("UNLOAD SCRIPT",function()
    UnloadPhaze()
end)

end
end)()

RenderCategory("Anti-Cheat")

UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.RightShift then
        ScreenGui.Enabled = not ScreenGui.Enabled
        return
    end
    if inp.UserInputType == Enum.UserInputType.Keyboard then
        for _, kb in ipairs(KeybindActions) do
            local keyName = KeybindStates[kb.bindKey]
            if keyName and keyName ~= "None" and inp.KeyCode.Name == keyName then
                pcall(kb.action)
            end
        end
    end
end)

task.spawn(function() task.wait(3); _G._Funcs.FindAllFunctions() end)

local function SetupESPForPlayer(p)
    if p == LocalPlayer then return end
    CreateESP(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        RemoveESP(p)
        if ESP.Enabled then CreateESP(p) end
    end)
end
for _,p in pairs(Players:GetPlayers()) do SetupESPForPlayer(p) end
Players.PlayerAdded:Connect(function(p) task.wait(1); SetupESPForPlayer(p) end)
Players.PlayerRemoving:Connect(function(p) RemoveESP(p) end)

task.spawn(function()
    while true do
        task.wait(5)
        if ESP.Enabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and not ESPObjects[p] then
                    CreateESP(p)
                end
            end
        end
    end
end)
task.wait(1); Notify("Phaze","Loaded! Press K to toggle.",5)
print("=======================================")
print("    Phaze — FiveM-Style Panel")
print("   Press K to toggle | Scan AC First")
print("=======================================")

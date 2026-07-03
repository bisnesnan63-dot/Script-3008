-- УМНАЯ ДВОЙНАЯ ЗАГРУЗКА БИБЛИОТЕКИ ИНТЕРФЕЙСА
local success, Rayfield = pcall(function()
   return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
   Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua'))()
end

local Window = Rayfield:CreateWindow({
   Name = "SCP-3008 Ultimate Hub V15.4",
   LoadingTitle = "Studio Production",
   LoadingSubtitle = "by Ropi (Smooth Timer Fix)",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "SCP3008ProFixedV8",
      FileName = "BossHubV13"
   }
})

-- СОЗДАНИЕ ВКЛАДОК
local PlayerTab = Window:CreateTab("Player Mod", 4483362458)
local WorldTab = Window:CreateTab("World & ESP", 4483362458)
local BaseTab = Window:CreateTab("Base & Items", 4483362458)
local ServerTab = Window:CreateTab("Server Manager", 4483362458)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-- СОХРАНЕНИЕ ОРИГИНАЛЬНЫХ НАСТРОЕК СВЕТА
local Lighting = game:GetService("Lighting")
local OrigAmbient = Lighting.Ambient
local OrigOutdoorAmbient = Lighting.OutdoorAmbient
local OrigBrightness = Lighting.Brightness
local OrigFogEnd = Lighting.FogEnd
local OrigShadows = Lighting.GlobalShadows

----------------------------------------------------
-- [ВКЛАДКА 1: PLAYER MOD (ФУНКЦИИ ИГРОКА)]
----------------------------------------------------
local selectedPlayerName = ""
local PlayerDropdown = PlayerTab:CreateDropdown({
   Name = "Select Target Player",
   Options = {},
   CurrentOption = "",
   Flag = "PlayerDropdown",
   Callback = function(Option)
      if type(Option) == "table" then
         selectedPlayerName = Option[1]
      else
         selectedPlayerName = Option
      end
   end
})

PlayerTab:CreateButton({
   Name = "Refresh Player List",
   Callback = function()
      local names = {}
      for _, p in pairs(Players:GetPlayers()) do
         if p.Name ~= LocalPlayer.Name then
            table.insert(names, p.Name)
         end
      end
      PlayerDropdown:Refresh(names, true)
   end
})

PlayerTab:CreateButton({
   Name = "Advanced Teleport (Infinite Distance)",
   Callback = function()
      if selectedPlayerName ~= "" then
         local targetPlayer = Players:FindFirstChild(selectedPlayerName)
         local localChar = LocalPlayer.Character
         
         if targetPlayer and localChar then
            local targetChar = targetPlayer.Character or workspace:FindFirstChild(selectedPlayerName)
            
            if targetChar then
               local targetPart = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChildOfClass("Part")
               
               if targetPart then
                  local targetPos = targetPart.Position
                  Rayfield:Notify({Title = "Teleporting...", Content = "Requesting chunks and moving to target!", Duration = 2})
                  
                  pcall(function()
                     LocalPlayer:RequestStreamAroundAsync(targetPos)
                  end)
                  task.wait(0.15)
                  
                  localChar:PivotTo(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
               else
                  Rayfield:Notify({Title = "Error", Content = "Target parts are not fully loaded yet. Try again!", Duration = 3})
               end
            else
               Rayfield:Notify({Title = "Error", Content = "Character model not found in game world!", Duration = 3})
            end
         else
            Rayfield:Notify({Title = "Error", Content = "Target player left or your character is dead!", Duration = 3})
         end
      else
         Rayfield:Notify({Title = "Error", Content = "Please select a target player first!", Duration = 3})
      end
   end
})

local Flying = false
local FlySpeed = 60
local FlyConnection = nil
local bv = nil
local bg = nil

PlayerTab:CreateToggle({
   Name = "Mobile Smooth Fly (Joystick)",
   CurrentValue = false,
   Flag = "FlyToggleMobile",
   Callback = function(Value)
      Flying = Value
      local char = LocalPlayer.Character
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      local hum = char and char:FindFirstChild("Humanoid")
      
      if Flying then
         if hrp and hum then
            local camera = workspace.CurrentCamera
            hum.PlatformStand = true
            
            bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = hrp
            
            bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            bg.CFrame = hrp.CFrame
            bg.Parent = hrp
            
            FlyConnection = RunService.RenderStepped:Connect(function()
               if not Flying or not hrp or not hum then
                  if FlyConnection then FlyConnection:Disconnect() end
                  if bv then bv:Destroy() end
                  if bg then bg:Destroy() end
                  if hum then hum.PlatformStand = false end
                  return
               end
               
               local moveDir = hum.MoveDirection
               local camCFrame = camera.CFrame
               
               if moveDir.Magnitude > 0 then
                  local camLook = camCFrame.LookVector
                  local camRight = camCFrame.RightVector
                  local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
                  local flatRight = Vector3.new(camRight.X, 0, camRight.Z).Unit
                  local forwardDot = moveDir:Dot(flatLook)
                  local rightDot = moveDir:Dot(flatRight)
                  
                  bv.Velocity = (camLook * forwardDot + camRight * rightDot) * FlySpeed
               else
                  bv.Velocity = Vector3.new(0, 0, 0)
               end
               bg.CFrame = camCFrame
            end)
         end
      else
         if FlyConnection then FlyConnection:Disconnect() end
         if bv then bv:Destroy() end
         if bg then bg:Destroy() end
         if hum then hum.PlatformStand = false end
      end
   end
})

PlayerTab:CreateSlider({
   Name = "Flight Speed",
   Range = {10, 300},
   Increment = 5,
   Suffix = "Studs",
   CurrentValue = 60,
   Flag = "FlySpeedMobileConfig",
   Callback = function(Value)
      FlySpeed = Value
   end
})

local InfiniteJump = false
PlayerTab:CreateToggle({
   Name = "Infinite Jump (Air Jump)",
   CurrentValue = false,
   Flag = "InfiniteJumpToggle",
   Callback = function(Value)
      InfiniteJump = Value
   end
})

UserInputService.JumpRequest:Connect(function()
   if InfiniteJump then
      local char = LocalPlayer.Character
      local hum = char and char:FindFirstChildOfClass("Humanoid")
      if hum then
         hum:ChangeState(Enum.HumanoidStateType.Jumping)
      end
   end
end)

local GodMode = false
PlayerTab:CreateToggle({
   Name = "Anti-Staff Aura (Delete Nearby)",
   CurrentValue = false,
   Flag = "AuraToggle",
   Callback = function(Value)
      GodMode = Value
      task.spawn(function()
         while GodMode do
            task.wait(0.1)
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
               for _, npc in pairs(workspace:GetChildren()) do
                  if npc:IsA("Model") and (string.find(string.lower(npc.Name), "staff") or string.find(string.lower(npc.Name), "employee")) then
                     local hrp = npc:FindFirstChild("HumanoidRootPart")
                     if hrp and (hrp.Position - char.HumanoidRootPart.Position).Magnitude < 20 then
                        npc:Destroy() 
                     end
                  end
               end
            end
         end
      end)
   end
})

PlayerTab:CreateSlider({
   Name = "Advanced WalkSpeed",
   Range = {16, 150},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "ProSpeed",
   Callback = function(Value)
      if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
         LocalPlayer.Character.Humanoid.WalkSpeed = Value
      end
   end
})

local NoFall = false
local NoFallConnection = nil
PlayerTab:CreateToggle({
   Name = "No Fall Damage",
   CurrentValue = false,
   Flag = "NoFallDamageToggle",
   Callback = function(Value)
      NoFall = Value
      if NoFall then
         NoFallConnection = RunService.PreRender:Connect(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
               if hum:GetState() == Enum.HumanoidStateType.Freefall then
                  hum:ChangeState(Enum.HumanoidStateType.Running)
               end
            end
         end)
      else
         if NoFallConnection then 
            NoFallConnection:Disconnect() 
            NoFallConnection = nil
         end
      end
   end
})

----------------------------------------------------
-- [ВКЛАДКА 2: WORLD & ESP (ВИЗУАЛЫ И ПОДСВЕТКА)]
----------------------------------------------------
local ESP_Enabled = false
WorldTab:CreateToggle({
   Name = "Fixed ESP (All Items & Staff)",
   CurrentValue = false,
   Flag = "ItemEspToggleFinal",
   Callback = function(Value)
      ESP_Enabled = Value
      if ESP_Enabled then
         task.spawn(function()
            while ESP_Enabled do
               local descendants = workspace:GetDescendants()
               for i, obj in pairs(descendants) do
                  if not ESP_Enabled then break end
                  if i % 200 == 0 then task.wait() end
                  
                  if obj:IsA("Model") and obj.PrimaryPart then
                     local name = string.lower(obj.Name)
                     if string.find(name, "employee") or string.find(name, "staff") then
                        if not obj.PrimaryPart:FindFirstChild("NastyaESP") then
                           local bgui = Instance.new("BillboardGui")
                           bgui.Name = "NastyaESP"
                           bgui.Parent = obj.PrimaryPart
                           bgui.AlwaysOnTop = true
                           bgui.Size = UDim2.new(0, 100, 0, 25)
                           bgui.StudsOffset = Vector3.new(0, 3, 0)
                           local text = Instance.new("TextLabel")
                           text.Parent = bgui
                           text.BackgroundTransparency = 1
                           text.Size = UDim2.new(1, 0, 1, 0)
                           text.Text = "Danger: Staff"
                           text.TextColor3 = Color3.fromRGB(255, 0, 0)
                           text.TextStrokeTransparency = 0
                           text.TextScaled = true
                        end
                     elseif string.find(name, "pizza") or string.find(name, "burger") or 
                            string.find(name, "medkit") or string.find(name, "apple") or 
                            string.find(name, "lemon") or string.find(name, "water") or 
                            string.find(name, "hotdog") or string.find(name, "hot dog") or 
                            string.find(name, "cookie") or string.find(name, "crisps") or 
                            string.find(name, "chips") or string.find(name, "cola") or 
                            string.find(name, "bloxy") or string.find(name, "soda") or
                            string.find(name, "ice cream") or string.find(name, "donut") or
                            string.find(name, "frikadeller") or string.find(name, "meatball") then
                        if not obj.PrimaryPart:FindFirstChild("NastyaESP") then
                           local bgui = Instance.new("BillboardGui")
                           bgui.Name = "NastyaESP"
                           bgui.Parent = obj.PrimaryPart
                           bgui.AlwaysOnTop = true
                           bgui.Size = UDim2.new(0, 80, 0, 20)
                           bgui.StudsOffset = Vector3.new(0, 2, 0)
                           local text = Instance.new("TextLabel")
                           text.Parent = bgui
                           text.BackgroundTransparency = 1
                           text.Size = UDim2.new(1, 0, 1, 0)
                           text.Text = obj.Name
                           text.TextColor3 = Color3.fromRGB(0, 255, 0)
                           text.TextStrokeTransparency = 0
                           text.TextScaled = true
                        end
                     end
                  end
               end
               task.wait(2)
            end
         end)
      else
         for _, desc in pairs(workspace:GetDescendants()) do
            if desc.Name == "NastyaESP" then
               desc:Destroy()
            end
         end
      end
   end
})

local PlayerESP_Enabled = false
local PlayerESP_Connection = nil
local function CleanPlayerESP()
   for _, player in pairs(Players:GetPlayers()) do
      if player.Character then
         local box = player.Character:FindFirstChild("PlayerBoxESP")
         local tracer = player.Character:FindFirstChild("PlayerTracerESP")
         local gui = player.Character:FindFirstChild("PlayerTextESP")
         if box then box:Destroy() end
         if tracer then tracer:Destroy() end
         if gui then gui:Destroy() end
      end
   end
end

WorldTab:CreateToggle({
   Name = "Player ESP (Tracers, Box & Distance)",
   CurrentValue = false,
   Flag = "PlayerESPKeyToggle",
   Callback = function(Value)
      PlayerESP_Enabled = Value
      if PlayerESP_Enabled then
         PlayerESP_Connection = RunService.RenderStepped:Connect(function()
            if not PlayerESP_Enabled then return end
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHrp then return end
            
            for _, player in pairs(Players:GetPlayers()) do
               if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                  local targetHrp = player.Character.HumanoidRootPart
                  
                  local box = player.Character:FindFirstChild("PlayerBoxESP")
                  if not box then
                     box = Instance.new("BoxHandleAdornment")
                     box.Name = "PlayerBoxESP"
                     box.Size = Vector3.new(4, 5.5, 1.5)
                     box.Color3 = Color3.fromRGB(255, 255, 255)
                     box.Transparency = 0.6
                     box.AlwaysOnTop = true
                     box.ZIndex = 6
                     box.Parent = player.Character
                  end
                  box.Adornee = targetHrp

                  local tracer = player.Character:FindFirstChild("PlayerTracerESP")
                  if not tracer then
                     tracer = Instance.new("LineHandleAdornment")
                     tracer.Name = "PlayerTracerESP"
                     tracer.Thickness = 2
                     tracer.Color3 = Color3.fromRGB(255, 255, 0)
                     tracer.AlwaysOnTop = true
                     tracer.ZIndex = 6
                     tracer.Parent = player.Character
                  end
                  
                  tracer.Adornee = myHrp
                  local relativePos = myHrp.CFrame:PointToObjectSpace(targetHrp.Position)
                  tracer.CFrame = CFrame.lookAt(Vector3.new(0, 0, 0), relativePos)
                  tracer.Length = relativePos.Magnitude

                  local gui = player.Character:FindFirstChild("PlayerTextESP")
                  if not gui then
                     gui = Instance.new("BillboardGui")
                     gui.Name = "PlayerTextESP"
                     gui.Size = UDim2.new(0, 150, 0, 30)
                     gui.StudsOffset = Vector3.new(0, 4, 0)
                     gui.AlwaysOnTop = true
                     
                     local label = Instance.new("TextLabel")
                     label.Name = "Label"
                     label.Parent = gui
                     label.BackgroundTransparency = 1
                     label.Size = UDim2.new(1, 0, 1, 0)
                     label.TextColor3 = Color3.fromRGB(0, 225, 255)
                     label.TextStrokeTransparency = 0
                     label.TextScaled = true
                     gui.Parent = player.Character
                  end
                  gui.Adornee = targetHrp
                  
                  local distance = math.floor((myHrp.Position - targetHrp.Position).Magnitude)
                  if gui:FindFirstChild("Label") then
                     gui.Label.Text = player.Name .. " [" .. tostring(distance) .. " Studs]"
                  end
               end
            end
         end)
      else
         if PlayerESP_Connection then
            PlayerESP_Connection:Disconnect()
            PlayerESP_Connection = nil
         end
         CleanPlayerESP()
      end
   end
})

local FullbrightEnabled = false
local FullbrightConnection = nil

WorldTab:CreateToggle({
   Name = "Fullbright (No Fog / No Dark)",
   CurrentValue = false,
   Flag = "FullbrightDynamicToggle",
   Callback = function(Value)
      FullbrightEnabled = Value
      if FullbrightEnabled then
         FullbrightConnection = RunService.Heartbeat:Connect(function()
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 3
            Lighting.FogEnd = 9e9
            Lighting.GlobalShadows = false
         end)
         Rayfield:Notify({Title = "Fullbright", Content = "Fullbright Enabled!", Duration = 3})
      else
         if FullbrightConnection then
            FullbrightConnection:Disconnect()
            FullbrightConnection = nil
         end
         Lighting.Ambient = OrigAmbient
         Lighting.OutdoorAmbient = OrigOutdoorAmbient
         Lighting.Brightness = OrigBrightness
         Lighting.FogEnd = OrigFogEnd
         Lighting.GlobalShadows = OrigShadows
         Rayfield:Notify({Title = "Fullbright", Content = "Fullbright Disabled! Normal environment restored.", Duration = 3})
      end
   end
})

----------------------------------------------------
-- [ВКЛАДКА 3: BASE & ITEMS (ИНТЕРАКТИВНЫЙ ФАРМ)]
----------------------------------------------------
local AutoFoodEnabled = false
local FoodRadius = 1000
local FoodLimit = 16

local AllFoodList = {
   "Burger", "Water", "Hotdog", "Cookie", "Soda", "Apple", "Lemon", 
   "Banana", "Ice Cream", "Crisps", "Chips", "Cola", "Bloxy", "Bob", 
   "Donut", "Frikadeller", "Meatball"
}

local SelectedFoodItems = {
   "Burger", "Water", "Hotdog", "Cookie", "Soda", "Apple", "Lemon", 
   "Banana", "Ice Cream", "Crisps", "Chips", "Cola", "Bloxy", "Bob", 
   "Donut", "Frikadeller", "Meatball"
}

BaseTab:CreateSection("⚡ Interactive Food Auto-Farm")

BaseTab:CreateDropdown({
   Name = "Select Food to Collect",
   Options = AllFoodList,
   CurrentOption = SelectedFoodItems,
   MultipleOptions = true,
   Flag = "FoodMenuSelectorDropdown",
   Callback = function(Options)
      SelectedFoodItems = Options
   end,
})

BaseTab:CreateSlider({
   Name = "Food Scan Radius",
   Range = {100, 2000},
   Increment = 50,
   Suffix = "Studs",
   CurrentValue = 1000,
   Flag = "FoodRadiusSlider",
   Callback = function(Value)
      FoodRadius = Value
   end
})

BaseTab:CreateSlider({
   Name = "Food Inventory Limit",
   Range = {1, 16},
   Increment = 1,
   Suffix = "Items",
   CurrentValue = 16,
   Flag = "FoodLimitSlider",
   Callback = function(Value)
      FoodLimit = Value
   end
})

BaseTab:CreateToggle({
   Name = "Enable Loop Food Auto-Farm",
   CurrentValue = false,
   Flag = "AutoFoodToggleLoop",
   Callback = function(Value)
      AutoFoodEnabled = Value
      if AutoFoodEnabled then
         task.spawn(function()
            while AutoFoodEnabled do
               local char = LocalPlayer.Character
               local hrp = char and char:FindFirstChild("HumanoidRootPart")
               local system = char and char:FindFirstChild("System")
               local actionRemote = system and (system:FindFirstChild("Action") or system:FindFirstChild("Event"))
               
               if hrp and actionRemote then
                  local originalLocation = hrp.CFrame
                  local foodCollected = 0
                  local parts = workspace:GetPartBoundsInRadius(hrp.Position, FoodRadius)
                  local processedModels = {}
                  
                  for _, part in pairs(parts) do
                     if not AutoFoodEnabled or foodCollected >= FoodLimit then break end
                     local model = part:FindFirstAncestorOfClass("Model")
                     if model and not processedModels[model] then
                        processedModels[model] = true
                        local lowerName = string.lower(model.Name)
                        
                        local isWhitelisted = false
                        for k, v in pairs(SelectedFoodItems) do
                           local itemName = (type(k) == "string") and k or tostring(v)
                           if type(v) == "boolean" and v == false then continue end
                           
                           if string.find(lowerName, string.lower(itemName)) then
                              isWhitelisted = true
                              break
                           end
                        end
                        
                        if isWhitelisted then
                           local modelCenterCFrame, _ = model:GetBoundingBox()
                           hrp.CFrame = modelCenterCFrame
                           task.wait(0.02)
                           
                           pcall(function()
                              if actionRemote:IsA("RemoteFunction") then
                                 actionRemote:InvokeServer("Store", {["Model"] = model})
                              else
                                 actionRemote:FireServer("Store", {["Model"] = model})
                              end
                           end)
                           
                           for _, child in pairs(model:GetDescendants()) do
                              if child:IsA("ClickDetector") and fireclickdetector then fireclickdetector(child) end
                              if child:IsA("ProximityPrompt") and fireproximityprompt then fireproximityprompt(child) end
                           end
                           foodCollected = foodCollected + 1
                           task.wait(0.02)
                        end
                     end
                  end
                  if foodCollected > 0 then
                     hrp.CFrame = originalLocation
                  end
               end
               task.wait(3)
            end
         end)
      end
   end
})

local AutoMedkitsEnabled = false
local MedkitRadius = 1000
local MedkitLimit = 16

BaseTab:CreateSection("💊 Auto-Farm Medkits Configuration")

BaseTab:CreateSlider({
   Name = "Medkit Scan Radius",
   Range = {100, 2000},
   Increment = 50,
   Suffix = "Studs",
   CurrentValue = 1000,
   Flag = "MedkitRadiusSlider",
   Callback = function(Value)
      MedkitRadius = Value
   end
})

BaseTab:CreateSlider({
   Name = "Medkit Inventory Limit",
   Range = {1, 16},
   Increment = 1,
   Suffix = "Items",
   CurrentValue = 16,
   Flag = "MedkitLimitSlider",
   Callback = function(Value)
      MedkitLimit = Value
   end
})

BaseTab:CreateToggle({
   Name = "Enable Loop Medkit Auto-Farm",
   CurrentValue = false,
   Flag = "AutoMedkitsToggleLoop",
   Callback = function(Value)
      AutoMedkitsEnabled = Value
      if AutoMedkitsEnabled then
         task.spawn(function()
            while AutoMedkitsEnabled do
               local char = LocalPlayer.Character
               local hrp = char and char:FindFirstChild("HumanoidRootPart")
               local system = char and char:FindFirstChild("System")
               local actionRemote = system and (system:FindFirstChild("Action") or system:FindFirstChild("Event"))
               
               if hrp and actionRemote then
                  local originalLocation = hrp.CFrame
                  local medkitsCollected = 0
                  local parts = workspace:GetPartBoundsInRadius(hrp.Position, MedkitRadius)
                  local processedModels = {}
                  
                  for _, part in pairs(parts) do
                     if not AutoMedkitsEnabled or medkitsCollected >= MedkitLimit then break end
                     local model = part:FindFirstAncestorOfClass("Model")
                     if model and not processedModels[model] then
                        processedModels[model] = true
                        
                        if string.find(string.lower(model.Name), "medkit") then
                           local modelCenterCFrame, _ = model:GetBoundingBox()
                           hrp.CFrame = modelCenterCFrame
                           task.wait(0.02)
                           
                           pcall(function()
                              if actionRemote:IsA("RemoteFunction") then
                                 actionRemote:InvokeServer("Store", {["Model"] = model})
                              else
                                 actionRemote:FireServer("Store", {["Model"] = model})
                              end
                           end)
                           
                           for _, child in pairs(model:GetDescendants()) do
                              if child:IsA("ClickDetector") and fireclickdetector then fireclickdetector(child) end
                              if child:IsA("ProximityPrompt") and fireproximityprompt then fireproximityprompt(child) end
                           end
                           medkitsCollected = medkitsCollected + 1
                           task.wait(0.02)
                        end
                     end
                  end
                  if medkitsCollected > 0 then
                     hrp.CFrame = originalLocation
                  end
               end
               task.wait(3)
            end
         end)
      end
   end
})

BaseTab:CreateSection("Other Base Settings")

BaseTab:CreateButton({
   Name = "Teleport to Cafeteria (Find Beans/Bob)",
   Callback = function()
      local char = LocalPlayer.Character
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      if not hrp then 
         Rayfield:Notify({Title = "Error", Content = "Character not found!", Duration = 3})
         return 
      end
      
      Rayfield:Notify({Title = "Scanning Server", Content = "Searching for real Beans (Food) or Bob...", Duration = 3})
      
      local targetModel = nil
      for _, obj in pairs(workspace:GetDescendants()) do
         if obj:IsA("Model") then
            local name = string.lower(obj.Name)
            if (string.find(name, "bean") and not string.find(name, "bag")) or string.find(name, "bob") then
               targetModel = obj
               break
            end
         end
      end
      
      if targetModel then
         local modelCenterCFrame, _ = targetModel:GetBoundingBox()
         hrp.CFrame = modelCenterCFrame + Vector3.new(0, 4, 0)
         Rayfield:Notify({Title = "Success!", Content = "Teleported to Cafeteria near item: " .. targetModel.Name, Duration = 4})
      else
         Rayfield:Notify({Title = "Not Found", Content = "Beans/Bob are not loaded in your render distance.", Duration = 5})
      end
   end
})

local AutoConsume = false
BaseTab:CreateToggle({
   Name = "Auto-Consume Food & Medkits (Low HP)",
   CurrentValue = false,
   Flag = "AutoConsumeSurvivalToggle",
   Callback = function(Value)
      AutoConsume = Value
   end
})

task.spawn(function()
   while true do
      task.wait(1.5)
      if AutoConsume then
         local char = LocalPlayer.Character
         local hum = char and char:FindFirstChildOfClass("Humanoid")
         local system = char and char:FindFirstChild("System")
         local actionRemote = system and system:FindFirstChild("Action")
         
         if hum and hum.Health < 40 and actionRemote then
            pcall(function() actionRemote:FireServer("Consume", "Medkit") end)
            pcall(function() actionRemote:FireServer("Consume", "Burger") end)
            pcall(function() actionRemote:FireServer("Eat", "Medkit") end)
            pcall(function() actionRemote:FireServer("Use", "Medkit") end)
         end
      end
   end
end)

local Waypoints = {}
local TargetWaypointName = ""
local SelectedWaypoint = ""
local WaypointDropdown = nil

BaseTab:CreateSection("Advanced Waypoint Manager")

BaseTab:CreateInput({
   Name = "New Waypoint Name",
   PlaceholderText = "Type point name...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      TargetWaypointName = Text
   end,
})

BaseTab:CreateButton({
   Name = "Save Current Position",
   Callback = function()
      local char = LocalPlayer.Character
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      if not hrp then return end
      
      if TargetWaypointName and TargetWaypointName ~= "" then
         Waypoints[TargetWaypointName] = hrp.Position
         
         local list = {}
         for name, _ in pairs(Waypoints) do
            table.insert(list, name)
         end
         if WaypointDropdown then WaypointDropdown:Refresh(list) end
         
         Rayfield:Notify({Title = "Location Saved", Content = "Added '" .. TargetWaypointName .. "' to your list!", Duration = 3})
      else
         Rayfield:Notify({Title = "Error", Content = "Please type a name in the input box first!", Duration = 3})
      end
   end
})

WaypointDropdown = BaseTab:CreateDropdown({
   Name = "Select Saved Waypoint",
   Options = {},
   CurrentOption = "",
   MultipleOptions = false,
   Flag = "NastyaWaypointDropdown",
   Callback = function(Option)
      if type(Option) == "table" then
         SelectedWaypoint = Option[1]
      else
         SelectedWaypoint = Option
      end
   end,
})

BaseTab:CreateButton({
   Name = "Teleport To Selected Waypoint",
   Callback = function()
      local char = LocalPlayer.Character
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      if not hrp then return end
      
      if SelectedWaypoint and Waypoints[SelectedWaypoint] then
         hrp.CFrame = CFrame.new(Waypoints[SelectedWaypoint])
         Rayfield:Notify({Title = "Teleported", Content = "Arrived safely at: " .. SelectedWaypoint, Duration = 3})
      else
         Rayfield:Notify({Title = "Teleport Failed", Content = "Please select a valid point from the drop-down list!", Duration = 3})
      end
   end
})

BaseTab:CreateButton({
   Name = "Delete Selected Waypoint",
   Callback = function()
      if SelectedWaypoint and Waypoints[SelectedWaypoint] then
         Waypoints[SelectedWaypoint] = nil
         SelectedWaypoint = ""
         
         local list = {}
         for name, _ in pairs(Waypoints) do
            table.insert(list, name)
         end
         if WaypointDropdown then WaypointDropdown:Refresh(list) end
         
         Rayfield:Notify({Title = "Deleted", Content = "Waypoint removed from your memory.", Duration = 3})
      end
   end
})

----------------------------------------------------
-- [ВКЛАДКА 4: SERVER MANAGER & TIME TRACKER]
----------------------------------------------------
ServerTab:CreateSection("Time & Status")

local TimeOverlayEnabled = false
local ScreenGui = nil
local TimerLabel = nil
local cachedTimeLabel = nil
local timeRenderConnection = nil

local function getRealGameTime()
   if cachedTimeLabel and cachedTimeLabel.Parent then
      return cachedTimeLabel.Text
   end
   for _, v in pairs(LocalPlayer:WaitForChild("PlayerGui"):GetDescendants()) do
      if v:IsA("TextLabel") and string.match(v.Text, "^%d%d:%d%d$") then
         cachedTimeLabel = v
         return v.Text
      end
   end
   return nil
end

ServerTab:CreateToggle({
   Name = "Show Day/Night Overlay",
   CurrentValue = false,
   Flag = "TimeOverlayToggle",
   Callback = function(Value)
      TimeOverlayEnabled = Value
      
      if TimeOverlayEnabled then
         if not ScreenGui then
            ScreenGui = Instance.new("ScreenGui")
            ScreenGui.Name = "TimeOverlayGui"
            ScreenGui.ResetOnSpawn = false
            ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            
            local Frame = Instance.new("Frame")
            Frame.Name = "TimeFrame"
            Frame.Size = UDim2.new(0, 200, 0, 60)
            Frame.Position = UDim2.new(0.5, -100, 0.05, 0)
            Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Frame.BorderSizePixel = 0
            Frame.Active = true
            Frame.Draggable = true
            Frame.Parent = ScreenGui
            
            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(0, 8)
            Corner.Parent = Frame
            
            TimerLabel = Instance.new("TextLabel")
            TimerLabel.Name = "TimerLabel"
            TimerLabel.Size = UDim2.new(1, 0, 1, 0)
            TimerLabel.BackgroundTransparency = 1
            TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            TimerLabel.TextScaled = true
            TimerLabel.Font = Enum.Font.GothamBold
            TimerLabel.Text = "Searching UI..."
            TimerLabel.Parent = Frame
         end
         
         ScreenGui.Enabled = true
         
         local lastTimeStr = ""
         local currentPhase = ""
         local exactRealSecondsLeft = 0
         local lastSyncClock = os.clock()

         if timeRenderConnection then timeRenderConnection:Disconnect() end
         timeRenderConnection = RunService.RenderStepped:Connect(function()
            if not TimeOverlayEnabled or not ScreenGui.Enabled then return end
            
            local timeStr = getRealGameTime()
            if timeStr then
               -- Если время в игре изменилось, пересчитываем базу
               if timeStr ~= lastTimeStr then
                  local hour, minute = string.match(timeStr, "(%d%d):(%d%d)")
                  if hour and minute then
                     hour = tonumber(hour)
                     minute = tonumber(minute)
                     local totalMinutes = hour * 60 + minute
                     
                     if totalMinutes >= 360 and totalMinutes < 1080 then
                        -- ДЕНЬ: Длится ровно 6 минут (360 секунд на 720 игровых минут)
                        currentPhase = "To NIGHT: "
                        local inGameMinutesLeft = 1080 - totalMinutes
                        exactRealSecondsLeft = inGameMinutesLeft * (360 / 720) -- Коэффициент 0.5
                        if TimerLabel then TimerLabel.TextColor3 = Color3.fromRGB(0, 200, 255) end
                     else
                        -- НОЧЬ: Длится ровно 5 минут (300 секунд на 720 игровых минут)
                        currentPhase = "To DAY: "
                        local inGameMinutesLeft = 0
                        if totalMinutes >= 1080 then
                           inGameMinutesLeft = (1440 - totalMinutes) + 360
                        else
                           inGameMinutesLeft = 360 - totalMinutes
                        end
                        exactRealSecondsLeft = inGameMinutesLeft * (300 / 720) -- Коэффициент ~0.416
                        if TimerLabel then TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 0) end
                     end
                     
                     lastTimeStr = timeStr
                     lastSyncClock = os.clock() -- Сохраняем время синхронизации
                  end
               end
               
               -- ПЛАВНЫЙ ПОКАДРОВЫЙ ОТСЧЕТ НАЗАД (ИНТЕРПОЛЯЦИЯ)
               local elapsed = os.clock() - lastSyncClock
               local predictedTime = math.max(0, exactRealSecondsLeft - elapsed)
               
               local mins = math.floor(predictedTime / 60)
               local secs = math.floor(predictedTime % 60)
               if TimerLabel then
                  TimerLabel.Text = string.format("%s%02d:%02d", currentPhase, mins, secs)
               end
            else
               if TimerLabel then TimerLabel.Text = "Searching HUD..." end
            end
         end)
      else
         if ScreenGui then ScreenGui.Enabled = false end
         if timeRenderConnection then
            timeRenderConnection:Disconnect()
            timeRenderConnection = nil
         end
      end
   end
})

local AgeLabel = ServerTab:CreateLabel("Current Server Age: Calculating...")

task.spawn(function()
   while task.wait(1) do
      local totalSeconds = math.floor(workspace.DistributedGameTime)
      local hours = math.floor(totalSeconds / 3600)
      local minutes = math.floor((totalSeconds % 3600) / 60)
      local seconds = totalSeconds % 60
      AgeLabel:Set(string.format("Current Server Age: %02d:%02d:%02d", hours, minutes, seconds))
   end
end)

ServerTab:CreateLabel("Tip: Fresh servers usually have more untampered loot!")

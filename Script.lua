-- УМНАЯ ДВОЙНАЯ ЗАГРУЗКА БИБЛИОТЕКИ ИНТЕРФЕЙСА
local success, Rayfield = pcall(function()
   return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
   Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua'))()
end

local Window = Rayfield:CreateWindow({
   Name = "SCP-3008 Ultimate Hub V12.0 (Turbo Farm)",
   LoadingTitle = "Studio Production",
   LoadingSubtitle = "by Nastya (Excluding Pizza)",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "SCP3008ProFixedV7",
      FileName = "BossHubV12"
   }
})

-- СОЗДАНИЕ ВСЕХ ВКЛАДОК
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
   Name = "Teleport to Selected",
   Callback = function()
      if selectedPlayerName ~= "" and Players:FindFirstChild(selectedPlayerName) then
         local target = Players[selectedPlayerName].Character
         if target and target:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
         else
            Rayfield:Notify({Title = "Error", Content = "Target has no character!", Duration = 3})
         end
      else
         Rayfield:Notify({Title = "Error", Content = "Player not selected!", Duration = 3})
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
               for _, obj in pairs(workspace:GetDescendants()) do
                  if not ESP_Enabled then break end
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
                  tracer.Adornee = targetHrp
                  tracer.Length = (targetHrp.Position - myHrp.Position).Magnitude
                  tracer.CFrame = CFrame.lookAt(Vector3.new(0, 0, 0), targetHrp.Position - myHrp.Position)

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

WorldTab:CreateButton({
   Name = "Remove Fog & Dark",
   Callback = function()
      local lighting = game:GetService("Lighting")
      lighting.FogEnd = 9e9
      lighting.GlobalShadows = false
      lighting.Ambient = Color3.fromRGB(255, 255, 255)
      lighting.Brightness = 2
   end
})

----------------------------------------------------
-- [ВКЛАДКА 3: BASE & ITEMS (АВТОФАРМ, ТОЧКИ И КАФЕТЕРИЙ)]
----------------------------------------------------
-- Пицца ("pizza") полностью исключена из таблицы поиска
local FoodKeywords = {
   "burger", "water", "hotdog", "cookie", "soda", 
   "apple", "lemon", "banana", "ice cream", "crisps", 
   "chips", "cola", "bloxy", "bob", "donut", "frikadeller", "meatball"
}

BaseTab:CreateButton({
   Name = "Turbo Collect 16 Food (No Pizza | Radius 1000)",
   Callback = function()
      local char = LocalPlayer.Character
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      local system = char and char:FindFirstChild("System")
      local actionRemote = system and system:FindFirstChild("Action")
      
      if not hrp then 
         Rayfield:Notify({Title = "Error", Content = "Character not found!", Duration = 3})
         return 
      end
      
      local originalLocation = hrp.CFrame
      local foodCollected = 0
      
      Rayfield:Notify({
         Title = "Turbo Farm Started",
         Content = "Scanning 1000 studs radius for food (Excluding Pizza)...",
         Duration = 2
      })
      
      -- Расширенный радиус до 1000 стадов
      local parts = workspace:GetPartBoundsInRadius(hrp.Position, 1000)
      local processedModels = {}
      
      for _, part in pairs(parts) do
         if foodCollected >= 16 then break end
         local model = part:FindFirstAncestorOfClass("Model")
         if model and not processedModels[model] then
            processedModels[model] = true
            local lowerName = string.lower(model.Name)
            local isFood = false
            
            for i = 1, #FoodKeywords do
               if string.find(lowerName, FoodKeywords[i]) then
                  isFood = true
                  break
               end
            end
            
            -- Дополнительная жесткая фильтрация против пиццы
            if isFood and not string.find(lowerName, "pizza") then
               local modelCenterCFrame, _ = model:GetBoundingBox()
               hrp.CFrame = modelCenterCFrame
               task.wait(0.01) -- Турбо-задержка
               
               if actionRemote then
                  pcall(function()
                     if actionRemote:IsA("RemoteFunction") then
                        actionRemote:InvokeServer("Store", {["Model"] = model})
                     else
                        actionRemote:FireServer("Store", {["Model"] = model})
                     end
                     pcall(function() actionRemote:FireServer("Store", model) end)
                  end)
               end
               
               for _, child in pairs(model:GetDescendants()) do
                  if child:IsA("ClickDetector") and fireclickdetector then fireclickdetector(child) end
                  if child:IsA("ProximityPrompt") and fireproximityprompt then fireproximityprompt(child) end
               end
               foodCollected = foodCollected + 1
               task.wait(0.01) -- Турбо-задержка
            end
         end
      end
      hrp.CFrame = originalLocation
      Rayfield:Notify({
         Title = "Farm Completed",
         Content = "Successfully collected " .. tostring(foodCollected) .. " non-pizza items!",
         Duration = 4
      })
   end
})

BaseTab:CreateButton({
   Name = "Turbo Collect 16 Medkits (Radius 1000)",
   Callback = function()
      local char = LocalPlayer.Character
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      local system = char and char:FindFirstChild("System")
      local actionRemote = system and system:FindFirstChild("Action")
      
      if not hrp then 
         Rayfield:Notify({Title = "Error", Content = "Character not found!", Duration = 3})
         return 
      end
      
      local originalLocation = hrp.CFrame
      local medkitsCollected = 0
      
      Rayfield:Notify({
         Title = "Medkit Farm Started",
         Content = "Scanning 1000 studs radius for Medkits...",
         Duration = 2
      })
      
      -- Расширенный радиус до 1000 стадов
      local parts = workspace:GetPartBoundsInRadius(hrp.Position, 1000)
      local processedModels = {}
      
      for _, part in pairs(parts) do
         if medkitsCollected >= 16 then break end
         local model = part:FindFirstAncestorOfClass("Model")
         if model and not processedModels[model] then
            processedModels[model] = true
            
            if string.find(string.lower(model.Name), "medkit") then
               local modelCenterCFrame, _ = model:GetBoundingBox()
               hrp.CFrame = modelCenterCFrame
               task.wait(0.01) -- Турбо-задержка
               
               if actionRemote then
                  pcall(function()
                     if actionRemote:IsA("RemoteFunction") then
                        actionRemote:InvokeServer("Store", {["Model"] = model})
                     else
                        actionRemote:FireServer("Store", {["Model"] = model})
                     end
                     pcall(function() actionRemote:FireServer("Store", model) end)
                  end)
               end
               
               for _, child in pairs(model:GetDescendants()) do
                  if child:IsA("ClickDetector") and fireclickdetector then fireclickdetector(child) end
                  if child:IsA("ProximityPrompt") and fireproximityprompt then fireproximityprompt(child) end
               end
               medkitsCollected = medkitsCollected + 1
               task.wait(0.01) -- Турбо-задержка
            end
         end
      end
      hrp.CFrame = originalLocation
      Rayfield:Notify({
         Title = "Medkit Farm Completed",
         Content = "Successfully collected " .. tostring(medkitsCollected) .. " Medkits!",
         Duration = 4
      })
   end
})

BaseTab:CreateButton({
   Name = "Teleport to Cafeteria (Find Beans/Bob)",
   Callback = function()
      local char = LocalPlayer.Character
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      if not hrp then 
         Rayfield:Notify({Title = "Error", Content = "Character not found!", Duration = 3})
         return 
      end
      
      Rayfield:Notify({
         Title = "Scanning Server",
         Content = "Searching for real Beans (Food) or Bob...",
         Duration = 3
      })
      
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
         Rayfield:Notify({
            Title = "Success!",
            Content = "Teleported directly to Cafeteria near item: " .. targetModel.Name,
            Duration = 4
         })
      else
         Rayfield:Notify({
            Title = "Not Found",
            Content = "Beans/Bob are not loaded in your render distance. Walk around or change server!",
            Duration = 5
         })
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
         
         Rayfield:Notify({
            Title = "Location Saved",
            Content = "Added '" .. TargetWaypointName .. "' to your list!",
            Duration = 3
         })
      else
         Rayfield:Notify({
            Title = "Error",
            Content = "Please type a name in the input box first!",
            Duration = 3
         })
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
         Rayfield:Notify({
            Title = "Teleported",
            Content = "Arrived safely at: " .. SelectedWaypoint,
            Duration = 3
         })
      else
         Rayfield:Notify({
            Title = "Teleport Failed",
            Content = "Please select a valid point from the drop-down list!",
            Duration = 3
         })
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
         
         Rayfield:Notify({
            Title = "Deleted",
            Content = "Waypoint removed from your memory.",
            Duration = 3
         })
      end
   end
})

----------------------------------------------------
-- [ВКЛАДКА 4: SERVER MANAGER]
----------------------------------------------------
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

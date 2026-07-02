local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "SCP-3008 Ultimate Hub V9.2 (Center TP)",
   LoadingTitle = "Studio Production",
   LoadingSubtitle = "by Nastya",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "SCP3008ProFixedV7",
      FileName = "BossHubV11"
   }
})

local PlayerTab = Window:CreateTab("Player Mod", 4483362458)
local WorldTab = Window:CreateTab("World & ESP", 4483362458)
local BaseTab = Window:CreateTab("Base & Items", 4483362458)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- НАСТРОЙКИ МОБИЛЬНОГО ПЛАВНОГО ПОЛЕТА
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

-- ЗАЩИТА ОТ УРОНА ПРИ ПАДЕНИИ
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

-- УЛУЧШЕННЫЙ АВТОФАРМ ЕДЫ С ТЕЛЕПОРТОМ В ГЕОМЕТРИЧЕСКИЙ ЦЕНТР МОДЕЛИ
local FoodKeywords = {
   "pizza", "burger", "water", "hotdog", "cookie", "soda", 
   "apple", "lemon", "banana", "ice cream", "crisps", 
   "chips", "cola", "bloxy", "bob", "donut", "frikadeller", "meatball"
}

BaseTab:CreateButton({
   Name = "Auto Collect 16 Food (Fixed Auto Farm)",
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
         Title = "Auto Farm Started",
         Content = "Scanning 3D space for food...",
         Duration = 2
      })
      
      local parts = workspace:GetPartBoundsInRadius(hrp.Position, 250)
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
            
            if isFood then
               -- Использование BoundingBox для получения точного центра модели
               local modelCenterCFrame, _ = model:GetBoundingBox()
               hrp.CFrame = modelCenterCFrame
               task.wait(0.04)
               
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
               task.wait(0.04)
            end
         end
      end
      
      hrp.CFrame = originalLocation
      
      Rayfield:Notify({
         Title = "Farm Completed",
         Content = "Successfully collected " .. tostring(foodCollected) .. " food items!",
         Duration = 4
      })
   end
})

-- УЛУЧШЕННЫЙ АВТОФАРМ АПТЕЧЕК С ТЕЛЕПОРТОМ В ГЕОМЕТРИЧЕСКИЙ ЦЕНТР МОДЕЛИ
BaseTab:CreateButton({
   Name = "Auto Collect 16 Medkits (Auto Farm)",
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
         Content = "Scanning 3D space for Medkits...",
         Duration = 2
      })
      
      local parts = workspace:GetPartBoundsInRadius(hrp.Position, 250)
      local processedModels = {}
      
      for _, part in pairs(parts) do
         if medkitsCollected >= 16 then break end
         
         local model = part:FindFirstAncestorOfClass("Model")
         if model and not processedModels[model] then
            processedModels[model] = true
            
            if string.find(string.lower(model.Name), "medkit") then
               -- Использование BoundingBox для получения точного центра модели
               local modelCenterCFrame, _ = model:GetBoundingBox()
               hrp.CFrame = modelCenterCFrame
               task.wait(0.04)
               
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
               task.wait(0.04)
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

local BaseLocation = nil
BaseTab:CreateButton({
   Name = "Set Base Waypoint Here",
   Callback = function()
      local char = LocalPlayer.Character
      if char and char:FindFirstChild("HumanoidRootPart") then
         BaseLocation = char.HumanoidRootPart.Position
         Rayfield:Notify({
            Title = "Base Saved",
            Content = "Your base location is marked in memory!",
            Duration = 3
         })
      end
   end
})

BaseTab:CreateButton({
   Name = "Teleport To Base",
   Callback = function()
      local char = LocalPlayer.Character
      if char and char:FindFirst

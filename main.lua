--[[
    ███████╗███████╗███╗   ██╗ ██████╗ ██╗   ██╗ █████╗
    ╚══███╔╝██╔════╝████╗  ██║██╔═══██╗██║   ██║██╔══██╗
      ███╔╝ █████╗  ██╔██╗ ██║██║   ██║██║   ██║███████║
     ███╔╝  ██╔══╝  ██║╚██╗██║██║   ██║╚██╗ ██╔╝██╔══██║
    ███████╗███████╗██║ ╚████║╚██████╔╝ ╚████╔╝ ██║  ██║
    ╚══════╝╚══════╝╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝

    Zenova UI Library v2.0
    A sleek, dark-themed Roblox UI Library
    Features: Multi-tab panels, sliders, toggles, dropdowns,
              sub-pages, multi-select, smooth animations.

    Usage:
        local ZenovaLib = loadstring(game:HttpGet("..."))()
        local Window = ZenovaLib:CreateWindow({ Title = "MyScript" })

        local CombatTab = Window:CreateTab({ Name = "Combat", Icon = "⚔" })

        CombatTab:AddToggle({
            Name = "Aim Bot",
            Default = false,
            Callback = function(v) print("AimBot:", v) end,
        })

        CombatTab:AddExpandable({
            Name = "Speed Settings",
            Items = {
                { Type = "Slider",  Name = "Speed",     Min = 0, Max = 5,   Default = 1,   Decimals = 1, Callback = function(v) end },
                { Type = "Toggle",  Name = "Auto Jump",  Default = false, Callback = function(v) end },
                { Type = "Toggle",  Name = "Keep Sprint", Default = true,  Callback = function(v) end },
            }
        })

        CombatTab:AddDropdown({
            Name = "Weapon",
            Options = { "Sword", "Bow", "Axe" },
            Default = "Sword",
            Callback = function(v) print("Weapon:", v) end,
        })
]]

-- ============================================================
--  SERVICES
-- ============================================================
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")

-- ============================================================
--  THEME
-- ============================================================
local Theme = {
    PanelBg        = Color3.fromRGB(30,  30,  30),
    HeaderBg       = Color3.fromRGB(22,  22,  22),
    RowBg          = Color3.fromRGB(30,  30,  30),
    RowHover       = Color3.fromRGB(42,  42,  42),
    Separator      = Color3.fromRGB(50,  50,  50),
    Text           = Color3.fromRGB(210, 210, 210),
    TextDim        = Color3.fromRGB(120, 120, 120),
    TextActive     = Color3.fromRGB(160, 100, 230),
    Accent         = Color3.fromRGB(140, 90,  220),
    AccentDark     = Color3.fromRGB(90,  55,  155),
    ToggleOff      = Color3.fromRGB(60,  60,  60),
    SliderTrack    = Color3.fromRGB(55,  55,  55),
    White          = Color3.fromRGB(255, 255, 255),
    CheckColor     = Color3.fromRGB(140, 90,  220),
    ScrollBar      = Color3.fromRGB(100, 60,  180),
}

-- Panel dimensions
local PANEL_W      = 168
local PANEL_H      = 340
local HEADER_H     = 40
local ROW_H        = 32
local GAP          = 1        -- gap between panels
local CORNER       = 8
local ANIM_FAST    = 0.15
local ANIM_MED     = 0.22
local ANIM_SLOW    = 0.35

-- ============================================================
--  UTILITY
-- ============================================================
local function Tween(obj, props, t, style, dir)
    local ti = TweenInfo.new(
        t   or ANIM_FAST,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out
    )
    local tw = TweenService:Create(obj, ti, props)
    tw:Play()
    return tw
end

local function Round(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or CORNER)
    c.Parent = obj
    return c
end

local function NewFrame(props)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    for k, v in pairs(props or {}) do
        f[k] = v
    end
    return f
end

local function NewLabel(props)
    local l = Instance.new("TextLabel")
    l.BorderSizePixel   = 0
    l.BackgroundTransparency = 1
    l.Font              = Enum.Font.Gotham
    l.TextSize          = 13
    l.TextColor3        = Theme.Text
    l.TextXAlignment    = Enum.TextXAlignment.Left
    l.TextYAlignment    = Enum.TextYAlignment.Center
    for k, v in pairs(props or {}) do
        l[k] = v
    end
    return l
end

local function NewButton(props)
    local b = Instance.new("TextButton")
    b.BorderSizePixel        = 0
    b.AutoButtonColor        = false
    b.Text                   = ""
    b.BackgroundColor3       = Theme.RowBg
    for k, v in pairs(props or {}) do
        b[k] = v
    end
    return b
end

-- Separator line
local function Separator(parent, yPos, padX)
    padX = padX or 12
    local s = NewFrame({
        Size            = UDim2.new(1, -padX*2, 0, 1),
        Position        = UDim2.new(0, padX, 0, yPos),
        BackgroundColor3 = Theme.Separator,
        Parent          = parent,
    })
    return s
end

-- Make a frame draggable via a handle
local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil

    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end

    local function onInputChanged(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end

    handle.InputBegan:Connect(onInputBegan)
    UserInputService.InputChanged:Connect(onInputChanged)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============================================================
--  PILL TOGGLE WIDGET (reusable)
-- ============================================================
local function CreatePillToggle(parent, xPos, yCenter, initialVal, onChange)
    local PILL_W, PILL_H, DOT_S = 36, 18, 12

    local pillBg = NewFrame({
        Size             = UDim2.new(0, PILL_W, 0, PILL_H),
        Position         = UDim2.new(0, xPos, 0, yCenter - PILL_H/2),
        BackgroundColor3 = initialVal and Theme.Accent or Theme.ToggleOff,
        Parent           = parent,
    })
    Round(pillBg, 100)

    local dot = NewFrame({
        Size             = UDim2.new(0, DOT_S, 0, DOT_S),
        Position         = initialVal
            and UDim2.new(0, PILL_W - DOT_S - 3, 0, (PILL_H - DOT_S)/2)
            or  UDim2.new(0, 3, 0, (PILL_H - DOT_S)/2),
        BackgroundColor3 = Theme.White,
        Parent           = pillBg,
    })
    Round(dot, 100)

    local state = initialVal

    local function set(val)
        state = val
        Tween(pillBg, { BackgroundColor3 = val and Theme.Accent or Theme.ToggleOff }, ANIM_FAST)
        Tween(dot, {
            Position = val
                and UDim2.new(0, PILL_W - DOT_S - 3, 0, (PILL_H - DOT_S)/2)
                or  UDim2.new(0, 3, 0, (PILL_H - DOT_S)/2)
        }, ANIM_FAST)
        if onChange then onChange(val) end
    end

    return pillBg, dot, set, function() return state end
end

-- ============================================================
--  SLIDER WIDGET (reusable)
-- ============================================================
local function CreateSlider(parent, cfg, layoutOrder)
    --[[
        cfg = {
            Name     = string,
            Min      = number,
            Max      = number,
            Default  = number,
            Decimals = number (0..4),
            Callback = function(val),
        }
    ]]
    local TRACK_H   = 4
    local THUMB_S   = 12
    local PADX      = 15
    local CELL_H    = 54
    local decimals  = cfg.Decimals or 1
    local value     = math.clamp(cfg.Default or cfg.Min, cfg.Min, cfg.Max)

    local cell = NewFrame({
        Size             = UDim2.new(1, 0, 0, CELL_H),
        BackgroundTransparency = 1,
        LayoutOrder      = layoutOrder,
        Parent           = parent,
    })

    -- name label
    local nameLbl = NewLabel({
        Text             = cfg.Name,
        TextSize         = 12,
        TextColor3       = Theme.TextDim,
        Size             = UDim2.new(1, -80, 0, 18),
        Position         = UDim2.new(0, PADX, 0, 8),
        Parent           = cell,
    })

    -- value label
    local valLbl = NewLabel({
        TextXAlignment   = Enum.TextXAlignment.Right,
        TextSize         = 12,
        TextColor3       = Theme.TextDim,
        Size             = UDim2.new(0, 60, 0, 18),
        Position         = UDim2.new(1, -PADX-60, 0, 8),
        Parent           = cell,
    })

    -- track bg
    local trackBg = NewFrame({
        Size             = UDim2.new(1, -PADX*2, 0, TRACK_H),
        Position         = UDim2.new(0, PADX, 0, 34),
        BackgroundColor3 = Theme.SliderTrack,
        Parent           = cell,
    })
    Round(trackBg, 100)

    -- track fill
    local trackFill = NewFrame({
        Size             = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        Parent           = trackBg,
    })
    Round(trackFill, 100)

    -- thumb
    local thumb = NewFrame({
        Size             = UDim2.new(0, THUMB_S, 0, THUMB_S),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Theme.White,
        Parent           = trackBg,
    })
    Round(thumb, 100)

    -- invisible hit area over track (bigger)
    local hitArea = NewButton({
        Size             = UDim2.new(1, 0, 0, THUMB_S + 10),
        Position         = UDim2.new(0, 0, 0.5, -(THUMB_S+10)/2),
        BackgroundTransparency = 1,
        ZIndex           = thumb.ZIndex + 1,
        Parent           = trackBg,
    })

    local function setValue(val, skipCallback)
        val = math.clamp(val, cfg.Min, cfg.Max)
        value = val
        local pct = (val - cfg.Min) / (cfg.Max - cfg.Min)
        valLbl.Text = string.format("%." .. decimals .. "f", val)
        Tween(trackFill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.08)
        thumb.Position = UDim2.new(pct, 0, 0.5, 0)
        if not skipCallback and cfg.Callback then cfg.Callback(val) end
    end
    setValue(value, true)

    local dragging = false

    local function computeFromX(absX)
        local abs = trackBg.AbsolutePosition
        local sz  = trackBg.AbsoluteSize
        local pct = math.clamp((absX - abs.X) / sz.X, 0, 1)
        return cfg.Min + pct * (cfg.Max - cfg.Min)
    end

    hitArea.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setValue(computeFromX(inp.Position.X))
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            setValue(computeFromX(inp.Position.X))
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- bottom separator
    Separator(cell, CELL_H - 1, PADX)

    return cell, setValue, function() return value end
end

-- ============================================================
--  MULTI-SELECT WIDGET (used in sub-page, like "Vật phẩm")
-- ============================================================
local function CreateMultiSelect(parent, cfg, startOrder)
    --[[
        cfg = {
            Name     = string,        -- section label
            Items    = { string, ... },
            Selected = { string, ... }, -- defaults
            Callback = function(selectedSet),
        }
    ]]
    local selectedSet = {}
    for _, v in ipairs(cfg.Selected or {}) do selectedSet[v] = true end

    -- Label row
    local headCell = NewFrame({
        Size             = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        LayoutOrder      = startOrder,
        Parent           = parent,
    })
    NewLabel({
        Text             = cfg.Name,
        TextSize         = 11,
        TextColor3       = Theme.TextDim,
        Font             = Enum.Font.GothamBold,
        Size             = UDim2.new(1, -30, 1, 0),
        Position         = UDim2.new(0, 15, 0, 0),
        Parent           = headCell,
    })

    -- Count label e.g. "2 of 4"
    local countLbl = NewLabel({
        TextXAlignment   = Enum.TextXAlignment.Right,
        TextSize         = 11,
        TextColor3       = Theme.TextDim,
        Size             = UDim2.new(0, 60, 1, 0),
        Position         = UDim2.new(1, -75, 0, 0),
        Parent           = headCell,
    })

    local function updateCount()
        local n = 0
        for _ in pairs(selectedSet) do n = n + 1 end
        countLbl.Text = n .. " of " .. #cfg.Items
        if cfg.Callback then cfg.Callback(selectedSet) end
    end
    updateCount()

    for i, item in ipairs(cfg.Items) do
        local row = NewButton({
            Size             = UDim2.new(1, 0, 0, ROW_H),
            BackgroundColor3 = Theme.RowBg,
            LayoutOrder      = startOrder + i,
            Parent           = parent,
        })
        row.MouseEnter:Connect(function() Tween(row, { BackgroundColor3 = Theme.RowHover }, ANIM_FAST) end)
        row.MouseLeave:Connect(function() Tween(row, { BackgroundColor3 = Theme.RowBg },    ANIM_FAST) end)

        local lbl = NewLabel({
            Text             = item,
            TextSize         = 13,
            TextColor3       = selectedSet[item] and Theme.TextActive or Theme.Text,
            Size             = UDim2.new(1, -40, 1, 0),
            Position         = UDim2.new(0, 20, 0, 0),
            Parent           = row,
        })

        local check = NewLabel({
            Text             = "✓",
            Font             = Enum.Font.GothamBold,
            TextSize         = 13,
            TextColor3       = Theme.CheckColor,
            TextXAlignment   = Enum.TextXAlignment.Right,
            Size             = UDim2.new(0, 20, 1, 0),
            Position         = UDim2.new(1, -25, 0, 0),
            TextTransparency = selectedSet[item] and 0 or 1,
            Parent           = row,
        })

        Separator(row, ROW_H - 1)

        row.MouseButton1Click:Connect(function()
            if selectedSet[item] then
                selectedSet[item] = nil
            else
                selectedSet[item] = true
            end
            Tween(check, { TextTransparency = selectedSet[item] and 0 or 1 }, ANIM_FAST)
            Tween(lbl, { TextColor3 = selectedSet[item] and Theme.TextActive or Theme.Text }, ANIM_FAST)
            updateCount()
        end)
    end

    return startOrder + #cfg.Items + 1
end

-- ============================================================
--  BUILD SUB-PAGE CONTENTS
-- ============================================================
local function BuildSubPage(subFrame, items)
    local subLayout = Instance.new("UIListLayout")
    subLayout.SortOrder   = Enum.SortOrder.LayoutOrder
    subLayout.Padding     = UDim.new(0, 0)
    subLayout.Parent      = subFrame

    local order = 2 -- 0 = back row (pre-built), 1 = separator
    for _, item in ipairs(items) do
        local t = item.Type

        if t == "Slider" then
            CreateSlider(subFrame, item, order)
            order = order + 1

        elseif t == "Toggle" then
            local enabled = item.Default or false
            local row = NewButton({
                Size             = UDim2.new(1, 0, 0, ROW_H),
                BackgroundColor3 = Theme.RowBg,
                LayoutOrder      = order,
                Parent           = subFrame,
            })
            row.MouseEnter:Connect(function() Tween(row, { BackgroundColor3 = Theme.RowHover }, ANIM_FAST) end)
            row.MouseLeave:Connect(function() Tween(row, { BackgroundColor3 = Theme.RowBg },    ANIM_FAST) end)

            NewLabel({
                Text             = item.Name,
                Size             = UDim2.new(1, -65, 1, 0),
                Position         = UDim2.new(0, 15, 0, 0),
                Parent           = row,
            })
            Separator(row, ROW_H - 1)

            local _, _, setFn = CreatePillToggle(row, PANEL_W - 55, ROW_H/2, enabled, item.Callback)
            row.MouseButton1Click:Connect(function()
                enabled = not enabled
                setFn(enabled)
            end)
            order = order + 1

        elseif t == "MultiSelect" then
            order = CreateMultiSelect(subFrame, item, order)

        elseif t == "Label" then
            local lCell = NewFrame({
                Size             = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
                LayoutOrder      = order,
                Parent           = subFrame,
            })
            NewLabel({
                Text             = item.Name,
                TextSize         = 11,
                Font             = Enum.Font.GothamBold,
                TextColor3       = Theme.TextDim,
                Size             = UDim2.new(1, -30, 1, 0),
                Position         = UDim2.new(0, 15, 0, 0),
                Parent           = lCell,
            })
            order = order + 1
        end
    end

    subLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        subFrame.CanvasSize = UDim2.new(0, 0, 0, subLayout.AbsoluteContentSize.Y + 8)
    end)
end

-- ============================================================
--  MAIN LIBRARY
-- ============================================================
local ZenovaLib  = {}
ZenovaLib.__index = ZenovaLib

function ZenovaLib:CreateWindow(config)
    config = config or {}
    local title       = config.Title       or "Zenova"
    local toggleKey   = config.ToggleKey   or Enum.KeyCode.RightShift

    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name            = "ZenovaUI_" .. title
    gui.ResetOnSpawn    = false
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset  = true
    gui.DisplayOrder    = 999

    local ok = pcall(function()
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end)
    if not ok then
        gui.Parent = game:GetService("CoreGui")
    end

    -- Root container (holds all panels side-by-side)
    local root = NewFrame({
        Name             = "Root",
        Size             = UDim2.new(0, 0, 0, PANEL_H),
        Position         = config.Position or UDim2.new(0, 200, 0, 200),
        BackgroundTransparency = 1,
        Parent           = gui,
    })

    local rootLayout = Instance.new("UIListLayout")
    rootLayout.FillDirection = Enum.FillDirection.Horizontal
    rootLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    rootLayout.Padding       = UDim.new(0, GAP)
    rootLayout.Parent        = root

    -- --------------------------------------------------------
    --  Window object
    -- --------------------------------------------------------
    local Window = {
        Gui       = gui,
        Root      = root,
        Tabs      = {},
        Visible   = true,
    }

    -- Toggle visibility
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode == toggleKey then
            Window.Visible = not Window.Visible
            for _, tab in ipairs(Window.Tabs) do
                tab._panel.Visible = Window.Visible
            end
        end
    end)

    -- Update root width whenever a tab is added
    local function refreshRootSize()
        local n = #Window.Tabs
        root.Size = UDim2.new(0, n * PANEL_W + math.max(0, n-1) * GAP, 0, PANEL_H)
    end

    -- ----------------------------------------------------
    --  CreateTab
    -- ----------------------------------------------------
    function Window:CreateTab(tabCfg)
        tabCfg = tabCfg or {}
        local tabName = tabCfg.Name or "Tab"
        local tabIcon = tabCfg.Icon or ""

        -- ── Panel frame ──────────────────────────────────
        local panel = NewFrame({
            Name             = tabName,
            Size             = UDim2.new(0, PANEL_W, 0, PANEL_H),
            BackgroundColor3 = Theme.PanelBg,
            LayoutOrder      = #Window.Tabs + 1,
            ClipsDescendants = true,
            Parent           = root,
        })
        Round(panel, CORNER)

        -- ── Header ───────────────────────────────────────
        local header = NewFrame({
            Name             = "Header",
            Size             = UDim2.new(1, 0, 0, HEADER_H),
            BackgroundColor3 = Theme.HeaderBg,
            Parent           = panel,
        })
        Round(header, CORNER)

        -- patch: fill bottom corners of header
        NewFrame({
            Size             = UDim2.new(1, 0, 0, CORNER),
            Position         = UDim2.new(0, 0, 1, -CORNER),
            BackgroundColor3 = Theme.HeaderBg,
            Parent           = header,
        })

        -- Tab name label
        NewLabel({
            Text             = tabName,
            Font             = Enum.Font.GothamBold,
            TextSize         = 14,
            TextColor3       = Theme.Text,
            Size             = UDim2.new(1, -36, 1, 0),
            Position         = UDim2.new(0, 14, 0, 0),
            Parent           = header,
        })

        -- Icon label (top-right)
        NewLabel({
            Text             = tabIcon,
            TextSize         = 14,
            TextXAlignment   = Enum.TextXAlignment.Center,
            TextColor3       = Theme.TextDim,
            Size             = UDim2.new(0, 24, 1, 0),
            Position         = UDim2.new(1, -28, 0, 0),
            Parent           = header,
        })

        -- Header separator
        NewFrame({
            Size             = UDim2.new(1, 0, 0, 1),
            Position         = UDim2.new(0, 0, 0, HEADER_H),
            BackgroundColor3 = Theme.Separator,
            Parent           = panel,
        })

        -- Make the whole window draggable via the header
        MakeDraggable(root, header)

        -- ── Main scroll frame ─────────────────────────────
        local mainScroll = Instance.new("ScrollingFrame")
        mainScroll.Name                 = "MainScroll"
        mainScroll.Size                 = UDim2.new(1, 0, 1, -(HEADER_H + 1))
        mainScroll.Position             = UDim2.new(0, 0, 0, HEADER_H + 1)
        mainScroll.BackgroundTransparency = 1
        mainScroll.BorderSizePixel      = 0
        mainScroll.ScrollBarThickness   = 2
        mainScroll.ScrollBarImageColor3 = Theme.ScrollBar
        mainScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
        mainScroll.ScrollingDirection   = Enum.ScrollingDirection.Y
        mainScroll.Parent               = panel

        local mainLayout = Instance.new("UIListLayout")
        mainLayout.SortOrder   = Enum.SortOrder.LayoutOrder
        mainLayout.Padding     = UDim.new(0, 0)
        mainLayout.Parent      = mainScroll

        mainLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            mainScroll.CanvasSize = UDim2.new(0, 0, 0, mainLayout.AbsoluteContentSize.Y + 6)
        end)

        -- ── Sub-page scroll frame (hidden) ────────────────
        local subScroll = Instance.new("ScrollingFrame")
        subScroll.Name                  = "SubScroll"
        subScroll.Size                  = UDim2.new(1, 0, 1, -(HEADER_H + 1))
        subScroll.Position              = UDim2.new(0, 0, 0, HEADER_H + 1)
        subScroll.BackgroundTransparency = 1
        subScroll.BorderSizePixel       = 0
        subScroll.ScrollBarThickness    = 2
        subScroll.ScrollBarImageColor3  = Theme.ScrollBar
        subScroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
        subScroll.ScrollingDirection    = Enum.ScrollingDirection.Y
        subScroll.Visible               = false
        subScroll.Parent                = panel

        -- ── Internal helpers ─────────────────────────────
        local itemCount = 0

        local function nextOrder()
            itemCount = itemCount + 1
            return itemCount
        end

        -- Open a sub-page with a back button + custom build function
        local function openSubPage(subName, buildFn)
            -- Wipe old sub-page content
            for _, c in ipairs(subScroll:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end

            -- Back row
            local backRow = NewButton({
                Size             = UDim2.new(1, 0, 0, ROW_H + 2),
                BackgroundColor3 = Theme.RowBg,
                LayoutOrder      = 0,
                Parent           = subScroll,
            })
            backRow.MouseEnter:Connect(function() Tween(backRow, { BackgroundColor3 = Theme.RowHover }, ANIM_FAST) end)
            backRow.MouseLeave:Connect(function() Tween(backRow, { BackgroundColor3 = Theme.RowBg    }, ANIM_FAST) end)

            NewLabel({
                Text             = "‹  " .. subName,
                Font             = Enum.Font.GothamBold,
                TextSize         = 13,
                TextColor3       = Theme.TextActive,
                Size             = UDim2.new(1, -20, 1, 0),
                Position         = UDim2.new(0, 12, 0, 0),
                Parent           = backRow,
            })

            -- Separator after back row
            local sepRow = NewFrame({
                Size             = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Theme.Separator,
                LayoutOrder      = 1,
                Parent           = subScroll,
            })

            -- Slide in animation: sub-page starts at x=PANEL_W, slides to 0
            subScroll.Position = UDim2.new(0, PANEL_W, 0, HEADER_H + 1)
            subScroll.Visible  = true
            mainScroll.Visible = false

            Tween(subScroll, { Position = UDim2.new(0, 0, 0, HEADER_H + 1) }, ANIM_MED, Enum.EasingStyle.Quart)

            buildFn(subScroll)

            backRow.MouseButton1Click:Connect(function()
                -- Slide out sub-page
                Tween(subScroll, { Position = UDim2.new(0, PANEL_W, 0, HEADER_H + 1) }, ANIM_MED, Enum.EasingStyle.Quart)
                Tween(mainScroll, { Position = UDim2.new(0, 0, 0, HEADER_H + 1) }, ANIM_MED, Enum.EasingStyle.Quart)
                mainScroll.Position = UDim2.new(0, -PANEL_W, 0, HEADER_H + 1)
                mainScroll.Visible = true
                task.delay(ANIM_MED + 0.02, function()
                    subScroll.Visible = false
                end)
            end)
        end

        -- ── Tab object ────────────────────────────────────
        local Tab = {
            _panel      = panel,
            _mainScroll = mainScroll,
            _subScroll  = subScroll,
        }

        -- ------------------------------------------------
        --  AddToggle
        -- ------------------------------------------------
        function Tab:AddToggle(cfg)
            cfg = cfg or {}
            local enabled = cfg.Default or false
            local order   = nextOrder()

            local row = NewButton({
                Size             = UDim2.new(1, 0, 0, ROW_H),
                BackgroundColor3 = Theme.RowBg,
                LayoutOrder      = order,
                Parent           = mainScroll,
            })
            row.MouseEnter:Connect(function() Tween(row, { BackgroundColor3 = Theme.RowHover }, ANIM_FAST) end)
            row.MouseLeave:Connect(function() Tween(row, { BackgroundColor3 = Theme.RowBg    }, ANIM_FAST) end)

            local lbl = NewLabel({
                Text             = cfg.Name or "Toggle",
                Size             = UDim2.new(1, -36, 1, 0),
                Position         = UDim2.new(0, 15, 0, 0),
                TextColor3       = enabled and Theme.TextActive or Theme.Text,
                Parent           = row,
            })

            local checkLbl = NewLabel({
                Text             = "✓",
                Font             = Enum.Font.GothamBold,
                TextColor3       = Theme.CheckColor,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Right,
                Size             = UDim2.new(0, 22, 1, 0),
                Position         = UDim2.new(1, -26, 0, 0),
                TextTransparency = enabled and 0 or 1,
                Parent           = row,
            })

            Separator(row, ROW_H - 1)

            local function setEnabled(val)
                enabled = val
                Tween(checkLbl, { TextTransparency = val and 0 or 1 }, ANIM_FAST)
                Tween(lbl, { TextColor3 = val and Theme.TextActive or Theme.Text }, ANIM_FAST)
                if cfg.Callback then
                    task.spawn(cfg.Callback, val)
                end
            end

            row.MouseButton1Click:Connect(function()
                setEnabled(not enabled)
            end)

            -- Return control object
            local toggleObj = {}
            function toggleObj:Set(val) setEnabled(val) end
            function toggleObj:Get() return enabled end
            return toggleObj
        end

        -- ------------------------------------------------
        --  AddButton
        -- ------------------------------------------------
        function Tab:AddButton(cfg)
            cfg = cfg or {}
            local order = nextOrder()

            local row = NewButton({
                Size             = UDim2.new(1, 0, 0, ROW_H),
                BackgroundColor3 = Theme.RowBg,
                LayoutOrder      = order,
                Parent           = mainScroll,
            })
            row.MouseEnter:Connect(function() Tween(row, { BackgroundColor3 = Theme.RowHover }, ANIM_FAST) end)
            row.MouseLeave:Connect(function() Tween(row, { BackgroundColor3 = Theme.RowBg    }, ANIM_FAST) end)

            local lbl = NewLabel({
                Text             = cfg.Name or "Button",
                Size             = UDim2.new(1, -30, 1, 0),
                Position         = UDim2.new(0, 15, 0, 0),
                Parent           = row,
            })
            Separator(row, ROW_H - 1)

            row.MouseButton1Click:Connect(function()
                Tween(lbl, { TextColor3 = Theme.TextActive }, 0.05)
                task.delay(0.18, function() Tween(lbl, { TextColor3 = Theme.Text }, ANIM_FAST) end)
                if cfg.Callback then task.spawn(cfg.Callback) end
            end)
        end

        -- ------------------------------------------------
        --  AddExpandable  (navigates to sub-page)
        --  items: array of { Type, Name, ...params }
        -- ------------------------------------------------
        function Tab:AddExpandable(cfg)
            cfg = cfg or {}
            local order = nextOrder()

            local row = NewButton({
                Size             = UDim2.new(1, 0, 0, ROW_H),
                BackgroundColor3 = Theme.RowBg,
                LayoutOrder      = order,
                Parent           = mainScroll,
            })
            row.MouseEnter:Connect(function() Tween(row, { BackgroundColor3 = Theme.RowHover }, ANIM_FAST) end)
            row.MouseLeave:Connect(function() Tween(row, { BackgroundColor3 = Theme.RowBg    }, ANIM_FAST) end)

            NewLabel({
                Text             = cfg.Name or "Section",
                Size             = UDim2.new(1, -36, 1, 0),
                Position         = UDim2.new(0, 15, 0, 0),
                Parent           = row,
            })

            NewLabel({
                Text             = "›",
                Font             = Enum.Font.GothamBold,
                TextSize         = 16,
                TextColor3       = Theme.TextDim,
                TextXAlignment   = Enum.TextXAlignment.Right,
                Size             = UDim2.new(0, 20, 1, 0),
                Position         = UDim2.new(1, -26, 0, 0),
                Parent           = row,
            })

            Separator(row, ROW_H - 1)

            row.MouseButton1Click:Connect(function()
                openSubPage(cfg.Name or "Section", function(sf)
                    BuildSubPage(sf, cfg.Items or {})
                end)
            end)
        end

        -- ------------------------------------------------
        --  AddDropdown  (inline expand)
        -- ------------------------------------------------
        function Tab:AddDropdown(cfg)
            cfg     = cfg     or {}
            local opts      = cfg.Options  or {}
            local selected  = cfg.Default  or opts[1]
            local expanded  = false
            local order     = nextOrder()

            local HEADER_ROW_H = ROW_H
            local OPT_H        = 28
            local collapsedH   = HEADER_ROW_H
            local expandedH    = HEADER_ROW_H + #opts * OPT_H + 4

            local wrapper = NewFrame({
                Size             = UDim2.new(1, 0, 0, collapsedH),
                BackgroundColor3 = Theme.RowBg,
                ClipsDescendants = true,
                LayoutOrder      = order,
                Parent           = mainScroll,
            })

            -- header row (clickable)
            local hRow = NewButton({
                Size             = UDim2.new(1, 0, 0, HEADER_ROW_H),
                BackgroundTransparency = 1,
                Parent           = wrapper,
            })
            hRow.MouseEnter:Connect(function() Tween(wrapper, { BackgroundColor3 = Theme.RowHover }, ANIM_FAST) end)
            hRow.MouseLeave:Connect(function() Tween(wrapper, { BackgroundColor3 = Theme.RowBg    }, ANIM_FAST) end)

            NewLabel({
                Text             = cfg.Name or "Dropdown",
                Size             = UDim2.new(0.55, 0, 1, 0),
                Position         = UDim2.new(0, 15, 0, 0),
                Parent           = hRow,
            })

            local valLbl = NewLabel({
                Text             = tostring(selected),
                TextSize         = 12,
                TextColor3       = Theme.TextDim,
                TextXAlignment   = Enum.TextXAlignment.Right,
                Size             = UDim2.new(0.35, 0, 1, 0),
                Position         = UDim2.new(0.55, 0, 0, 0),
                Parent           = hRow,
            })

            local arrowLbl = NewLabel({
                Text             = "∨",
                Font             = Enum.Font.GothamBold,
                TextSize         = 11,
                TextColor3       = Theme.TextDim,
                TextXAlignment   = Enum.TextXAlignment.Right,
                Size             = UDim2.new(0, 20, 1, 0),
                Position         = UDim2.new(1, -26, 0, 0),
                Parent           = hRow,
            })

            -- Separator under header
            NewFrame({
                Size             = UDim2.new(1, -24, 0, 1),
                Position         = UDim2.new(0, 12, 0, HEADER_ROW_H - 1),
                BackgroundColor3 = Theme.Separator,
                Parent           = wrapper,
            })

            -- Option rows
            for i, opt in ipairs(opts) do
                local optRow = NewButton({
                    Size             = UDim2.new(1, 0, 0, OPT_H),
                    Position         = UDim2.new(0, 0, 0, HEADER_ROW_H + (i-1)*OPT_H + 4),
                    BackgroundTransparency = 1,
                    Parent           = wrapper,
                })
                optRow.MouseEnter:Connect(function() Tween(optRow, { BackgroundTransparency = 0.7 }, ANIM_FAST) end)
                optRow.MouseLeave:Connect(function() Tween(optRow, { BackgroundTransparency = 1   }, ANIM_FAST) end)
                optRow.BackgroundColor3 = Theme.RowHover

                NewLabel({
                    Text             = tostring(opt),
                    TextSize         = 12,
                    TextColor3       = Theme.TextDim,
                    Size             = UDim2.new(1, -36, 1, 0),
                    Position         = UDim2.new(0, 26, 0, 0),
                    Parent           = optRow,
                })

                optRow.MouseButton1Click:Connect(function()
                    selected      = opt
                    valLbl.Text   = tostring(opt)
                    expanded      = false
                    Tween(wrapper,  { Size = UDim2.new(1, 0, 0, collapsedH) }, ANIM_MED)
                    Tween(arrowLbl, { Rotation = 0 }, ANIM_MED)
                    if cfg.Callback then task.spawn(cfg.Callback, opt) end
                end)
            end

            hRow.MouseButton1Click:Connect(function()
                expanded = not expanded
                if expanded then
                    Tween(wrapper,  { Size = UDim2.new(1, 0, 0, expandedH) }, ANIM_MED)
                    Tween(arrowLbl, { Rotation = 180 }, ANIM_MED)
                else
                    Tween(wrapper,  { Size = UDim2.new(1, 0, 0, collapsedH) }, ANIM_MED)
                    Tween(arrowLbl, { Rotation = 0 }, ANIM_MED)
                end
            end)

            -- Control object
            local dropdownObj = {}
            function dropdownObj:Get() return selected end
            function dropdownObj:Set(val)
                if table.find(opts, val) then
                    selected = val
                    valLbl.Text = tostring(val)
                    if cfg.Callback then task.spawn(cfg.Callback, val) end
                end
            end
            return dropdownObj
        end

        -- ------------------------------------------------
        --  AddSlider  (standalone, in main list)
        -- ------------------------------------------------
        function Tab:AddSlider(cfg)
            cfg = cfg or {}
            local order = nextOrder()
            local cell, setFn, getFn = CreateSlider(mainScroll, cfg, order)
            cell.BackgroundTransparency = 1

            local sliderObj = {}
            function sliderObj:Set(val) setFn(val) end
            function sliderObj:Get() return getFn() end
            return sliderObj
        end

        -- ------------------------------------------------
        --  AddLabel  (category header / spacer)
        -- ------------------------------------------------
        function Tab:AddLabel(cfg)
            cfg = cfg or {}
            local order = nextOrder()

            local cell = NewFrame({
                Size             = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
                LayoutOrder      = order,
                Parent           = mainScroll,
            })
            NewLabel({
                Text             = (cfg.Text or ""):upper(),
                TextSize         = 10,
                Font             = Enum.Font.GothamBold,
                TextColor3       = Theme.TextDim,
                Size             = UDim2.new(1, -30, 1, 0),
                Position         = UDim2.new(0, 15, 0, 0),
                Parent           = cell,
            })
        end

        -- ------------------------------------------------
        --  AddSeparator  (thin line)
        -- ------------------------------------------------
        function Tab:AddSeparator()
            local order = nextOrder()
            NewFrame({
                Size             = UDim2.new(1, -24, 0, 1),
                BackgroundColor3 = Theme.Separator,
                LayoutOrder      = order,
                Parent           = mainScroll,
            })
        end

        table.insert(Window.Tabs, Tab)
        refreshRootSize()
        return Tab
    end

    -- --------------------------------------------------------
    --  Window helpers
    -- --------------------------------------------------------
    function Window:Show()
        self.Visible = true
        for _, tab in ipairs(self.Tabs) do
            tab._panel.Visible = true
        end
    end

    function Window:Hide()
        self.Visible = false
        for _, tab in ipairs(self.Tabs) do
            tab._panel.Visible = false
        end
    end

    function Window:Destroy()
        gui:Destroy()
    end

    return Window
end

-- ============================================================
--  RETURN
-- ============================================================
return ZenovaLib


--[[
═══════════════════════════════════════════════════════════════
                    EXAMPLE USAGE SCRIPT
═══════════════════════════════════════════════════════════════

local ZenovaLib = loadstring(game:HttpGet("YOUR_RAW_URL"))()

local Window = ZenovaLib:CreateWindow({
    Title     = "Zenova",
    ToggleKey = Enum.KeyCode.RightShift,
    Position  = UDim2.new(0, 150, 0, 180),
})

-- ── COMBAT ────────────────────────────────────────────────
local Combat = Window:CreateTab({ Name = "Combat", Icon = "⚔" })

Combat:AddExpandable({
    Name  = "Aim Bot",
    Items = {
        {
            Type     = "MultiSelect",
            Name     = "Weapon",
            Items    = { "Sword", "Bow", "Crossbow", "Trident" },
            Selected = { "Sword" },
            Callback = function(sel) end,
        },
        { Type = "Toggle", Name = "Prediction",  Default = true,  Callback = function(v) end },
        { Type = "Toggle", Name = "Silent Aim",  Default = false, Callback = function(v) end },
        { Type = "Slider", Name = "Range",       Min = 0, Max = 200, Default = 100, Decimals = 0, Callback = function(v) end },
        { Type = "Slider", Name = "FOV",         Min = 0, Max = 180, Default = 90,  Decimals = 0, Callback = function(v) end },
    },
})

Combat:AddToggle({ Name = "AimAssist",    Default = false, Callback = function(v) print("AimAssist:", v) end })
Combat:AddToggle({ Name = "Air Target",   Default = false, Callback = function(v) end })
Combat:AddToggle({ Name = "Anti Bot",     Default = false, Callback = function(v) end })
Combat:AddToggle({ Name = "Anti Crystal", Default = false, Callback = function(v) end })
Combat:AddToggle({ Name = "Auto Anchor",  Default = false, Callback = function(v) end })
Combat:AddToggle({ Name = "Auto Armor",   Default = false, Callback = function(v) end })
Combat:AddToggle({ Name = "Auto Cart",    Default = false, Callback = function(v) end })

-- ── MOVEMENT ─────────────────────────────────────────────
local Movement = Window:CreateTab({ Name = "Movement", Icon = "✦" })

Movement:AddExpandable({
    Name  = "Inf HVH Helper",
    Items = {
        { Type = "Slider", Name = "Speed",       Min = 0, Max = 5,   Default = 0.3, Decimals = 1, Callback = function(v) end },
        { Type = "Slider", Name = "AirFactor",   Min = 0, Max = 2,   Default = 0.8, Decimals = 1, Callback = function(v) end },
        { Type = "Slider", Name = "DamageBoost", Min = 0, Max = 1,   Default = 0.1, Decimals = 1, Callback = function(v) end },
        { Type = "Toggle", Name = "AutoJump",    Default = true,  Callback = function(v) end },
        { Type = "Toggle", Name = "KeepSprint",  Default = true,  Callback = function(v) end },
        { Type = "Toggle", Name = "StopOnUse",   Default = true,  Callback = function(v) end },
    },
})

Movement:AddToggle({ Name = "Anti Void",   Default = false, Callback = function(v) end })
Movement:AddToggle({ Name = "Auto Sprint", Default = false, Callback = function(v) end })
Movement:AddToggle({ Name = "Flight",      Default = false, Callback = function(v) end })
Movement:AddToggle({ Name = "No Slow",     Default = false, Callback = function(v) end })
Movement:AddToggle({ Name = "No Web",      Default = false, Callback = function(v) end })
Movement:AddSlider({ Name = "Speed",       Min = 0, Max = 10,  Default = 1,   Decimals = 1, Callback = function(v) end })

-- ── VISUALS ───────────────────────────────────────────────
local Visuals = Window:CreateTab({ Name = "Visuals", Icon = "🔒" })

Visuals:AddToggle({ Name = "Swing Animation", Default = false, Callback = function(v) end })
Visuals:AddToggle({ Name = "TNT Timer",       Default = false, Callback = function(v) end })
Visuals:AddToggle({ Name = "Target ESP",      Default = false, Callback = function(v) end })
Visuals:AddToggle({ Name = "Trails",          Default = false, Callback = function(v) end })
Visuals:AddToggle({ Name = "Trap ESP",        Default = false, Callback = function(v) end })
Visuals:AddToggle({ Name = "View Model",      Default = false, Callback = function(v) end })
Visuals:AddToggle({ Name = "Waypoints",       Default = false, Callback = function(v) end })
Visuals:AddDropdown({
    Name     = "World",
    Options  = { "Overworld", "Nether", "End" },
    Default  = "Overworld",
    Callback = function(v) print("World:", v) end,
})

-- ── PLAYER ────────────────────────────────────────────────
local Player = Window:CreateTab({ Name = "Player", Icon = "◉" })

Player:AddToggle({ Name = "Auto Drop",    Default = false, Callback = function(v) end })
Player:AddToggle({ Name = "Auto Eat",     Default = false, Callback = function(v) end })
Player:AddToggle({ Name = "Auto Farm",    Default = false, Callback = function(v) end })
Player:AddToggle({ Name = "Auto Leave",   Default = false, Callback = function(v) end })
Player:AddToggle({ Name = "Auto Swap",    Default = false, Callback = function(v) end })
Player:AddToggle({ Name = "Blink",        Default = false, Callback = function(v) end })
Player:AddToggle({ Name = "Creeper Farm", Default = false, Callback = function(v) end })
Player:AddToggle({ Name = "Fake Player",  Default = false, Callback = function(v) end })

-- ── OTHER ─────────────────────────────────────────────────
local Other = Window:CreateTab({ Name = "Other", Icon = "···" })

Other:AddToggle({ Name = "Anti Trap",    Default = true,  Callback = function(v) end })
Other:AddToggle({ Name = "Assist",       Default = false, Callback = function(v) end })
Other:AddToggle({ Name = "Auction",      Default = false, Callback = function(v) end })
Other:AddToggle({ Name = "Auto Accept",  Default = false, Callback = function(v) end })
Other:AddToggle({ Name = "Auto Auth",    Default = false, Callback = function(v) end })
Other:AddToggle({ Name = "Auto Duels",   Default = false, Callback = function(v) end })
Other:AddToggle({ Name = "Auto Join",    Default = false, Callback = function(v) end })
Other:AddToggle({ Name = "Auto Resell",  Default = false, Callback = function(v) end })
Other:AddToggle({ Name = "Counter Mine", Default = false, Callback = function(v) end })
Other:AddToggle({ Name = "Death Cords",  Default = false, Callback = function(v) end })

Other:AddExpandable({
    Name  = "Effect Remover",
    Items = {
        { Type = "Toggle", Name = "Remove Blindness",  Default = true,  Callback = function(v) end },
        { Type = "Toggle", Name = "Remove Slowness",   Default = false, Callback = function(v) end },
        { Type = "Toggle", Name = "Remove Weakness",   Default = false, Callback = function(v) end },
        { Type = "Toggle", Name = "Remove Nausea",     Default = false, Callback = function(v) end },
    },
})

]]

<div align="center">

# IXIU UI Library

**A feature-complete, themeable Roblox Lua UI framework**  
*Windows · Tabs · Sections · 10+ Components · Notifications · Auth · Runtime*

---

![Lua](https://img.shields.io/badge/Lua-5.1-blue?style=flat-square&logo=lua)
![Platform](https://img.shields.io/badge/Platform-Roblox-red?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=flat-square)

</div>

---

## Overview

IXIU UI Library is a modular, fully-featured UI framework for Roblox. It provides a windowed GUI system complete with a collapsible sidebar, tabbed navigation, nested sections, a rich set of input components, a notification queue, an authentication gate, and an optional runtime module (`Runtime.luau`) that manages player entity state and named event loop bindings.

---

## Table of Contents

- [File Structure](#file-structure)
- [Quick Start](#quick-start)
- [Library API](#library-api)
  - [Theme](#theme)
  - [Window](#window)
  - [Tab](#tab)
  - [Section](#section)
  - [Components](#components)
    - [Button](#button)
    - [Toggle](#toggle)
    - [Label](#label)
    - [DualLabel](#duallabel)
    - [ClipboardLabel](#clipboardlabel)
    - [Box](#box)
    - [Bind](#bind)
    - [Slider](#slider)
    - [Dropdown](#dropdown)
    - [Picker (Color)](#picker-color)
    - [SubSection](#subsection)
  - [Arraylist](#arraylist)
  - [Notify](#notify)
  - [Auth](#auth)
- [IXIUCore (Runtime)](#ixiucore-runtime)
  - [Entity Tracking](#entity-tracking)
  - [RunLoops](#runloops)
- [Full Example](#full-example)

---

## File Structure

```
IXIU/
├── Library.luau      — Main UI framework
├── UI.lua            — Internal UI creation helpers (required by Library)
└── IXIUCore.luau     — Runtime: entity tracking + named event loops
```

---

## Quick Start

```lua
local Library = require(path.to.Library)
local Core     = require(path.to.IXIUCore)  -- optional runtime

local Window = Library:AddWindow({
    title = { "IXIU", "Hub" },
    key   = Enum.KeyCode.RightControl,
})

local Tab     = Window:AddTab("Combat")
local Section = Tab:AddSection("Aimbot")

local myToggle = Section:AddToggle("Silent Aim", { default = false }, function(bool)
    print("Silent Aim:", bool)
end)
```

---

## Library API

### Theme

Customize the color palette when calling `AddWindow` via the `theme` key, or live via `Window:SetTheme()`.

| Key               | Type     | Default              | Description              |
|-------------------|----------|----------------------|--------------------------|
| `Accent`          | Color3   | `RGB(0, 255, 0)`     | Primary accent color     |
| `TopbarColor`     | Color3   | `RGB(20, 20, 20)`    | Topbar / window chrome   |
| `SidebarColor`    | Color3   | `RGB(15, 15, 15)`    | Sidebar background       |
| `BackgroundColor` | Color3   | `RGB(10, 10, 10)`    | Content area background  |
| `SectionColor`    | Color3   | `RGB(20, 20, 20)`    | Section panel background |
| `TextColor`       | Color3   | `RGB(255, 255, 255)` | All label text           |

---

### Window

```lua
local Window = Library:AddWindow(options)
```

**Options**

| Key             | Type      | Default                   | Description                         |
|-----------------|-----------|---------------------------|-------------------------------------|
| `title`         | `{string, string}` | required         | Two-part title. Second part gets accent background |
| `key`           | KeyCode   | `RightControl`            | Toggle visibility keybind           |
| `fullscreenKey` | KeyCode   | `nil`                     | Toggle fullscreen keybind           |
| `default`       | boolean   | `true`                    | Visible on load                     |
| `theme`         | table     | `nil`                     | Override any theme keys on init     |

**Methods**

```lua
Window:Toggle(bool)              -- Show/hide the window
Window:SetKey(keycode)           -- Change the toggle keybind at runtime
Window:GetKey()                  -- Returns current KeyCode
Window:SetAccent(color)          -- Color3 or "rainbow"
Window:SetTheme(themeTable)      -- Live-update the full theme
Window:SetFullscreen(bool)       -- Expand to fill screen
```

---

### Tab

```lua
local Tab = Window:AddTab("TabName", options?)
```

**Options**

| Key       | Type    | Description                       |
|-----------|---------|-----------------------------------|
| `icon`    | string  | Asset ID for a sidebar icon       |
| `default` | boolean | Auto-select this tab on load      |

**Methods**

```lua
Tab:Show()         -- Select and display this tab
Tab:Hide()         -- Hide this tab's content
Tab:GetHeight()    -- Returns computed pixel height
Tab:UpdateHeight() -- Recalculate canvas size
```

---

### Section

```lua
local Section = Tab:AddSection("SectionName", options?)
```

**Options**

| Key       | Type    | Description                         |
|-----------|---------|-------------------------------------|
| `default` | boolean | Start expanded (`true`) or collapsed |

**Methods**

```lua
Section:SetName(text)   -- Rename the section header
Section:GetName()       -- Returns current header text
Section:GetHeight()     -- Returns computed pixel height
Section:UpdateHeight()  -- Refresh after child changes
```

---

### Components

All components are created via methods on a `Section` or `SubSection` object.

---

#### Button

```lua
local Button = Section:AddButton("Label", callback)
```

Fires `callback()` on click. Includes a ripple visual effect.

---

#### Toggle

```lua
local Toggle = Section:AddToggle("Label", options, callback)
```

**Options**

| Key       | Type    | Description                          |
|-----------|---------|--------------------------------------|
| `flag`    | string  | Key name in `Tab.Flags` (default: name) |
| `default` | boolean | Initial state                        |

**Methods**

```lua
Toggle:Set(bool, instant?)   -- Set state; pass true to skip animation
Toggle:Get()                 -- Returns current boolean
```

**Callback** receives `(bool)`.

---

#### Label

```lua
local Label = Section:AddLabel("Text")
```

**Methods**

```lua
Label:SetName(text)
Label:GetName()
```

Direct reference: `Label.Label` → the underlying TextLabel instance.

---

#### DualLabel

```lua
local DL = Section:AddDualLabel({ "Left Text", "Right Text" })
```

Two labels side-by-side. Left-aligned and right-aligned respectively.

**Methods**

```lua
DL:SetLeftText(text)    DL:GetLeftText()
DL:SetRightText(text)   DL:GetRightText()
```

---

#### ClipboardLabel

```lua
local CL = Section:AddClipboardLabel("Label", callback)
```

Displays a clipboard icon. Clicking fires `callback()`. Useful for copy-to-clipboard flows.

**Methods**

```lua
CL:SetName(text)
CL:GetName()
```

---

#### Box

```lua
local Box = Section:AddBox("Label", options, callback)
```

**Options**

| Key             | Type    | Description                                     |
|-----------------|---------|-------------------------------------------------|
| `extend`        | number  | Expanded width on hover/focus (default: `200`)  |
| `clearonfocus`  | boolean | Clear text on focus (default: `false`)          |
| `fireonempty`   | boolean | Fire callback even if input is empty            |

**Methods**

```lua
Box:SetName(text)       Box:GetName()
Box:SetText(text)       Box:GetText()
Box:SetExtend(number)   Box:GetExtend()
```

Direct reference: `Box.Box` → the TextBox instance.  
**Callback** receives `(text)` on FocusLost.

---

#### Bind

```lua
local Bind = Section:AddBind("Label", Enum.KeyCode.X, options, callback)
```

**Options**

| Key          | Type    | Description                               |
|--------------|---------|-------------------------------------------|
| `flag`       | string  | Flag key (default: name)                  |
| `toggleable` | boolean | Adds a toggle indicator next to the bind  |
| `default`    | boolean | Initial toggle state (if `toggleable`)    |
| `fireontoggle` | boolean | Fire callback on toggle change (default: `true`) |

**Methods**

```lua
Bind:Set(KeyCode)          -- Change the bound key
Bind:Get()                 -- Returns current boolean (toggleable only)
Bind:Toggle(bool, instant?) -- Toggle state (toggleable only)
Bind:SetName(text)         Bind:GetName()
```

**Callback** receives `(KeyCode)` on keypress (and optionally on toggle).

---

#### Slider

```lua
local Slider = Section:AddSlider("Label", min, max, default, options, callback)
```

**Options**

| Key          | Type    | Description                                          |
|--------------|---------|------------------------------------------------------|
| `flag`       | string  | Flag key (default: name)                             |
| `rounded`    | boolean | Floor values to integers                             |
| `cap`        | boolean | Clamp to `[min, max]`                                |
| `dual`       | boolean | Dual-handle range slider; `default` becomes `{v1, v2}` |
| `toggleable` | boolean | Adds a toggle indicator                              |
| `default`    | boolean | Initial toggle state (if `toggleable`)               |
| `fireondrag` | boolean | Fire callback while dragging (default: `true`)       |

**Methods**

```lua
Slider:Set(v1, v2?)       -- Set value(s)
Slider:Get()              -- Returns value (or v1, v2 in dual mode)
Slider:Change(min, max)   -- Update the min/max range
Slider:Toggle(bool, instant?)  -- Toggle state (toggleable only)
Slider:SetName(text)      Slider:GetName()
```

**Callback** for single: `(value, toggleState?)`.  
**Callback** for dual: `(v1, v2, toggleState?)`.

---

#### Dropdown

```lua
local DD = Section:AddDropdown("Label", { "Item1", "Item2" }, options, callback)
```

**Options**

| Key       | Type    | Description                              |
|-----------|---------|------------------------------------------|
| `multi`   | boolean | Allow multiple selections                |
| `default` | string  | Pre-selected item name                   |

**Methods**

```lua
DD:Add(name)           -- Add a new item
DD:Remove(name)        -- Remove an item
DD:ClearList()         -- Remove all items
DD:SetList(list)       -- Replace entire list
DD:Select(name)        -- Programmatically select
DD:Toggle(bool)        -- Open/close the dropdown
DD:SetName(text)       DD:GetName()
```

**Callback** for single: `(selectedString)`.  
**Callback** for multi: `(selectedTable)`.

---

#### Picker (Color)

```lua
local Picker = Section:AddPicker("Label", options, callback)
```

**Options**

| Key     | Type   | Description               |
|---------|--------|---------------------------|
| `color` | Color3 | Initial color (default: Accent) |

**Methods**

```lua
Picker:Set(h, s, v)        -- Set color via HSV components
Picker:Get()               -- Returns h, s, v
Picker:Toggle(bool)        -- Open/close the picker panel
Picker:ToggleRainbow(bool) -- Enable/disable rainbow cycling
Picker:Speed(number)       -- Set rainbow cycle speed
Picker:SetName(text)       Picker:GetName()
```

**Callback** receives `(Color3)` on any change.

---

#### SubSection

A collapsible nested panel inside a Section. Supports all the same components as Section.

```lua
local Sub = Section:AddSubSection("Name", options?)
```

**Options**

| Key       | Type    | Description               |
|-----------|---------|---------------------------|
| `default` | boolean | Start expanded            |

**Available child components:**  
`AddButton` · `AddToggle` · `AddLabel` · `AddDualLabel` · `AddClipboardLabel` · `AddBox` · `AddBind` · `AddSlider` · `AddDropdown` · `AddPicker`

**Methods**

```lua
Sub:SetName(text)   Sub:GetName()
Sub:GetHeight()
Sub:UpdateHeight()
```

---

### Arraylist

A floating HUD list that auto-sorts entries by text width.

```lua
local AL = Library:Arraylist()
```

**Methods**

```lua
AL:Add(name, options)
AL:Edit(name, options)
AL:Remove(name)
```

**`options`** for `Add` / `Edit`

| Key           | Type    | Description                         |
|---------------|---------|-------------------------------------|
| `Text`        | string  | Display text                        |
| `Color`       | Color3  | Side line and glow color            |
| `TextColor`   | Color3  | Text color                          |
| `RichText`    | boolean | Enable RichText on the label        |
| `Background`  | boolean | Show background panel               |
| `Transparency`| number  | Background transparency override    |

---

### Notify

```lua
Library:Notify(options, callback)
```

Queues and displays a sliding notification with Yes/No buttons.

**`options`**

| Key        | Type    | Description                                   |
|------------|---------|-----------------------------------------------|
| `title`    | string  | Notification header                           |
| `text`     | string  | Body content (wraps automatically)            |
| `color`    | Color3  | Optional left indicator strip color           |
| `sound`    | number  | Optional sound asset ID to play on show       |
| `duration` | number  | Auto-dismiss after N seconds (default: `10`)  |

**`callback`** receives `(bool)` — `true` for Yes, `false` for No / auto-dismiss.

**Settings**

```lua
Library.Settings.MaxNotifLines    = 5   -- max wrapped lines per notif
Library.Settings.MaxNotifStacking = 12  -- max simultaneous notifs
```

---

### Auth

```lua
local Menu = Library:Auth({ Key = "your-secret-key" })
```

Displays a fullscreen authentication gate. The window animates in and validates the user's input in real time — green underline for match, red for mismatch. On success, the gate bounces off screen.

Returns a `Menu` table with:

| Field           | Type    | Description                      |
|-----------------|---------|----------------------------------|
| `Authenticated` | boolean | `true` after correct key entered |

---

## IXIUCore (Runtime)

`IXIUCore` is a standalone runtime module that handles two things: **live player entity tracking** and **named event loop management**. It is designed to be required once and shared across all your scripts.

```lua
local Core = require(path.to.IXIUCore)
```

---

### Entity Tracking

All entity references update automatically across character respawns and deaths.

| Field                    | Type      | Description                               |
|--------------------------|-----------|-------------------------------------------|
| `Core.LocalPlayer`       | Player    | Always valid                              |
| `Core.Character`         | Model?    | Current character model, nil when dead    |
| `Core.Humanoid`          | Humanoid? | Nil when dead or respawning               |
| `Core.HumanoidRootPart`  | Part?     | Nil when dead or respawning               |
| `Core.Mouse`             | Mouse     | Always valid                              |
| `Core.Backpack`          | Backpack  | Always valid                              |
| `Core.IsAlive`           | boolean   | Updated every Heartbeat                   |
| `Core.IsActive`          | boolean   | Set to `false` after `DestructAll`        |

**Methods**

```lua
Core.Functions.Get()             -- Snapshot table of all entities
Core.Functions.RefreshCharacter(char)  -- Manually refresh entity refs
Core.Functions.Destruct(conn)    -- Disconnect a single RBXScriptConnection
Core.Functions.DestructAll()     -- Kill all connections + RunLoops, set IsActive = false
```

**Usage pattern**

```lua
Core.RunLoops:BindToHeartbeat("MyAimbot", function()
    if not Core.IsAlive then return end
    -- Core.HumanoidRootPart is guaranteed non-nil here
    local pos = Core.HumanoidRootPart.Position
end)
```

---

### RunLoops

Named connection management for all RunService events and player events. Prevents duplicate binds and makes cleanup trivial.

```lua
-- Bind
Core.RunLoops:BindToRenderStep("name", func)
Core.RunLoops:BindToStepped("name", func)
Core.RunLoops:BindToHeartbeat("name", func)
Core.RunLoops:BindToPreRender("name", func)
Core.RunLoops:BindToPreAnimation("name", func)
Core.RunLoops:BindToPreSimulation("name", func)
Core.RunLoops:BindToPlayerAdded("name", func)
Core.RunLoops:BindToPlayerRemoving("name", func)

-- Unbind (by name)
Core.RunLoops:UnbindFromRenderStep("name")
Core.RunLoops:UnbindFromStepped("name")
Core.RunLoops:UnbindFromHeartbeat("name")
Core.RunLoops:UnbindFromPreRender("name")
Core.RunLoops:UnbindFromPreAnimation("name")
Core.RunLoops:UnbindFromPreSimulation("name")
Core.RunLoops:UnbindFromPlayerAdded("name")
Core.RunLoops:UnbindFromPlayerRemoving("name")

-- Nuke all loop connections
Core.RunLoops:DestructAll()
```

> **Note:** Binding a name that is already bound is a no-op. Unbind first if you need to replace a function.

---

## Full Example

```lua
local Library = require(path.to.Library)
local Core    = require(path.to.IXIUCore)

-- ── Window ───────────────────────────────────────────────────────────
local Window = Library:AddWindow({
    title = { "IXIU", "Hub" },
    key   = Enum.KeyCode.RightControl,
    theme = {
        Accent = Color3.fromRGB(0, 200, 255),
    },
})

-- ── Tab & Section ────────────────────────────────────────────────────
local Tab     = Window:AddTab("Combat", { default = true })
local Section = Tab:AddSection("Settings", { default = true })

-- Toggle
local silentAim = Section:AddToggle("Silent Aim", { default = false }, function(bool)
    -- enable / disable logic
end)

-- Slider
local fovSlider = Section:AddSlider("FOV", 1, 360, 90, { cap = true, rounded = true }, function(val)
    print("FOV:", val)
end)

-- Dual Slider
local rangeSlider = Section:AddSlider(
    "Range", 0, 500, { 50, 300 },
    { dual = true, cap = true, rounded = true },
    function(min, max)
        print("Range:", min, "–", max)
    end
)

-- Dropdown
local teamDD = Section:AddDropdown(
    "Team Filter",
    { "All", "Enemies", "Allies" },
    { default = "All" },
    function(selected)
        print("Filter:", selected)
    end
)

-- Bind
local aimBind = Section:AddBind(
    "Aim Key",
    Enum.KeyCode.Q,
    { toggleable = true, default = true },
    function(key)
        if silentAim:Get() then
            -- aim logic
        end
    end
)

-- Color Picker
local colorPicker = Section:AddPicker("Highlight Color", {
    color = Color3.fromRGB(255, 0, 80),
}, function(color)
    print("New color:", color)
end)

-- ── Notification ─────────────────────────────────────────────────────
Library:Notify({
    title    = "IXIU Hub",
    text     = "Loaded successfully. Press RightControl to toggle.",
    color    = Color3.fromRGB(0, 200, 255),
    duration = 6,
}, function(accepted)
    print("User responded:", accepted)
end)

-- ── Arraylist ────────────────────────────────────────────────────────
local AL = Library:Arraylist()
AL:Add("Silent Aim", { Color = Color3.fromRGB(0, 255, 150), Text = "Silent Aim" })

-- ── IXIUCore runtime loop ────────────────────────────────────────────
Core.RunLoops:BindToHeartbeat("AimbotTick", function()
    if not Core.IsAlive then return end
    if not aimBind:Get() then return end
    -- Core.HumanoidRootPart, Core.Character etc. all safe to use
end)

-- ── Cleanup on unload ────────────────────────────────────────────────
-- Library:Destroy()         -- destroy the UI
-- Core.Functions.DestructAll()  -- stop all runtime loops
```

---

<div align="center">

**Made by mitixiu :)**

</div>

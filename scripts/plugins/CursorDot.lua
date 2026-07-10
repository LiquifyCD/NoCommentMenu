-- CursorDot.lua
-- A small themed dot that follows the mouse while it's hovering over any
-- No comment window. Implemented as a Framework PLUGIN (via
-- Framework.RegisterPlugin) rather than a standalone script — the plugin's
-- Init(Framework) callback gets the live Framework table, including
-- Framework.Gui (to parent the dot under) and Framework.Windows (to check
-- hover bounds against), so it doesn't need any extra wiring.
--
-- SETUP:
--   Put this in a LocalScript that runs AFTER Framework.lua has executed.

repeat task.wait() until shared.NoComment and shared.NoComment.Ready
local Framework = shared.NoComment

Framework.RegisterPlugin("CursorDot", {
	Init = function(Fw)
		local RunService = game:GetService("RunService")
		local UserInputService = game:GetService("UserInputService")

		local theme = Fw.Theme.Values

		local dot = Instance.new("Frame")
		dot.Name = "CursorDot"
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Size = UDim2.fromOffset(8, 8)
		dot.BackgroundColor3 = theme.Accent
		dot.BorderSizePixel = 0
		dot.Visible = false
		dot.ZIndex = 100000 -- above windows, notifications, command palette, etc.
		dot.Parent = Fw.Gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0) -- perfect circle regardless of size
		corner.Parent = dot

		-- Keep the dot's color in sync if the theme changes (Dark/Light/custom)
		Fw.Theme.Changed:Connect(function(newTheme)
			dot.BackgroundColor3 = newTheme.Accent
		end)

		local function isHoveringWindow(win, pos)
			if not win or not win.Frame or not win.Frame.Visible then
				return false
			end
			local absPos = win.Frame.AbsolutePosition
			local absSize = win.Frame.AbsoluteSize
			return pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
				and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y
		end

		RunService.RenderStepped:Connect(function()
			local mouse = UserInputService:GetMouseLocation()
			local hovering = false

			for _, win in pairs(Fw.Windows) do
				if isHoveringWindow(win, mouse) then
					hovering = true
					break
				end
			end

			dot.Visible = hovering
			if hovering then
				dot.Position = UDim2.fromOffset(mouse.X, mouse.Y)
			end
		end)
	end,
})

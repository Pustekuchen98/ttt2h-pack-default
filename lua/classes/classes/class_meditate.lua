if SERVER then
	resource.AddFile("materials/vgui/ttt/heroes/status/hud_icon_meditate.png")

	util.AddNetworkString("TTTCGesture")
end

-- register status effect icon
if CLIENT then
	hook.Add("Initialize", "ttt2h_status_meditate_init", function() 
		STATUS:RegisterStatus("ttt2h_status_meditate", {
			hud = Material("vgui/ttt/heroes/status/hud_icon_meditate.png"),
			type = "good"
		})
	end)
end

local function ActivateMeditate(ply)
	if SERVER then
		net.Start("TTTCGesture")
		net.WriteUInt(ACT_GMOD_TAUNT_CHEER, 32)
		net.WriteEntity(ply)
		net.Broadcast()

		ply:Freeze(true)

		ply.meditateCol = ply:GetColor()
		ply.meditateColMode = ply:GetRenderMode()

		local col = table.Copy(ply.meditateCol)
		col.a = math.Round(col.a * 0.5)

		ply:SetColor(col)
		ply:SetRenderMode(RENDERMODE_TRANSALPHA)

		timer.Create("class_gesture_" .. ply:UniqueID(), 1, 0, function()
			if IsValid(ply) then
				local health = ply:Health()

				ply:SetHealth(math.Clamp(health + 5, health, ply:GetMaxHealth()))
			end
		end)

		-- add status effect
		STATUS:AddStatus(ply, "ttt2h_status_meditate")
	end
end

local function DeactivateMeditate(ply)
	if SERVER then
		ply:RemoveGesture(ACT_GMOD_TAUNT_CHEER) -- TODO necessary ?
		ply:Freeze(false)
		ply:SetColor(ply.meditateCol)
		ply:SetRenderMode(ply.meditateColMode)

		timer.Remove("class_gesture_" .. ply:UniqueID())

		-- remove status effect
		STATUS:RemoveStatus(ply, "ttt2h_status_meditate")
	end
end

CLASS.AddClass("MEDITATE", {
		color = Color(160, 204, 66, 255),
		onActivate = ActivateMeditate,
		onDeactivate = DeactivateMeditate,
		endless = true,
		cooldown = 30,
		langs = {
			English = "Meditate"
		}
})

if CLIENT then
	net.Receive("TTTCGesture", function()
		local gesture = net.ReadUInt(32)
		local target = net.ReadEntity()

		if IsValid(target) then
			target:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, gesture, false)
		end
	end)
end
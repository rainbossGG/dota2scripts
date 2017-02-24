local InvokerExtended = {}

InvokerExtended.autoSunStrikeOption = Menu.AddOption({"Hero Specific", "Invoker Extended"}, "Auto Sun Strike", "On/Off")
InvokerExtended.autoAlacrityOption = Menu.AddOption({"Hero Specific", "Invoker Extended"}, "Auto Alacrity", "On/Off")
InvokerExtended.autoSwitchInstanceOption = Menu.AddOption({"Hero Specific", "Invoker Extended"}, "Auto Switch Instance", "On/Off")
InvokerExtended.font = Renderer.LoadFont("Tahoma", 30, Enum.FontWeight.EXTRABOLD)

function InvokerExtended.OnUpdate()
	local myHero = Heroes.GetLocal()
	if not myHero or NPC.GetUnitName(myHero) ~= "npc_dota_hero_invoker" then return end

	local Q = NPC.GetAbilityByIndex(myHero, 0)
	local W = NPC.GetAbilityByIndex(myHero, 1)
	local E = NPC.GetAbilityByIndex(myHero, 2)
	local R = NPC.GetAbilityByIndex(myHero, 5)

	if Menu.IsEnabled(InvokerExtended.autoAlacrityOption) then
		InvokerExtended.AutoAlacrity(myHero, Q, W, E, R)
	end

	if Menu.IsEnabled(InvokerExtended.autoSunStrikeOption) then
		InvokerExtended.AutoSunStrike(myHero, Q, W, E, R)
	end	

	if Menu.IsEnabled(InvokerExtended.autoSwitchInstanceOption) then
		InvokerExtended.AutoSwitchInstance(myHero, Q, W, E, R)
	end	

end

-- auto cast alacrity after cold snap
function InvokerExtended.AutoAlacrity(myHero, Q, W, E, R)
	if NPC.IsStunned(myHero) or NPC.IsSilenced(myHero) then return end
	
	local myMana = NPC.GetMana(myHero)
	local invokeManaCost = NPC.HasItem(myHero, "item_ultimate_scepter", true) and 0 or 60

	local alacrity = NPC.GetAbility(myHero, "invoker_alacrity")
	local cold_snap = NPC.GetAbility(myHero, "invoker_cold_snap")
	local hasUsedColdSnap = false
	for i = 1, Heroes.Count() do
		local enemy = Heroes.Get(i)
		if NPC.HasModifier(enemy, "modifier_invoker_cold_snap") then
			hasUsedColdSnap = true
		end
	end

	if alacrity and Ability.IsCastable(alacrity, myMana-invokeManaCost) and hasUsedColdSnap then
		if not hasInvoked(myHero, alacrity) then
			Ability.CastNoTarget(W)
			Ability.CastNoTarget(W)
			Ability.CastNoTarget(E)
			Ability.CastNoTarget(R)
		end
		Ability.CastTarget(alacrity, myHero, true)
		Ability.CastNoTarget(E)
		Ability.CastNoTarget(E)
		Ability.CastNoTarget(E)
	end

	sleep(0.02)
end

-- To be done
function InvokerExtended.AutoSunStrike(myHero, Q, W, E, R)
	if NPC.IsStunned(myHero) or NPC.IsSilenced(myHero) then return end
	
	local myMana = NPC.GetMana(myHero)
	local invokeManaCost = NPC.HasItem(myHero, "item_ultimate_scepter", true) and 0 or 60
	local sunstrike = NPC.GetAbility(myHero, "invoker_sun_strike")
	if not sunstrike then return end
	
	for i = 1, Heroes.Count() do
		local enemy = Heroes.Get(i)
		if not NPC.IsIllusion(enemy) and not Entity.IsSameTeam(myHero, enemy) and not Entity.IsDormant(enemy) and Entity.IsAlive(enemy) then

			local pos = NPC.GetAbsOrigin(enemy)

			-- auto cast sunstrike when enemy is in a fixed position
			if inFixedPosition(enemy) then
				if not hasInvoked(myHero, sunstrike) and Ability.IsCastable(sunstrike, myMana-invokeManaCost) then
					Ability.CastNoTarget(E)
					Ability.CastNoTarget(E)
					Ability.CastNoTarget(E)
					Ability.CastNoTarget(R)
					Ability.CastPosition(sunstrike, pos)
				end
				if hasInvoked(myHero, sunstrike)and Ability.IsCastable(sunstrike, myMana) then
					Ability.CastPosition(sunstrike, pos)
				end
			end


		end
	end

end

-- this function lags as hell. recommend to turn it off
function InvokerExtended.AutoSwitchInstance(myHero, Q, W, E, R)
	if NPC.IsStunned(myHero) or NPC.IsSilenced(myHero) then return end
	local QWEState = getQWEState(myHero)
	local switchManaCost = 0
	
	-- Log.Write("W: " .. tostring(Ability.IsCastable(W, switchManaCost)))
	
	if NPC.IsRunning(myHero) then
		if QWEState ~= "WWW" then
			if Ability.IsCastable(W, switchManaCost) then
				Ability.CastNoTarget(W, true)
				Ability.CastNoTarget(W, true)
				Ability.CastNoTarget(W, true)
			end
		end
	elseif NPC.IsAttacking(myHero) then
		if QWEState ~= "EEE" then
			if Ability.IsCastable(E, switchManaCost) then
				Ability.CastNoTarget(E, true)
				Ability.CastNoTarget(E, true)
				Ability.CastNoTarget(E, true)
			end
		end
	else
		if QWEState ~= "QQQ" then
			if Ability.IsCastable(Q, switchManaCost) then
				Ability.CastNoTarget(Q, true)
				Ability.CastNoTarget(Q, true)
				Ability.CastNoTarget(Q, true)
			end
		end
	end

	sleep(0.02)
end

-- return current state of QWE ("QWE", "QQQ", "EEE", etc)
function getQWEState(myHero)
	local modTable = NPC.GetModifiers(myHero)
	local Q_num, W_num, E_num = 0, 0, 0
	
	for i, mod in ipairs(modTable) do
		if Modifier.GetName(mod) == "modifier_invoker_quas_instance" then
			Q_num = Q_num + 1
		elseif Modifier.GetName(mod) == "modifier_invoker_wex_instance" then
			W_num = W_num + 1
		elseif Modifier.GetName(mod) == "modifier_invoker_exort_instance" then
			E_num = E_num + 1
		end
	end

	local QWE_text = ""
	while Q_num > 0 do QWE_text = QWE_text .. "Q"; Q_num = Q_num - 1 end
	while W_num > 0 do QWE_text = QWE_text .. "W"; W_num = W_num - 1 end
	while E_num > 0 do QWE_text = QWE_text .. "E"; E_num = E_num - 1 end

	return QWE_text
end

-- return whether a spell has been invoked.
function hasInvoked(myHero, spell)
	if not myHero or not spell then return false end
	local spell_1 = NPC.GetAbilityByIndex(myHero, 3)
	local spell_2 = NPC.GetAbilityByIndex(myHero, 4)
	return (spell == spell_1) or (spell == spell_2)
end

-- return true if npc is stunned, rooted, duel by LC, etc
function inFixedPosition(npc)
	return NPC.HasState(npc, Enum.ModifierState.MODIFIER_STATE_ROOTED) 
	or NPC.HasState(npc, Enum.ModifierState.MODIFIER_STATE_ROOTED)
	or NPC.HasModifier(npc, "modifier_legion_commander_duel")
	or NPC.HasModifier(npc, "modifier_axe_berserkers_call")
	or NPC.HasModifier(npc, "modifier_faceless_void_chronosphere")
	or NPC.HasModifier(npc, "modifier_enigma_black_hole_pull")
end

-- 0.02s delay works good for me
local clock = os.clock
function sleep(n)  -- seconds
    local t0 = clock()
    while clock() - t0 <= n do end
end

return InvokerExtended
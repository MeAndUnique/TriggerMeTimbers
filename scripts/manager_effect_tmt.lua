--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

rCombatantHasEffectCondition = nil;

rRemoveCombatantEffectAction = nil;

function onInit()
	initializeConditions();
	initializeActions()
end

function initializeConditions()
	rCombatantHasEffectCondition = {
		sName = "combatant_has_effect_condition",
		fCondition = combatantHasEffectCondition,
		aConfigurableParameters = {
			TriggerData.rCombatantParameter,
			{
				sName = "sEffectName",
				sDisplay = "effect_name_parameter",
				sType = "string"
			},
		},
	};

	TriggerManager.defineCondition(rCombatantHasEffectCondition);
end

function initializeActions()
	rRemoveCombatantEffectAction = {
		sName = "remove_effect_from_combatant_action",
		fAction = removeCombatantEffect,
		aConfigurableParameters = {
			TriggerData.rCombatantParameter,
			{
				sName = "sEffectName",
				sDisplay = "effect_name_parameter",
				sType = "string"
			},
		},
	};

	TriggerManager.defineAction(rRemoveCombatantEffectAction);
end

function combatantHasEffectCondition(rTriggerData, rEventData)
	local rCombatant = TriggerData.resolveCombatant(rTriggerData, rEventData);
	return EffectManager.hasEffect(rCombatant, rTriggerData.sEffectName);
end

function removeCombatantEffect(rTriggerData, rEventData)
	local rCombatant = TriggerData.resolveCombatant(rTriggerData, rEventData);
	EffectManager.removeEffect(ActorManager.getCTNode(rCombatant), rTriggerData.sEffectName);
end
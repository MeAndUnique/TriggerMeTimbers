--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

rAfterAttackRollEvent = {
	sName = "after_attack_event",
	aParameters = {
		"rSource",
		"rTarget",
		"nAttack",
		"rRoll",
	}
}
rAttackResultCondition = nil;

local fApplyAttackOriginal;

function onInit()
	fApplyAttackOriginal = ActionAttack.applyAttack;
	ActionAttack.applyAttack = applyAttack;

	initializeConditions();
	TriggerManager.defineEvent(rAfterAttackRollEvent);
end

function initializeConditions()
	rAttackResultCondition = {
		sName = "attack_result_condition",
		fCondition = attackMatchesResultCondition,
		aRequiredParameters = {
			"rSource",
			"rTarget",
			"nAttack",
			"rRoll"
		},
		aConfigurableParameters = {
			{
				sName = "sAttackResult",
				sDisplay = "attack_result_property_parameter",
				sType = "combo",
				aDefinedValues = {
					"attack_result_property_hit",
					"attack_result_property_miss",
					"attack_result_property_critical",
					"attack_result_property_fumble"
				}
			}
		}
	}

	TriggerManager.defineCondition(rAttackResultCondition);
end

function attackMatchesResultCondition(rTriggerData, rEventData)
	if rTriggerData.sAttackResult == "attack_result_property_hit" then
		return (rEventData.rRoll.sResult == "hit") or (rEventData.rRoll.sResult == "crit");
	elseif rTriggerData.sAttackResult == "attack_result_property_critical" then
		return rEventData.rRoll.sResult == "crit";
	elseif rTriggerData.sAttackResult == "attack_result_property_miss" then
		return (rEventData.rRoll.sResult == "miss") or (rEventData.rRoll.sResult == "fumble");
	elseif rTriggerData.sAttackResult == "attack_result_property_fumble" then
		return rEventData.rRoll.sResult == "fumble";
	end

	return false;
end

function applyAttack(rSource, rTarget, rRoll)
	fApplyAttackOriginal(rSource, rTarget, rRoll);

	local rEventData = {
		rSource = rSource,
		rTarget = rTarget,
		nAttack = rRoll.nTotal,
		rRoll = rRoll,
	}
	TriggerManager.fireEvent(rAfterAttackRollEvent.sName, rEventData);
end
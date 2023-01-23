--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

rApplyHpCombatantAction = nil;

function onInit()
	initializeActions();
end

function initializeActions()
	-- TODO: Add more parameters to this action
	-- For spending healing surges, maybe adding dice instead of a flat value
	rApplyHpCombatantAction = {
		sName = "apply_heal_to_combatant_action",
		fAction = applyHpToCombatant,
		aConfigurableParameters = {
			TriggerData.rCombatantParameter,
			{
				sName = "sLabel",
				sDisplay = "apply_heal_label_parameter",
				sType = "string"
			},
			{
				sName = "sType",
				sDisplay = "apply_heal_type_parameter",
				sType = "combo",
				aDefinedValues = {
					"apply_heal_type_hitpoints",
					"apply_heal_type_temphitpoints"
				}
			},
			{
				sName = "nValue",
				sDisplay = "apply_heal_value_parameter",
				sType = "number"
			}
		}
	}

	TriggerManager.defineAction(rApplyHpCombatantAction);
end

function applyHpToCombatant(rTriggerData, rEventData)
	local rAction = {};
	rAction.type = "heal";
	rAction.name = rTriggerData.sLabel or "";
	rAction.order = 0;
	rAction.range = "";
	rAction.sTargeting = "self";
	rAction.clauses = {};

	local rHealClause = {};
	rHealClause.dicestr = "" .. rTriggerData.nValue;
	rHealClause.cost = 0;
	rHealClause.basemult = 0;
	rHealClause.stat = {};

	if rTriggerData.sType == "apply_heal_type_hitpoints" then
		rHealClause.subtype = "";
	elseif rTriggerData.sType == "apply_heal_type_temphitpoints" then
		rHealClause.subtype = "temp";
	end

	table.insert(rAction.clauses, rHealClause);

	local rActor = TriggerData.resolveCombatant(rTriggerData, rEventData);
	ActionHeal.performRoll(nil, rActor, rAction)
end
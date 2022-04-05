-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

rDiceRolledEvent = {
	sName = "dice_rolled_event",
	aParameters = {"rSource", "rTarget", "rRoll"}
};

rRollIsTypeCondition = nil;
rRollValueCondition = nil;

rRerollDiceAction = nil;
rReplaceDiceAction = nil; -- TODO define

local resolveActionOriginal;

function onInit()
	resolveActionOriginal = ActionsManager.resolveAction;
	ActionsManager.resolveAction = resolveAction;
	
	TriggerManager.defineEvent(rDiceRolledEvent);

	initializeConditions();
	initializeActions();
end

function initializeConditions()
	local aActions = {};
	for sAction,_ in pairs(GameSystem.actions) do
		table.insert(aActions, sAction);
	end

	rRollIsTypeCondition = {
		sName = "roll_is_type_condition",
		fCondition = rollIsType,
		aRequiredParameters = {"rRoll"},
		aConfigurableParameters = {
			{
				sName = "sType",
				sDisplay = "roll_type_parameter",
				sType = "combo",
				aDefinedValues = aActions,
			},
		},
	};
	rRollValueCondition = {
		sName = "roll_is_value_condition",
		fCondition = rollIsType,
		aRequiredParameters = {"rRoll"},
		aConfigurableParameters = {
			{
				sName = "sMatchAgainst",
				sDisplay = "match_against_parameter",
				sType = "combo",
				aDefinedValues = {
					"any_dice",
					"all_dice",
					"sum_dice",
				},
			},
			TriggerData.rComparisonParameter,
			{
				sName = "nCompareAgainst",
				sDisplay = "value_parameter",
				sType = "number",
			},
			{
				sName = "bIncludeModifiers",
				sDisplay = "include_modifiers_parameter",
				sType = "bool",
				fCheckVisibility = checkModifierInclusionVisibility,
			},
		},
	};
	if ActionsManager2 and ActionsManager2.decodeAdvantage then
		table.insert(rRollValueCondition.aConfigurableParameters,
		{
			sName = "bIncludeAdvantage",
			sDisplay = "include_advantage_parameter",
			sType = "bool",
			fCheckVisibility = checkAdvantageInclusionVisibility,
		});
	end
	
	TriggerManager.defineCondition(rRollIsTypeCondition);
	TriggerManager.defineCondition(rRollValueCondition);
end

function initializeActions()
	local rComparisonParameter = UtilityManager.copyDeep(TriggerData.rComparisonParameter);
	rComparisonParameter.fCheckVisibility = checkRerollDiceComparisonVisibility;
	rRerollDiceAction = {
		sName = "reroll_dice_action",
		fAction = rerollDice,
		aRequiredParameters = {"rRoll"},
		aConfigurableParameters = {
			{
				sName = "sSelection",
				sDisplay = "die_selection_parameter",
				sType = "combo",
				aDefinedValues = {
					"all_dice",
					"highest_dice",
					"lowest_dice",
					"matching_dice",
				},
			},
			rComparisonParameter,
			{
				sName = "nCompareAgainst",
				sDisplay = "value_parameter",
				sType = "number",
				fCheckVisibility = checkRerollDiceComparisonVisibility,
			},
		}
	};

	TriggerManager.defineAction(rRerollDiceAction);
end

function resolveAction(rSource, rTarget, rRoll)
	local rEventData = {rSource=rSource, rTarget=rTarget, rRoll=rRoll};
	TriggerManager.fireEvent(rDiceRolledEvent.sName, rEventData);
	return resolveActionOriginal(rSource, rTarget, rRoll);
end

function rollIsType(rTriggerData, rEventData)
	return rTriggerData.sType == rEventData.rRoll.sType;
end

function rollIsValue(rTriggerData, rEventData)
	-- TODO Halfling luck can reroll either one of the dice, but not both
	-- may want to with adv dropping a 1, since the high roll could still be low
	-- Could consider bool for calculating before/after dropping the die, but then any replacement action gets more complicated
	-- Could make this handle each roll individually... only that complicates the "but not both" above
		-- All/Lowest/Highest option on action could resolve that
		-- How to handle post-drop things then, such as reliable talent etc?
	if rTriggerData.bIncludeAdvantage and ActionsManager2 and ActionsManager2.decodeAdvantage then
		ActionsManager2.decodeAdvantage(rEventData.rRoll);
	end

	local nTotal = ActionsManager.total(rEventData.rRoll);
	if not rTriggerData.bIncludeModifiers then
		nTotal = nTotal - rEventData.rRoll.nMod;
	end

	return TriggerHelper.resolveComparison(nTotal, rTriggerData.nCompareAgainst, rTriggerData.sComparison);
end

function rerollDice(rTriggerData, rEventData)
	local fSelect = nil;
	local nIndexToReplace;
	local nExtremity;
	if rTriggerData.sSelection == "lowest_dice" then
		nExtremity = 10000;
		fSelect = function(nCurrent, nIndex)
			if nCurrent < nExtremity then
				nExtremity = nCurrent;
				nIndexToReplace = nIndex;
			end
		end
	elseif rTriggerData.sSelection == "highest_dice" then
		nExtremity = -10000;
		fSelect = function(nCurrent, nIndex)
			if nCurrent > nExtremity then
				nExtremity = nCurrent;
				nIndexToReplace = nIndex;
			end
		end
	end

	for nIndex,rDie in ipairs(rEventData.rRoll.aDice) do
		if not rDie.dropped then
			if fSelect then
				fSelect(rDie.result, nIndex);
			elseif rTriggerData.sSelection ~= "matching_dice" or
				TriggerHelper.resolveComparison(rDie.result, rTriggerData.nCompareAgainst, rTriggerData.sComparison) then
					rEventData.rRoll.sDesc = rEventData.rRoll.sDesc .. " [REROLL " .. rDie.result .. "]";
					rDie.result = DiceManager.evalDie(rDie.type);
			end
		end
	end

	if nIndexToReplace then
		local rDie = rEventData.rRoll.aDice[nIndexToReplace];
		rEventData.rRoll.sDesc = rEventData.rRoll.sDesc .. " [REROLL " .. rDie.result .. "]";
		rDie.result = DiceManager.evalDie(rDie.type);
	end
end

function checkModifierInclusionVisibility(rConditionData)
	return rConditionData.sMatchAgainst == "sum_dice";
end

function checkAdvantageInclusionVisibility(rConditionData)
	return rConditionData.sMatchAgainst == "all_dice";
end

function checkRerollDiceComparisonVisibility(rActionData)
	return rActionData.sSelection == "matching_dice";
end
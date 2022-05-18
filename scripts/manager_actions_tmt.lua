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
		fCondition = rollIsValue,
		aRequiredParameters = {"rRoll"},
		aConfigurableParameters = {
			{
				sName = "sMatchAgainst",
				sDisplay = "match_against_parameter",
				sDescription = "match_against_parameter_description",
				sType = "combo",
				aDefinedValues = {
					{
						sValue = "any_dice",
						sDescription = "any_dice_description",
					},
					{
						sValue = "all_dice",
						sDescription = "all_dice_match_against_description",
					},
					{
						sValue = "sum_dice",
						sDescription = "sum_dice_description",
					},
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

	rReplaceDiceAction = UtilityManager.copyDeep(rRerollDiceAction);
	rReplaceDiceAction.sName = "replace_dice_action";
	rReplaceDiceAction.fAction = replaceDice;
	table.insert(rReplaceDiceAction.aConfigurableParameters,
	{
		sName = "sReplacement",
		sDisplay = "die_replacement_parameter",
		sType = "number",
	});

	TriggerManager.defineAction(rRerollDiceAction);
	TriggerManager.defineAction(rReplaceDiceAction);
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

	-- TODO probably can clean this up a fair bit
	local bResult = false;
	if rTriggerData.sMatchAgainst == "any_dice" then
		for _,rDie in ipairs(rEventData.rRoll.aDice) do
			if not rDie.dropped then
				if TriggerData.resolveComparison(rDie.result, rTriggerData.nCompareAgainst, rTriggerData.sComparison) then
					bResult = true;
					break;
				end
			end
		end
	elseif rTriggerData.sMatchAgainst == "all_dice" then
		local bAllMatch = true;
		for _,rDie in ipairs(rEventData.rRoll.aDice) do
			if not rDie.dropped then
				if not TriggerData.resolveComparison(rDie.result, rTriggerData.nCompareAgainst, rTriggerData.sComparison) then
					bAllMatch = false;
					break;
				end
			end
		end
		bResult = bAllMatch;
	elseif rTriggerData.sMatchAgainst == "sum_dice" then
		local nTotal = ActionsManager.total(rEventData.rRoll);
		if not rTriggerData.bIncludeModifiers then
			nTotal = nTotal - rEventData.rRoll.nMod;
		end
	
		bResult = TriggerData.resolveComparison(nTotal, rTriggerData.nCompareAgainst, rTriggerData.sComparison);
	end

	return bResult;
end

function rerollDice(rTriggerData, rEventData)
	changeDice(rTriggerData, rEventData, "REROLL", DiceManager.evalDie)
end

function replaceDice(rTriggerData, rEventData)
	changeDice(rTriggerData, rEventData, "REPLACE", function(sDieType) return rTriggerData.sReplacement; end)
end

function changeDice(rTriggerData, rEventData, sDisplay, fGetResult)
	local fSelect = nil;
	local nIndicesToReplace = {};
	local nExtremity;
	if rTriggerData.sSelection == "lowest_dice" then
		nExtremity = math.huge;
		fSelect = function(nCurrent, nIndex)
			if nCurrent < nExtremity then
				nExtremity = nCurrent;
				nIndicesToReplace[1] = nIndex;
			end
		end
	elseif rTriggerData.sSelection == "highest_dice" then
		nExtremity = -math.huge;
		fSelect = function(nCurrent, nIndex)
			if nCurrent > nExtremity then
				nExtremity = nCurrent;
				nIndicesToReplace[1] = nIndex;
			end
		end
	end

	for nIndex,rDie in ipairs(rEventData.rRoll.aDice) do
		if not rDie.dropped then
			if fSelect then
				fSelect(rDie.result, nIndex);
			elseif rTriggerData.sSelection ~= "matching_dice" or
				TriggerData.resolveComparison(rDie.result, rTriggerData.nCompareAgainst, rTriggerData.sComparison) then
					table.insert(nIndicesToReplace, nIndex);
			end
		end
	end

	for _,nIndex in ipairs(nIndicesToReplace) do
		local rDie = rEventData.rRoll.aDice[nIndex];
		rEventData.rRoll.sDesc = rEventData.rRoll.sDesc .. " [" .. sDisplay .. " " .. rDie.result .. "]";
		rDie.result = fGetResult(rDie.type);
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
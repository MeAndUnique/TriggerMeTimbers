-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local getDamageAdjustOriginal;
local decodeDamageTextOriginal;
local applyDamageOriginal;
local messageDamageOriginal;

local mathMaxOriginal;
local stringFormatOriginal;

local rActiveSource = nil;
local rActiveTarget = nil;
local rDamageOutput = nil;
local bPrepareForBeforeDamageEvent = false;

rBeforeDamageTakenEvent = {
	sName = "before_damage_taken_event",
	aParameters = {"rSource", "rTarget", "nDamage", "nWounds", "nHitpoints", "nTemporaryHitpoints"}
};

-- TODO damage value comparison
		-- rolls in general? if so roll type needed
		--		geenral roll here confounded by resitances
-- TODO support for configurable parameters that depend on event params
--		damage exceeds wounds is primary use case here
--			which would need secondary configurable for type of comparison

rTargetHasCurrentHitPointsCondition = nil;
rCombatantHasTemporaryHitPointsCondition = nil;
rDamageValueCondition = nil;

rEnsureRemainingHitpointsAction = nil;
rModifyDamageAction = nil;

function onInit()
	getDamageAdjustOriginal = ActionDamage.getDamageAdjust;
	ActionDamage.getDamageAdjust = getDamageAdjust;
	decodeDamageTextOriginal = ActionDamage.decodeDamageText;
	ActionDamage.decodeDamageText = decodeDamageText;
	applyDamageOriginal = ActionDamage.applyDamage;
	ActionDamage.applyDamage = applyDamage;
	messageDamageOriginal = ActionDamage.messageDamage;
	ActionDamage.messageDamage = messageDamage;

	TriggerManager.defineEvent(rBeforeDamageTakenEvent);

	initializeConditions();
	intializeActions();
end

function initializeConditions()
	rTargetHasCurrentHitPointsCondition = {
		sName = "target_has_current_hit_points_condition",
		fCondition = targetHasCurrentHitpoints,
		aRequiredParameters = {"rTarget"},
		aConfigurableParameters = {
			TriggerData.rComparisonParameter,
			{
				sName = "nCompareAgainst",
				sDisplay = "value_parameter",
				sType = "number",
			},
		},
	};

	rCombatantHasTemporaryHitPointsCondition  = {
		sName = "combatant_has_temporary_hit_points_condition",
		fCondition = combatantHasTemporaryHitpoints,
		aConfigurableParameters = {
			{
				sName = "sCombatant",
				sDisplay = "combatant_parameter",
				sType = "combo",
				aDefinedValues = {
					{
						sValue = "source_subject",
						aRequiredParameters = {"rSource"}
					},
					{
						sValue = "target_subject",
						aRequiredParameters = {"rTarget"}
					},
				}
			},
			TriggerData.rComparisonParameter,
			{
				sName = "nCompareAgainst",
				sDisplay = "value_parameter",
				sType = "number",
			},
		},
	};

	rDamageValueCondition = {
		sName = "damage_value_condition",
		fCondition = damageIsValue,
		aRequiredParameters = {"nDamage"},
		aConfigurableParameters = {
			TriggerData.rComparisonParameter,
			{
				sName = "sCompareTo",
				sDisplay = "compare_against_parameter",
				sType = "combo",
				aDefinedValues = {
					"number_parameter",
					{
						sValue = "target_hitpoints_parameter",
						aRequiredParameters = {"rTarget"},
					}
				},
			},
			{
				sName = "nCompareAgainst",
				sDisplay = "value_parameter",
				sType = "number",
				fCheckVisibility = checkDamageValueCompareAgainstVisibility
			}
		},
	};

	TriggerManager.defineCondition(rTargetHasCurrentHitPointsCondition);
	TriggerManager.defineCondition(rCombatantHasTemporaryHitPointsCondition);
	TriggerManager.defineCondition(rDamageValueCondition);
end

function intializeActions()
	rEnsureRemainingHitpointsAction = {
		sName = "ensure_target_has_remaining_hit_points_action",
		fAction = ensureRemainingHitpoints,
		aRequiredParameters = {"nDamage", "nWounds", "nHitpoints"},
		aConfigurableParameters = {
			{
				sName = "nMinimum",
				sDisplay = "minimum_parameter",
				sType = "number",
			},
			{
				sName = "sMessage",
				sDisplay = "chat_message_parameter",
				sType = "string",
			},
		},
	};

	-- TODO resolve behavior for reduced damage interacting with other systems, such as concentration, or life steal
	rModifyDamageAction = {
		sName="modify_damage_action",
		fAction = modifyDamage,
		aRequiredParameters = {"nDamage"},
		aConfigurableParameters = {
			{
				sName = "sModification",
				sDisplay = "modification_parameter",
				sType = "combo",
				aDefinedValues = {
					"modification_add",
					"modification_at_least",
					"modification_at_most",
					"modification_ratio",
					"modification_set_to",
				},
			},
			{
				sName = "sCompareTo",
				sDisplay = "compare_against_parameter",
				sType = "combo",
				aDefinedValues = {
					"number_parameter",
					"target_hitpoints_parameter",
				},
				fCheckVisibility = checkModifyDamageCompareVisibility,
			},
			{
				sName = "nValue",
				sDisplay = "value_parameter",
				sType = "number",
				fCheckVisibility = checkModifyDamageValueVisibility,
			},
			{
				sName = "nOffset",
				sDisplay = "offset_parameter",
				sType = "number",
				fCheckVisibility = checkModifyDamageOffsetVisibility,
			},
			{
				sName = "sMessage",
				sDisplay = "chat_message_parameter",
				sType = "string",
			},
		},
	};

	TriggerManager.defineAction(rEnsureRemainingHitpointsAction);
end

function mathMax(adjustedWounds, zero)
	math.max = mathMaxOriginal;

	local nWounds = getWounds(rActiveTarget);
	local nDamage = nWounds - adjustedWounds;
	local nTotal = getTotalHitPoints(rActiveTarget);

	local rEventData = {rSource=rActiveSource, rTarget=rActiveTarget, nDamage=nDamage, nWounds=nWounds, nHitpoints=nTotal};
	TriggerManager.fireEvent(rBeforeDamageTakenEvent.sName, rEventData);

	return math.max(nWounds - rEventData.nDamage, zero);
end

-- In the event that math.max isn't invoked first, ensure that it is reset.
function stringFormat(sFormat, ...)
	math.max = mathMaxOriginal;
	string.format = stringFormatOriginal;
	return string.format(sFormat, unpack(arg));
end


function getDamageAdjust(rSource, rTarget, nDamage, rDamageOutput)
	local results = {getDamageAdjustOriginal(rSource, rTarget, nDamage, rDamageOutput)};

	if bPrepareForBeforeDamageEvent then
		mathMaxOriginal = math.max;
		math.max = mathMax;
		stringFormatOriginal = string.format;
		string.format = stringFormat;
	end

	bPrepareForBeforeDamageEvent = false;
	return unpack(results);
end

function decodeDamageText(nDamage, sDamageDesc)
	rDamageOutput = decodeDamageTextOriginal(nDamage, sDamageDesc);
	return rDamageOutput;
end

function applyDamage(rSource, rTarget, bSecret, sDamage, nTotal)
	rActiveSource = rSource;
	rActiveTarget = rTarget;
	initialHitPoints = getCurrentHitPoints(rTarget);
	bPrepareForBeforeDamageEvent = true;
	applyDamageOriginal(rSource, rTarget, bSecret, sDamage, nTotal);
end

function messageDamage(rSource, rTarget, bSecret, sDamageType, sDamageDesc, sTotal, sExtraResult)
	messageDamageOriginal(rSource, rTarget, bSecret, sDamageType, sDamageDesc, sTotal, sExtraResult);

	rActiveSource = nil;
	rActiveTarget = nil;
	rDamageOutput = nil;
end

function targetHasCurrentHitpoints(rTriggerData, rEventData)
	if rEventData.rTarget == nil then
		return false;
	end

	local nCurrent = getCurrentHitPoints(rEventData.rTarget);
	return TriggerData.resolveComparison(nCurrent, rTriggerData.nCompareAgainst, rTriggerData.sComparison);
end

function combatantHasTemporaryHitpoints(rTriggerData, rEventData)
	local nTemporary;
	if rTriggerData.sCombatant == "source_subject" then
		nTemporary = getTemporaryHitPoints(rEventData.rSource);
	elseif rTriggerData.sCombatant == "target_subject" then
		nTemporary = getTemporaryHitPoints(rEventData.rTarget);
	end

	return TriggerData.resolveComparison(nTemporary, rTriggerData.nCompareAgainst, rTriggerData.sComparison);
end

function damageIsValue(rTriggerData, rEventData)
	if rTriggerData.sCompareTo == "target_hitpoints_parameter" then
		local nCurrent = getCurrentHitPoints(rEventData.rTarget);
		return TriggerData.resolveComparison(-rEventData.nDamage, nCurrent, rTriggerData.sComparison);
	else
		return TriggerData.resolveComparison(-rEventData.nDamage, rTriggerData.nCompareAgainst, rTriggerData.sComparison);
	end
end

function getCurrentHitPoints(rActor)
	local sType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return 0;
	end

	local nTotal = getTotalHitPoints(rActor, sType, nodeActor);
	local nWounds = getWounds(rActor, sType, nodeActor);
	return nTotal - nWounds;
end

function getTemporaryHitPoints(rActor)
	local sType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return 0;
	end

	local nTemporary;
	if sType == "pc" then
		nTemporary = DB.getValue(nodeActor, "hp.temporary", 0);
	else
		nTemporary = DB.getValue(nodeActor, "hptemp", 0);
	end
	return nTemporary;
end

function getTotalHitPoints(rActor, sType, nodeActor)
	if not nodeActor then
		sType, nodeActor = ActorManager.getTypeAndNode(rActor);
	end
	if not nodeActor then
		return 0;
	end

	local nTotal;
	if sType == "pc" then
		nTotal = DB.getValue(nodeActor, "hp.total", 0);
	else
		nTotal = DB.getValue(nodeActor, "hptotal", 0);
	end
	return nTotal;
end

function getWounds(rActor, sType, nodeActor)
	if not nodeActor then
		sType, nodeActor = ActorManager.getTypeAndNode(rActor);
	end
	if not nodeActor then
		return 0;
	end

	local nTotal, nWounds;
	if sType == "pc" then
		nWounds = DB.getValue(nodeActor, "hp.wounds", 0);
	else
		nWounds = DB.getValue(nodeActor, "wounds", 0);
	end
	return nWounds;
end

function ensureRemainingHitpoints(rTriggerData, rEventData)
	-- TODO what to do about damage sharing?
	-- 		might just work regardless
	local nCurrent = rEventData.nHitpoints - rEventData.nWounds;
	local nInitialDamage = rEventData.nDamage;
	rEventData.nDamage = math.max(rEventData.nDamage, rTriggerData.nMinimum - nCurrent);

	if nInitialDamage ~= rEventData.nDamage then
		table.insert(rDamageOutput.tNotifications, rTriggerData.sMessage);
	end
end

function modifyDamage(rTriggerData, rEventData)
	local nInitialDamage = rEventData.nDamage;
	if rTriggerData.sModification == "modification_add" then
		rEventData.nDamage = rEventData.nDamage + rTriggerData.nValue;
	elseif rTriggerData.sModification == "modification_at_least" then
		if rTriggerData.sCompareTo == "number_parameter" then
			rEventData.nDamage = math.min(rEventData.nDamage, -rTriggerData.nValue);
		elseif rEventData.rTarget and (rTriggerData.sCompareTo == "target_hitpoints_parameter") then
			local nCurrent = (rEventData.nWounds or 0) - (rEventData.nHitpoints or 0);
			rEventData.nDamage = math.min(rEventData.nDamage, nCurrent + rTriggerData.nOffset);
		end
	elseif rTriggerData.sModification == "modification_at_most" then
		if rTriggerData.sCompareTo == "number_parameter" then
			rEventData.nDamage = math.max(rEventData.nDamage, -rTriggerData.nValue);
		elseif rEventData.rTarget and (rTriggerData.sCompareTo == "target_hitpoints_parameter") then
			local nCurrent = (rEventData.nWounds or 0) - (rEventData.nHitpoints or 0);
			rEventData.nDamage = math.max(rEventData.nDamage, nCurrent + rTriggerData.nOffset);
		end
	elseif rTriggerData.sModification == "modification_ratio" then
		rEventData.nDamage = math.floor(rEventData.nDamage * rTriggerData.nValue);
	elseif rTriggerData.sModification == "modification_set_to" then
		if rTriggerData.sCompareTo == "number_parameter" then
			rEventData.nDamage = -rTriggerData.nValue;
		elseif rEventData.rTarget and (rTriggerData.sCompareTo == "target_hitpoints_parameter") then
			local nCurrent = (rEventData.nWounds or 0) - (rEventData.nHitpoints or 0);
			rEventData.nDamage = nCurrent + rTriggerData.nOffset;
		end
	end

	if nInitialDamage ~= rEventData.nDamage then
		table.insert(rDamageOutput.tNotifications, rTriggerData.sMessage);
	end
end

function checkDamageValueCompareAgainstVisibility(rConditionData)
	return rConditionData.sCompareTo == "number_parameter";
end

function checkModifyDamageCompareVisibility(rConditionData)
	return (rConditionData.sModification == "modification_at_least")
		or (rConditionData.sModification == "modification_at_most")
		or (rConditionData.sModification == "modification_set_to");
end

function checkModifyDamageOffsetVisibility(rConditionData)
	return rConditionData.sCompareTo == "target_hitpoints_parameter";
end

function checkModifyDamageValueVisibility(rConditionData)
	return (rConditionData.sModification == "modification_add")
		or (rConditionData.sModification == "modification_ratio")
		or (rConditionData.sCompareTo == "number_parameter");
end
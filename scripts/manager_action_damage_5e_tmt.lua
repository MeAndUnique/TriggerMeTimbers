--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

local getDamageAdjustOriginal;
local applyDamageOriginal;
local messageDamageOriginal;
local resolveDamageOriginal;

local bPrepareForBeforeDamageEvent = false;

rBeforeDamageTakenEvent = nil;

rDamageTypeParameter = nil;

rTargetHasCurrentHitPointsCondition = nil;
rCombatantHasTemporaryHitPointsCondition = nil;
rDamageTypeCondition = nil;
rDamageValueCondition = nil;

rEnsureRemainingHitpointsAction = nil;
rModifyDamageAction = nil;

function onInit()
	getDamageAdjustOriginal = ActionDamage.getDamageAdjust;
	ActionDamage.getDamageAdjust = getDamageAdjust;
	applyDamageOriginal = ActionDamage.applyDamage;
	ActionDamage.applyDamage = applyDamage;
	messageDamageOriginal = ActionDamage.messageDamage;
	ActionDamage.messageDamage = messageDamage;

	if ActionDamageCA then
		resolveDamageOriginal = ActionDamageCA.resolveDamage;
		ActionDamageCA.resolveDamage = resolveDamage;
	end

	initializeEvents();
	initializeParameters();
	initializeConditions();
	intializeActions();
end

function initializeEvents()
	rBeforeDamageTakenEvent = {
		sDescription = "before_damage_taken_event_description",
		sName = "before_damage_taken_event",
		aParameters = {"rSource", "rTarget", "rRoll", "nDamage", "nWounds", "nHitpoints", "nTemporaryHitpoints", "bInterruptable"},
		fResume = resumeApplyDamage
	};

	TriggerManager.defineEvent(rBeforeDamageTakenEvent);
end

function initializeParameters()
	rDamageTypeParameter = {
		sName = "sDamageType",
		sDisplay = "damage_type_parameter",
		sType = "combo",
		aDefinedValues = {},
	};
	for _,sDamage in ipairs(DataCommon.dmgtypes) do
		table.insert(rDamageTypeParameter.aDefinedValues,
		{
			sValue = sDamage,
			sDescription = StringManager.capitalize(sDamage),
		});
	end
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
			TriggerData.rCombatantParameter,
			TriggerData.rComparisonParameter,
			{
				sName = "nCompareAgainst",
				sDisplay = "value_parameter",
				sType = "number",
			},
		},
	};

	rDamageTypeCondition = {
		sName = "damage_type_condition",
		sDescription = "damage_type_condition_description",
		fCondition = damageIsType,
		aRequiredParameters = {"rRoll"},
		aConfigurableParameters = {
			rDamageTypeParameter,
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
	TriggerManager.defineCondition(rDamageTypeCondition);
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

function getDamageAdjust(rSource, rTarget, nDamage, rDamageOutput)
	rTarget.rDamageOutput = rDamageOutput;
	local nDamageAdjust, bVulnerable, bResist = getDamageAdjustOriginal(rSource, rTarget, nDamage, rDamageOutput);

	if bPrepareForBeforeDamageEvent then
		nDamageAdjust, bVulnerable, bResist = fireBeforeDamageEvent(rSource, rTarget, rDamageOutput, nDamageAdjust, bVulnerable, bResist);
	end
	bPrepareForBeforeDamageEvent = false;

	return nDamageAdjust, bVulnerable, bResist;
end

function applyDamage(rSource, rTarget, rRoll)
	bPrepareForBeforeDamageEvent = true;
	rTarget.rRoll = rRoll;
	applyDamageOriginal(rSource, rTarget, rRoll);
	local rPendingInterruption = rTarget.rPendingInterruption;
	if rPendingInterruption then
		TriggerManager.fireInterruption(rPendingInterruption.sEventName, rPendingInterruption.rEventData, rPendingInterruption.rInterruption);
	end
end

function messageDamage(rSource, rTarget, rRoll)
	if not rTarget.rPendingInterruption then
		messageDamageOriginal(rSource, rTarget, rRoll);
	end
end

function resolveDamage(rTarget, rRoll, rComplexDamage)
	if not rTarget.rPendingInterruption then
		resolveDamageOriginal(rTarget, rRoll, rComplexDamage);
	end
end

function fireBeforeDamageEvent(rSource, rTarget, rDamageOutput, nDamageAdjust, bVulnerable, bResist)
	local nWounds = getWounds(rTarget);
	local nTotal = getTotalHitPoints(rTarget);
	local nTemporaryHitpoints = getTemporaryHitPoints(rTarget);

	local rResumedInterruption = rTarget.rPendingInterruption;
	if rResumedInterruption then
		nDamageAdjust = rResumedInterruption.rEventData.nDamageAdjust;
		bVulnerable = rResumedInterruption.rEventData.bVulnerable;
		bResist = rResumedInterruption.rEventData.bResist;
		for sName,vValue in pairs(rResumedInterruption.rEventData.rDamageOutput) do
			rDamageOutput[sName] = vValue;
		end
		rTarget.rPendingInterruption = nil;
	end

	local rEventData = {
		rSource = rSource,
		rTarget = rTarget,
		rRoll = rTarget.rRoll,
		nDamage = rDamageOutput.nVal + nDamageAdjust,
		nWounds = nWounds,
		nHitpoints = nTotal,
		nTemporaryHitpoints = nTemporaryHitpoints
	};

	local rInterruption = TriggerManager.fireEvent(rBeforeDamageTakenEvent.sName, rEventData, (rResumedInterruption or {}).rInterruption);
	if rInterruption then
		rTarget.rPendingInterruption = {
			sEventName = rBeforeDamageTakenEvent.sName,
			rEventData = rEventData,
			rInterruption = rInterruption
		};
		rEventData.rRoll.nOriginalDamage = rEventData.rRoll.nTotal;
		rEventData.nDamageAdjust = nDamageAdjust;
		rEventData.bVulnerable = bVulnerable;
		rEventData.bResist = bResist;
		rEventData.rDamageOutput = UtilityManager.copyDeep(rDamageOutput);

		-- Ensure that no damage is dealt by the remainder of the applyDamage execution.
		nDamageAdjust = -rDamageOutput.nVal;
	elseif rEventData.nAdjust then
		nDamageAdjust = nDamageAdjust + rEventData.nAdjust;
	end

	return nDamageAdjust, bVulnerable, bResist;
end

function resumeApplyDamage(rEventData, _)
	rEventData.rRoll.nTotal = rEventData.rRoll.nOriginalDamage;
	applyDamage(rEventData.rSource, rEventData.rTarget, rEventData.rRoll);
end

function targetHasCurrentHitpoints(rTriggerData, rEventData)
	if rEventData.rTarget == nil then
		return false;
	end

	local nCurrent = getCurrentHitPoints(rEventData.rTarget);
	return TriggerData.resolveComparison(nCurrent, rTriggerData.nCompareAgainst, rTriggerData.sComparison);
end

function combatantHasTemporaryHitpoints(rTriggerData, rEventData)
	local rCombatant = TriggerData.resolveCombatant(rTriggerData, rEventData);
	local nTemporary = getTemporaryHitPoints(rCombatant);
	return TriggerData.resolveComparison(nTemporary, rTriggerData.nCompareAgainst, rTriggerData.sComparison);
end

function damageIsType(rTriggerData, rEventData)
	for sDamageTypes,_ in pairs(rEventData.rRoll.aDamageTypes or {}) do
		if sDamageTypes:match(rTriggerData.sDamageType) then
			return true;
		end
	end
	for _,rClause in ipairs(rEventData.rRoll.clauses or {}) do
		if rClause.dmgtype:match(rTriggerData.sDamageType) then
			return true;
		end
	end

	return false;
end

function damageIsValue(rTriggerData, rEventData)
	if rTriggerData.sCompareTo == "target_hitpoints_parameter" then
		local nCurrent = getCurrentHitPoints(rEventData.rTarget);
		return TriggerData.resolveComparison(rEventData.nDamage, nCurrent, rTriggerData.sComparison);
	else
		return TriggerData.resolveComparison(rEventData.nDamage, rTriggerData.nCompareAgainst, rTriggerData.sComparison);
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

	local nWounds;
	if sType == "pc" then
		nWounds = DB.getValue(nodeActor, "hp.wounds", 0);
	else
		nWounds = DB.getValue(nodeActor, "wounds", 0);
	end
	return nWounds;
end

function ensureRemainingHitpoints(rTriggerData, rEventData)
	-- TODO why not just decrease wounds?
	--	because nWounds is set early in applyDamage
	local nCurrent = rEventData.nHitpoints + rEventData.nTemporaryHitpoints - rEventData.nWounds;
	rEventData.nAdjust = math.min(0, nCurrent - rTriggerData.nMinimum - rEventData.nDamage);

	if rEventData.nAdjust ~= 0 then
		table.insert(rEventData.rTarget.rDamageOutput.tNotifications, rTriggerData.sMessage);
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
		table.insert(rEventData.rTarget.rDamageOutput.tNotifications, rTriggerData.sMessage);
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
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
rTargetHasTemporaryHitPointsCondition = nil;
rDamageValueCondition = nil;

rEnsureRemainingHitpointsAction = nil;

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

	rTargetHasTemporaryHitPointsCondition  = {
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
	TriggerManager.defineCondition(rTargetHasTemporaryHitPointsCondition);
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

	mathMaxOriginal = math.max;
	math.max = mathMax;
	stringFormatOriginal = string.format;
	string.format = stringFormat;

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
		return nil;
	end

	local nTotal = getTotalHitPoints(rActor, sType, nodeActor);
	local nWounds = getWounds(rActor, sType, nodeActor);
	return nTotal - nWounds;
end

function getTemporaryHitPoints(rActor)
	local sType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return nil;
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
		return nil;
	end

	local nWounds = getWounds(rActor);
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
		return nil;
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

function checkDamageValueCompareAgainstVisibility(rConditionData)
	return rConditionData.sCompareTo == "number_parameter";
end
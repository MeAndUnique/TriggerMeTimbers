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
	aParameters = {"rSource", "rTarget", "nDamage", "nWounds", "nHitpoints"}
};

rTargetHasCurrentHitPointsCondition = nil;
 -- TODO relocate
rIsSourceCondition = nil;
rIsTargetCondition = nil;

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

	-- TODO finish defining.
	TriggerManager.defineEvent({sName="Damage"});
	TriggerManager.defineEvent(rBeforeDamageTakenEvent);

	initializeConditions();
	intializeActions();

	TriggerManager.defineCondition({
		aEvents = {"Damage"},
		fCondition = targetHadInitialHitpoints,
		sName = "Target Had Initial Hit Points"
	});

	-- TODO remove debug code
	TriggerManager.defineAction({
		fAction = messageSuccess,
		sName = "Message Success"
	})
	Interface.onDesktopInit = onDesktopInit;
end

function onDesktopInit()
	-- TODO remove debug code
	TriggerManager.registerTrigger({
		tEvents={
			[rBeforeDamageTakenEvent.sName]={
				aConditions={
					{
						sName = rTargetHasCurrentHitPointsCondition.sName,
						rData = {sComparison="gt", nCompareAgainst=0},
					},
					{
						sName = EffectManagerTMT.rTargetHasEffectCondition.sName,
						rData = {sEffectName = "Death Ward"},
					}
				}
			}
		},
		aActions={
			{
				sName = rEnsureRemainingHitpointsAction.sName,
				rData = {nMinimum = 1, sMessage = "[DEATH WARD]"}
			},
			{
				sName = EffectManagerTMT.rRemoveTargetEffectAction.sName,
				rData = {sEffectName = "Death Ward"}
			},
		}
	});
end

function initializeConditions()
	rTargetHasCurrentHitPointsCondition = {
		sName = "target_has_current_hit_points_condition",
		fCondition = targetHasCurrentHitpoints,
		aRequiredParameters = {"rTarget"}
	};

	TriggerManager.defineCondition(rTargetHasCurrentHitPointsCondition);
end

function intializeActions()
	rEnsureRemainingHitpointsAction = {
		sName = "ensure_target_has_remaining_hit_points_action",
		fAction = ensureRemainingHitpoints,
		aRequiredParameters = {"nDamage", "nWounds", "nHitpoints"}
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

	Debug.chat("mathMax", rEventData)
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

function isDamageSource(rTriggerData, rEventData)
	return rTriggerData.sSourcePath == rEventData.rSource.sCreatureNode;
end

function isDamageTarget(rTriggerData, rEventData)
	return rEventData.rTarget and rTriggerData.sTargetPath == rEventData.rTarget.sCreatureNode;
end

function targetHasCurrentHitpoints(rTriggerData, rEventData)
	if rEventData.rTarget == nil then
		return false;
	end

	local nCurrent = getCurrentHitPoints(rEventData.rTarget);
	Debug.chat("targetHasCurrentHitpoints", rTriggerData, rEventData, nCurrent)
	return resolveComparison(nCurrent, rTriggerData.nCompareAgainst, rTriggerData.sComparison);
end

function resolveComparison(vLeft, vRight, sComparison)
	if sComparison == "not_equal_comparison" then
		return vLeft ~= vRight;
	elseif sComparison == "greater_than_comparison" then
		return vLeft > vRight;
	elseif sComparison == "greater_than_equal_comparison" then
		return vLeft >= vRight;
	elseif sComparison == "less_than_comparison" then
		return vLeft < vRight;
	elseif sComparison == "less_than_equal_comparison" then
		return vLeft <= vRight;
	else
		return vLeft == vRight;
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
	local nCurrent = rEventData.nHitpoints - rEventData.nWounds;
	local nInitialDamage = rEventData.nDamage;
	rEventData.nDamage = math.max(rEventData.nDamage, rTriggerData.nMinimum - nCurrent);

	if nInitialDamage ~= rEventData.nDamage then
		table.insert(rDamageOutput.tNotifications, rTriggerData.sMessage);
	end
end

function messageSuccess(rTriggerData, rEventData)
	Debug.chat("success");
	bStop = true;
	applyDamage(rEventData.rTarget, rEventData.rTarget, false, "Death Ward", -1)
end
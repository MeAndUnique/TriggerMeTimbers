--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

local onSaveOriginal;
local applySaveOriginal;

local rAfterSaveEvent = nil;

local rSaveResultCondition = nil;

local rRollSaveAction = nil;

function onInit()
	onSaveOriginal = ActionSave.onSave;
	ActionSave.onSave = onSave;
	ActionsManager.registerResultHandler("save", onSave);
	applySaveOriginal = ActionSave.applySave;
	ActionSave.applySave = applySave;

	initializeEvents();
	initializeConditions();
	initializeActions();
end

function initializeEvents()
	rAfterSaveEvent = {
		sDescription = "after_save_event_description",
		sName = "after_save_event",
		aParameters = { "rSource", "nTotal", "nTarget", "bAutoFail" },
	};

	TriggerManager.defineEvent(rAfterSaveEvent);
end

function initializeConditions()
	rSaveResultCondition = {
		sName = "save_result_condition",
		fCondition = saveMatchesResultCondition,
		aRequiredParameters = {
			"nTotal",
			"nTarget",
			"bAutoFail",
		},
		aConfigurableParameters = {
			{
				sName = "sAttackResult",
				sDisplay = "attack_result_property_parameter",
				sType = "combo",
				aDefinedValues = {
					"save_result_property_pass",
					"save_result_property_fail",
				}
			}
		}
	};

	TriggerManager.defineCondition(rSaveResultCondition);
end

function initializeActions()
	rRollSaveAction = {
		sName = "roll_save_action",
		fAction = prepareRollSave,
		aRequiredParameters = { "bInterruptable" },
		rCreatedEvent = rAfterSaveEvent,
		fDecodeEventOOB = decodeSaveOOB,
		aConfigurableParameters = {
			TriggerData.rCombatantParameter,
			TriggerData.rAbilityParameter,
			{
				sName = "sTargetType",
				sDisplay = "save_target_type_parameter",
				sType = "combo",
				aDefinedValues = {
					"number_parameter",
					{
						sValue = "half_damage_parameter",
						aRequiredParameters = {"nDamage"},
					}
				},
			},
			{
				sName = "nTarget",
				sDisplay = "save_target_parameter",
				sType = "number",
				fCheckVisibility = checkSaveTargetVisibility
			}
		},
	};

	TriggerManager.defineAction(rRollSaveAction);
end

function onSave(rSource, rTarget, rRoll)
	-- Autofailures are not sent to applySave by the ruleset and so interruptions must be ended here in that event.
	local sInterruptionKey;
	local bAutoFail = rRoll.sDesc:match("%[AUTOFAIL%]");
	if bAutoFail or not rRoll.nTarget then
		sInterruptionKey = rRoll.sSaveDesc:match("%[INTERRUPTION: ([^%]]+)");
	end

	onSaveOriginal(rSource, rTarget, rRoll);

	local rEventData = {
		rSource = rSource,
		bAutoFail = bAutoFail,
		nTotal = ActionsManager.total(rRoll),
		nTarget = rRoll.nTarget
	};
	TriggerManager.fireEvent(rAfterSaveEvent.sName, rEventData);
	if sInterruptionKey then
		TriggerManager.notifyEndTriggerInterruption(sInterruptionKey, encodeSaveOOB(rEventData));
	end
end

function applySave(rSource, rOrigin, rAction, sUser)
	-- TODO handle the fact that autofail saves never reach here
	local sInterruptionKey = rAction.sSaveDesc:match("%[INTERRUPTION: ([^%]]+)");
	if sInterruptionKey then
		rAction.sSaveDesc:gsub("%[INTERRUPTION: [%]]+%]", "");
	end

	applySaveOriginal(rSource, rOrigin, rAction, sUser);

	local rEventData = {
		rSource = rSource,
		nTotal = rAction.nTotal,
		nTarget = rAction.nTarget
	};
	TriggerManager.fireEvent(rAfterSaveEvent.sName, rEventData);
	if sInterruptionKey then
		TriggerManager.notifyEndTriggerInterruption(sInterruptionKey, encodeSaveOOB(rEventData));
	end
end

function saveMatchesResultCondition(rTriggerData, rEventData)
	local bResult = false;
	if rTriggerData.sAttackResult == "save_result_property_pass" then
		bResult = (not rEventData.bAutoFail) and rEventData.nTarget and (rEventData.nTarget <= rEventData.nTotal);
	else
		bResult = rEventData.bAutoFail or rEventData.nTarget and (rEventData.nTarget > rEventData.nTotal);
	end

	return bResult;
end

function prepareRollSave(rTriggerData, _)
	local rInterruption = {
		rData = rTriggerData,
		fAction = rollSave,
		bIsInterruption = true,
	};
	return rInterruption;
end

function rollSave(sInterruptionKey, rInterruptionData, rEventData)
	local rActor;
	if rInterruptionData.sCombatant == "source_subject" then
		rActor = rEventData.rSource;
	elseif rInterruptionData.sCombatant == "target_subject" then
		rActor = rEventData.rTarget;
	end

	local nTarget;
	if rInterruptionData.sTargetType == "number" then
		nTarget = rInterruptionData.nTarget;
	elseif rInterruptionData.sTargetType == "half_damage_parameter" then
		nTarget = math.floor(math.max(10, rEventData.nDamage / 2));
	end

	ActionSave.performVsRoll(nil, rActor, rInterruptionData.sAbility, nTarget, false, nil, false, "[INTERRUPTION: " .. sInterruptionKey .. "]");
end

function encodeSaveOOB(rEventData)
	local msgOOB = {
		sSourceNode =  ActorManager.getCreatureNodeName(rEventData.rSource),
		nTotal = rEventData.nTotal,
		nTarget = rEventData.nTarget,
	};
	if rEventData.bAutoFail then
		msgOOB.nAutoFail = 1;
	end
	return msgOOB;
end

function decodeSaveOOB(msgOOB)
	local rEventData = {
		rSource = ActorManager.resolveActor(msgOOB.sSourceNode),
		nTotal = tonumber(msgOOB.nTotal),
		nTarget = tonumber(msgOOB.nTarget),
		bAutoFail = (tonumber(msgOOB.nAutoFail) or 0) == 1,
	};
	return rEventData;
end

function checkSaveTargetVisibility(rConditionData)
	return rConditionData.sTargetType == "number_parameter";
end
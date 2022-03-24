-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

-- A Trigger consists of one or more Events and one or more Actions.
	-- When any of the events fire all of the Actions will be executed.
-- An Event consists of zero or more Conditions.
	-- All of an event's Conditions must be met in order for the event to fire.

local nId = 0;
local tEventDefinitions = {};
local tConditionDefinitions = {};
local tActionDefinitions = {};
local tRegisteredEventTriggers = {};

function onInit()
	initializeConditions();
end

function initializeConditions()
	rIsSourceCondition = {
		sName = "is_source_condition",
		fCondition = isDamageSource,
		aRequiredParameters = {"rSource"}
	};
	rIsTargetCondition = {
		sName = "is_target_condition",
		fCondition = isDamageTarget,
		aRequiredParameters = {"rTarget"}
	};
	
	TriggerManager.defineCondition(rIsSourceCondition);
	TriggerManager.defineCondition(rIsTargetCondition);
end

function defineEvent(rEvent)
	tEventDefinitions[rEvent.sName] = rEvent;
end

function getEventDefinitions()
	return tEventDefinitions;
end

function defineCondition(rCondition)
	tConditionDefinitions[rCondition.sName] = rCondition;
end

function getConditionDefinitonsForEvent(rEvent)
	local aConditions = {}
	for _,rConditionDefinition in pairs(rConditionDefinitions) do
		local bHasRequirements = true;
		for _,sParameterName in ipairs(rEvent.aParameters) do
			if not StringManager.contains(rConditionDefinition.aRequiredParameters, sParameterName) then
				bHasRequirements = false;
				break;
			end
		end
		if bHasRequirements then
			table.insert(aConditions, rConditionDefinition);
		end
	end
	return aConditions;
end

function defineAction(rAction)
	tActionDefinitions[rAction.sName] = rAction;
end

function getActionDefinitions()
	return tActionDefinitions;
end

-- TODO remove in favor of using DB nodes
function getNewTriggerId()
	nId = nId + 1;
	return nId;
end

function registerTrigger(rTrigger)
	Debug.chat("registerTrigger", rTrigger);
	local nTriggerId = getNewTriggerId();
	for sEventName,rEvent in pairs(rTrigger.tEvents) do
		Debug.chat("registerTrigger - loop", rEvent);
		local tEventTriggers = tRegisteredEventTriggers[sEventName];
		if not tEventTriggers then
			tEventTriggers = {};
			tRegisteredEventTriggers[sEventName] = tEventTriggers;
		end

		tEventTriggers[nTriggerId] = rTrigger;
	end
	return nTriggerId;
end

function fireEvent(sEventName, rEventData)
	Debug.chat("fireEvent", sEventName, rEventData, tRegisteredEventTriggers);
	local tEventTriggers = tRegisteredEventTriggers[sEventName];
	if tEventTriggers then
		for _,rTrigger in pairs(tEventTriggers) do
			Debug.chat("fireEvent - trigger", rTrigger, rTrigger.tEvents[sEventName].aConditions);
			local bConditionsMet = true;
			for _,rCondition in ipairs(rTrigger.tEvents[sEventName].aConditions) do
				Debug.chat("fireEvent - condition", rCondition);
				local rConditionDefinition = tConditionDefinitions[rCondition.sName];
				if not (rConditionDefinition and rConditionDefinition.fCondition(rCondition.rData, rEventData)) then
					Debug.chat("conditions not met")
					bConditionsMet = false;
					break;
				end
			end
			if not bConditionsMet then
				break;
			end
			
			for _,rAction in ipairs(rTrigger.aActions) do
				local rActionDefinition = tActionDefinitions[rAction.sName];
				if rActionDefinition then
					rActionDefinition.fAction(rAction.rData, rEventData);
				end
			end
		end
	end
end

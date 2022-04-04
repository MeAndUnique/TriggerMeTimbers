-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

-- A Trigger consists of one or more Events and one or more Actions.
	-- When any of the events fire all of the Actions will be executed.
-- An Event consists of zero or more Conditions.
	-- All of an event's Conditions must be met in order for the event to fire.

local tEventDefinitions = {};
local tConditionDefinitions = {};
local tActionDefinitions = {};
local tRegisteredEventTriggers = {};

function defineEvent(rEvent)
	tEventDefinitions[rEvent.sName] = rEvent;
end

function getEventDefinition(sEventName)
	return tEventDefinitions[sEventName];
end

function getEventDefinitions()
	return tEventDefinitions;
end

function getParametersForEvent(vEvent)
	local rEvent = vEvent;
	if type(vEvent) == "string" then
		rEvent = tEventDefinitions[vEvent];
	end
	return rEvent.aParameters;
end

function getCommonParametersForEvents(aEvents)
	local tParameterCounts = {};
	local nEventCount = 0;
	for _,vEvent in ipairs(aEvents) do
		nEventCount = nEventCount + 1;
		local aParameters = getParametersForEvent(vEvent);
		for _,sParameter in ipairs(aParameters) do
			tParameterCounts[sParameter] = (tParameterCounts[sParameter] or 0) + 1;
		end
	end

	local aParameters = {}
	for sParameter,nCount in pairs(tParameterCounts) do
		if nCount == nEventCount then
			table.insert(aParameters, sParameter);
		end
	end
	return aParameters;
end

function defineCondition(rCondition)
	tConditionDefinitions[rCondition.sName] = rCondition;
end

function getConditionDefinition(sConditionName)
	return tConditionDefinitions[sConditionName];
end

function getConditionDefinitions()
	return tConditionDefinitions;
end

function getConditionDefinitionsForEvent(vEvent)
	return getConditionDefinitionsForCommonEventParameters(getParametersForEvent(vEvent));
end

function getConditionDefinitionsForEventParameters(aEventParameters)
	local aConditions = {}
	for _,rConditionDefinition in pairs(tConditionDefinitions) do
		if hasRequiredParameters(rConditionDefinition.aRequiredParameters, aEventParameters) then
			table.insert(aConditions, rConditionDefinition);
		end
	end
	return aConditions;
end

function defineAction(rAction)
	tActionDefinitions[rAction.sName] = rAction;
end

function getActionDefinition(sActionName)
	return tActionDefinitions[sActionName];
end

function getActionDefinitions()
	return tActionDefinitions;
end

function getActionDefinitionsForEvents(aEvents)
	return getActionDefinitionsForCommonEventParameters(getCommonParametersForEvents(aEvents));
end

function getActionDefinitionsForEvent(vEvent)
	return getActionDefinitionsForCommonEventParameters(getParametersForEvent(vEvent));
end

function getActionDefinitionsForCommonEventParameters(aEventParameters)
	local aActions = {}
	for _,rActionDefinition in pairs(tActionDefinitions) do
		if hasRequiredParameters(rActionDefinition.aRequiredParameters, aEventParameters) then
			table.insert(aActions, rActionDefinition);
		end
	end
	return aActions;
end

function hasRequiredParameters(aRequiredParameters, aEventParameters)
	local bHasRequirements = true;
	for _,sParameterName in ipairs(aRequiredParameters or {}) do
		if not StringManager.contains(aEventParameters, sParameterName) then
			bHasRequirements = false;
			break;
		end
	end
	return bHasRequirements;
end	

function registerTrigger(nodeTrigger)
	local nTriggerId = getNewTriggerId();
	for sEventName,rEvent in pairs(rTrigger.tEvents) do
		local tEventTriggers = tRegisteredEventTriggers[sEventName];
		if not tEventTriggers then
			tEventTriggers = {};
			tRegisteredEventTriggers[sEventName] = tEventTriggers;
		end

		tEventTriggers[nTriggerId] = rTrigger;
	end
	return nTriggerId;
end

function loadTriggerFromNode(nodeTrigger)
	local rTrigger = {
		tEvents = {},
		tActions = {}
	};
	for _,nodeEvent in pairs(DB.getChildren(nodeTrigger, "events")) do
		local rEvent = loadTriggerEventFromNode(nodeEvent);
		rTrigger.tEvents[rEvent.sName] = rEvent;
	end
	for _,nodeAction in pairs(DB.getChildren(nodeTrigger, "actions")) do
		local rAction = loadTriggerActionFromNode(nodeEvent);
		rTrigger.tActions[rAction.sName] = rAction;
	end
	return rTrigger;
end

function loadTriggerEventFromNode(nodeEvent)
	local rEvent = {
		sName = DB.getValue(nodeEvent, "eventname", "");
		aConditions = {}
	};
	for _,nodeCondition in pairs(DB.getChildren(nodeEvent, "conditions")) do
		local rCondition = loadTriggerConditionFromNode(nodeCondition);
		table.insert(rEvent.aCondition, rCondition);
	end
	return rEvent;
end

function loadTriggerConditionFromNode(nodeCondition)
	-- TODO invertibility
	local rCondition = {
		sName = DB.getValue(nodeCondition, "conditionname", "");
		rData = loadParameters(nodeCondition)
	};
	return rCondition;
end

function loadParameters(nodeContainer)
	local tParameters = {};
	for _,nodeParameter in pairs(DB.getChildren(nodeContainer, "parameters")) do
		tParameters[nodeParameter.getName()] = nodeParameter.getValue();
	end
	return tParameters;
end

function loadTriggerActionFromNode(nodeCondition)
end

--TODO break this down if possible
function fireEvent(sEventName, rEventData)
	local tEventTriggers = tRegisteredEventTriggers[sEventName];
	if tEventTriggers then
		for _,rTrigger in pairs(tEventTriggers) do
			local bConditionsMet = true;
			for _,rCondition in ipairs(rTrigger.tEvents[sEventName].aConditions) do
				local rConditionDefinition = tConditionDefinitions[rCondition.sName];
				if not (rConditionDefinition and rConditionDefinition.fCondition(rCondition.rData, rEventData)) then
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

--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

local fActivatePowerOriginal;
function onInit()
	fActivatePowerOriginal = super.activatePower;
	super.activatePower = activatePower;

	if super and super.onInit then
		super.onInit()
	end
end

function activatePower()
	fActivatePowerOriginal();
	local node = getDatabaseNode();

	local charnode = node.getChild("...");
	local rActor = ActorManager.resolveActor(charnode);

	local sName = DB.getValue(node, "name", "");
	local sRange = DB.getValue(node, "range", "");
	local sRecharge = DB.getValue(node, "recharge", "");
	local sAction = DB.getValue(node, "action", "");
	local sKeywords = DB.getValue(node, "keywords", "");

	local rPower = { 
		sName = sName, 
		sRange = sRange,
		sRecharge = sRecharge,
		sAction = sAction,
		sKeywords = sKeywords
	};
	local rEventData = {
		rSource = rActor,
		rPower = rPower
	};

	TriggerManager.fireEvent(
		CharPowerTMT_4E.rPowerUsedEvent.sName,
		rEventData);
end
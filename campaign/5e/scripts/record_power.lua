--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

local fUsePowerOriginal;

function onInit()
	fUsePowerOriginal = super.usePower;
	super.usePower = usePower;

	if super and super.onInit then
		super.onInit();
	end
end

function usePower(bShowFull)
	fUsePowerOriginal(bShowFull);

	local node = getDatabaseNode();

	local charnode = node.getChild("...");
	local rActor = ActorManager.resolveActor(charnode);

	local sName = DB.getValue(node, "name", "");
	local nLevel = DB.getValue(node, "level", 0);
	local sSchool = DB.getValue(node, "school", "");
	local sCastingTime = DB.getValue(node, "castingtime", "");
	local sComponents = DB.getValue(node, "components", "");
	local sDuration = DB.getValue(node, "duration", "");
	local sGroup = DB.getValue(node, "group", "");
	local sRange = DB.getValue(node, "range", "");

	local rPower = {
		sName = sName,
		nLevel = nLevel,
		sSchool = sSchool,
		sCastingTime = sCastingTime,
		sComponents = sComponents,
		sDuration = sDuration,
		sGroup = sGroup,
		sRange = sRange
	};
	local rEventData = {
		rSource = rActor,
		rPower = rPower
	};

	TriggerManager.fireEvent(
		CharDamageTMT_5E.rPowerUsedEvent.sName,
		rEventData);
end
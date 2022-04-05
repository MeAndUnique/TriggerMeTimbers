-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local handleDropOriginal;

function onInit()
	handleDropOriginal = CampaignDataManager.handleDrop;
	CampaignDataManager.handleDrop = handleDrop;
end

function handleDrop(sTarget, draginfo)
	if (sTarget == "activetrigger") or (sTarget == "trigger") then
		local bAllowEdit = LibraryData.allowEdit(sTarget);
		if bAllowEdit then
			local sRootMapping = LibraryData.getRootMapping(sTarget);
			local sClass, sRecord = draginfo.getShortcutData();
			if (sClass == "trigger") and (not StringManager.startsWith(sRecord, sTarget)) and ((sRootMapping or "") ~= "") then
				local nodeSource = DB.findNode(sRecord);
				local nodeTarget = DB.createChild(sRootMapping);
				DB.copyNode(nodeSource, nodeTarget);
				DB.setValue(nodeTarget, "locked", "number", 1);
				DB.setCategory(nodeTarget, UtilityManager.getNodeCategory(nodeSource));
				return true;
			end
		end
	end

	return handleDropOriginal(sTarget, draginfo);
end
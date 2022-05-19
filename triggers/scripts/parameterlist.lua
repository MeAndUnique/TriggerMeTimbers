--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local rParameterData = {};

function onInit()
	onFilter = onFilterParameters;
	onSortCompare = onSortParameters;

	-- TODO respond to node changes for window stuff?
end

function onFilterParameters(winParameter)
	return winParameter.shouldBeVisible(rParameterData);
end

function onSortParameters(winLeft, winRight)
	return winLeft.getDatabaseNode().getPath() > winRight.getDatabaseNode().getPath();
end

function update(bReadOnly)
	for _,winParameter in ipairs(getWindows()) do
		winParameter.update(bReadOnly);
	end
end

function initializeParameters(aConfigurableParameters, aEventParameters, bRebuild)
	local windowNode = window.getDatabaseNode();
	if bRebuild or not windowNode.getChild("parameters") then
		rebuildParameterNodes(windowNode, aConfigurableParameters);
	end

	closeAll();
	local nodeParameters = windowNode.getChild("parameters");
	for nIndex,rParameterInfo in ipairs(aConfigurableParameters) do
		nodeParameter = nodeParameters.getChild(string.format("id-%05d", nIndex));
		local winParameter = createWindowWithClass("trigger_parameter_" .. rParameterInfo.sType, nodeParameter);
		winParameter.configure(rParameterInfo, aEventParameters);
	end

	onParameterChanged();
end

function rebuildParameterNodes(windowNode, aConfigurableParameters)
	DB.deleteChild(windowNode, "parameters");
	local nodeParameters = DB.createChild(windowNode, "parameters");
	for _,rParameterInfo in ipairs(aConfigurableParameters or {}) do
		local nodeParameter = nodeParameters.createChild();
		DB.setValue(nodeParameter, "name", "string", rParameterInfo.sName);
		DB.setValue(nodeParameter, "type", "string", rParameterInfo.sType);
	end
end

function onParameterChanged()
	-- TODO include specific data to avoid reprocessing everything?
	for _,winParameter in pairs(getWindows()) do
		local sParameterName, vValue = winParameter.getNameAndValue();
		rParameterData[sParameterName] = vValue;
	end
	applyFilter();
end
--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local showListOriginal;
local setListValueOriginal;

local tTooltips = {};

function onInit()
	showListOriginal = super.showList;
	super.showList = showList;
	setListValueOriginal = super.setListValue;
	super.setListValue = setListValue;

	super.onInit();
end

function showList()
	local bShouldUpdateAll = getListControl() == nil;
	showListOriginal();

	if bShouldUpdateAll then
		setItemTooltip(getListControl());
	end
end

function setListValue(sValue)
	setListValueOriginal(sValue);
	local sTooltip = tTooltips[getSelectedValue()];
	if (sTooltip or "") ~= "" then
		setTooltipText(sTooltip);
	end
end

function addTooltip(sValue, sTooltip)
	if (sTooltip or "") == "" then
		return;
	end

	tTooltips[sValue] = sTooltip;
	local listControl = getListControl();
	setItemTooltip(listControl, sValue, sTooltip);
end

function getListControl()
	local sName = getName() or "";
	local sList = sName .. "_cblist";
	return window[sList];
end

function setItemTooltip(listControl, sValue, sTooltip)
	if not listControl then
		return;
	end

	for _,winItem in ipairs(listControl.getWindows()) do
		if sValue then
			if sValue == winItem.Value.getValue() then
				winItem.Text.setTooltipText(sTooltip);
			end
		else
			sTooltip = tTooltips[winItem.Value.getValue()];
			if sTooltip then
				winItem.Text.setTooltipText(sTooltip);
			end
		end
	end
end
--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local m_vNode = nil;
local m_sRecordType = "";

function onInit()
	m_vNode = getDatabaseNode();
	if not m_vNode then
		return;
	end

	m_vNode.onCategoryChange = onCategoryChange;
	onCategoryChange(m_vNode);
end

function setRecordType(sNewRecordType)
	if m_sRecordType == sNewRecordType then
		return;
	end

	m_sRecordType = sNewRecordType

	local sRecordDisplayClass = LibraryData.getRecordDisplayClass(m_sRecordType, m_vNode);
	local sPath = "";
	if m_vNode then
		sPath = m_vNode.getPath();
	end
	link.setValue(sRecordDisplayClass, sPath);

	local sEmptyNameText = LibraryData.getEmptyNameText(m_sRecordType);
	name.setEmptyText(sEmptyNameText);
end

function onCategoryChange()
	local vCategory = m_vNode.getCategory();
	if type(vCategory) ~= "string" then
		vCategory = vCategory.name;
	end
	category.setValue(vCategory);
	category.setTooltipText(vCategory);
end
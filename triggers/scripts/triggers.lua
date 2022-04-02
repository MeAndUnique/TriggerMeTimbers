-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sInternalRecordType = "trigger";

local _tRecords = {};
local _nFilteredRecordCount = 0;
local _nDisplayOffset = 0;
local _nSavedScrollPos = nil;

local bDelayedChildrenChanged = false;
local bDelayedRebuild = false;

local sFilter = "";

function onInit()
	rebuildList();
	addHandlers();

	Module.onModuleLoad = onModuleLoadAndUnload;
	Module.onModuleUnload = onModuleLoadAndUnload;
end
function onClose()
	removeHandlers();
end

function onSortCompare(w1, w2)
	return not ListManager.defaultSortFunc(_tRecords[w1.getDatabaseNode()], _tRecords[w2.getDatabaseNode()]);
end

function onModuleLoadAndUnload(sModule)
	local nodeRoot = DB.getRoot(sModule);
	if nodeRoot then
		local vNodes = LibraryData.getMappings(sInternalRecordType);
		for i = 1, #vNodes do
			if nodeRoot.getChild(vNodes[i]) then
				bDelayedRebuild = true;
				onListRecordsChanged(true);
				break;
			end
		end
	end
end
function addHandlers()
	function addHandlerHelper(vNode)
		local sPath = DB.getPath(vNode);
		local sChildPath = sPath .. ".*@*";
		DB.addHandler(sChildPath, "onAdd", onChildAdded);
		DB.addHandler(sChildPath, "onDelete", onChildDeleted);
		DB.addHandler(DB.getPath(sChildPath, "name"), "onUpdate", onChildNameChange);
		DB.addHandler(DB.getPath(sChildPath, "isgmonly"), "onUpdate", onChildGMOnlyChange);
		DB.addHandler(sPath, "onChildCategoriesChange", onChildCategoriesChanged);
	end
	
	local vNodes = LibraryData.getMappings(sInternalRecordType);
	for i = 1, #vNodes do
		addHandlerHelper(vNodes[i]);
	end
end
function removeHandlers()
	function removeHandlerHelper(vNode)
		local sPath = DB.getPath(vNode);
		local sChildPath = sPath .. ".*@*";
		DB.removeHandler(sChildPath, "onAdd", onChildAdded);
		DB.removeHandler(sChildPath, "onDelete", onChildDeleted);
		DB.removeHandler(DB.getPath(sChildPath, "name"), "onUpdate", onChildNameChange);
		DB.removeHandler(DB.getPath(sChildPath, "isgmonly"), "onUpdate", onChildGMOnlyChange);
		DB.removeHandler(sPath, "onChildCategoriesChange", onChildCategoriesChanged);
	end
	
	local vNodes = LibraryData.getMappings(sInternalRecordType);
	for i = 1, #vNodes do
		removeHandlerHelper(vNodes[i]);
	end
end

function onChildAdded(vNode)
	addListRecord(vNode);
	onListRecordsChanged(true);
end
function onChildDeleted(vNode)
	if _tRecords[vNode] then
		_tRecords[vNode] = nil;
		onListRecordsChanged(true);
	end
end
function onListChanged()
	if bDelayedChildrenChanged then
		onListRecordsChanged(false);
	else
		list.update();
	end
end
function addListRecord(vNode)
	local rRecord = {};
	rRecord.vNode = vNode;
	rRecord.sDisplayName = DB.getValue(vNode, "name", "");
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
	rRecord.nGMOnly = DB.getValue(vNode, "isgmonly", 0);

	_tRecords[vNode] = rRecord;
end
function onChildCategoriesChanged()
	onListRecordsChanged(true);
end
function onListRecordsChanged(bAllowDelay)
	if bAllowDelay then
		bDelayedChildrenChanged = true;
		saveDisplayListScrollPosition();
		list.setDatabaseNode(nil);
	else
		bDelayedChildrenChanged = false;
		if bDelayedRebuild then
			bDelayedRebuild = false;
			rebuildList();
		end
		refreshDisplayList();
	end
end
function rebuildList()
	_tRecords = {};
	local aMappings = LibraryData.getMappings(sInternalRecordType);
	for _,vMapping in ipairs(aMappings) do
		for _,vNode in pairs(DB.getChildrenGlobal(vMapping)) do
			addListRecord(vNode);
		end
	end

	_nDisplayOffset = 0;
	onListRecordsChanged();
end

function handleCategorySelect(sCategory)
	if not bAllowCategories then
		return;
	end
	
	filter_category.setValue(sCategory);
	fCategory = sCategory;

	if fCategory == "*" then
		filter_category_label.setValue(Interface.getString("masterindex_label_category_all"));
	elseif fCategory == "" then
		filter_category_label.setValue(Interface.getString("masterindex_label_category_empty"));
	else
		filter_category_label.setValue(fCategory);
	end
	
	for _,w in ipairs(list_category.getWindows()) do
		w.setActiveByKey(fCategory);
	end
	
	button_category_detail.setValue(0);
	
	local sDefaultCategory = sCategory;
	if sDefaultCategory == "*" then
		sDefaultCategory = "";
	end
	for _,vMapping in ipairs(LibraryData.getMappings(sInternalRecordType)) do
		DB.setDefaultChildCategory(vMapping, sDefaultCategory);
	end

	setDisplayOffset(0);
	refreshDisplayList(true);
end
function handleCategoryNameChange(sOriginal, sNew)
	if sOriginal == sNew then
		return;
	end
	for _,vMapping in ipairs(LibraryData.getMappings(sInternalRecordType)) do
		DB.updateChildCategory(vMapping, sOriginal, sNew, true);
	end
end
function handleCategoryDelete(sName)
	for _,vMapping in ipairs(LibraryData.getMappings(sInternalRecordType)) do
		DB.removeChildCategory(vMapping, sName, true);
	end
end
function handleCategoryAdd()
	local aMappings = LibraryData.getMappings(sInternalRecordType);
	sDelayedCategoryFocus = DB.addChildCategory(aMappings[1]);
end
function rebuildCategories()
	if not bAllowCategories then
		return;
	end
	
	local aCategories = {};
	for _,vMapping in ipairs(LibraryData.getMappings(sInternalRecordType)) do
		for _,vCategory in ipairs(DB.getChildCategories(vMapping, true)) do
			if type(vCategory) == "string" then
				aCategories[vCategory] = vCategory;
			else
				aCategories[vCategory.name] = vCategory.name;
			end
		end
	end
	aCategories["*"] = Interface.getString("masterindex_label_category_all");
	aCategories[""] = Interface.getString("masterindex_label_category_empty");

	list_category.closeAll();
	for kCategory,vCategory in pairs(aCategories) do
		local w = list_category.createWindow();
		w.setData(kCategory, vCategory, (fCategory == kCategory));
	end
	list_category.applySort();
	
	if not aCategories[fCategory] then
		handleCategorySelect("*");
	end
	
	if button_category_iedit.getValue() == 1 then
		button_category_iedit.setValue(0);
		button_category_iedit.setValue(1);
	end

	if sDelayedCategoryFocus then
		for _,w in ipairs(list_category.getWindows()) do
			if w.getCategory() == sDelayedCategoryFocus then
				w.category_label.setFocus();
				break;
			end
		end
		sDelayedCategoryFocus = nil;
	end
end

function onFilterChanged()
	sFilter = filter.getValue():lower();
	refreshDisplayList(true);
end
function onChildNameChange(vNameNode)
	local vNode = vNameNode.getParent();
	local rRecord = _tRecords[vNode];
	rRecord.sDisplayName = DB.getValue(vNode, "name", "");
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
	refreshDisplayList();
end
function onChildGMOnlyChange(vNameNode)
	local vNode = vNameNode.getParent();
	local rRecord = _tRecords[vNode];
	rRecord.nGMOnly = DB.getValue(vNode, "isgmonly", 0);
	refreshDisplayList();
end

function refreshDisplayList(bResetScroll)
	saveDisplayListScrollPosition(bResetScroll);
	ListManager.refreshDisplayList(self);
	restoreDisplayListScrollPosition();
end
function addDisplayListItem(v)
	list.createWindow(v.vNode);
end
function saveDisplayListScrollPosition(bResetScroll)
	if bResetScroll then
		_nSavedScrollPos = nil;
	elseif not _nSavedScrollPos then
		_,_,_,_,_nSavedScrollPos,_ = list.getScrollState();
	end
end
function restoreDisplayListScrollPosition()
	if _nSavedScrollPos then
		list.setScrollPosition(0, _nSavedScrollPos);
		_nSavedScrollPos = nil;
	end
end

function getAllRecords()
	return _tRecords;
end
function getDisplayOffset()
	return _nDisplayOffset;
end
function setDisplayOffset(n)
	_nDisplayOffset = n;
	refreshDisplayList(true);
end
function getDisplayRecordCount()
	return _nFilteredRecordCount;
end
function setDisplayRecordCount(n)
	_nFilteredRecordCount = n;
end

function isFilteredRecord(v)
	if sFilter ~= "" then
		if not string.find(v.sDisplayNameLower, sFilter, 0, true) then
			return false;
		end
	end
	if v.nGMOnly == 1 and not Session.IsHost then
		return false;
	end
	return true;
end

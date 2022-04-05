-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

aRecordOverrides = {
	-- New record types
	["trigger"] = {
		bExport = true,
		bExportListSkip = true,
		bHidden = false,
		aDataMap = { "trigger" },
	},
	["activetrigger"] = {
		aDataMap = { "activetrigger" },
		sListDisplayClass = "masterindexitem_activetrigger",
		sRecordDisplayClass = "trigger",
		bHidden = true,
	},
};

function onInit()
	LibraryData.overrideRecordTypes(aRecordOverrides);
end
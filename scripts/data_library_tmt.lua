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
};

function onInit()
	LibraryData.overrideRecordTypes(aRecordOverrides);
end
-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onLockChanged()
	if header.subwindow then
		header.subwindow.update();
	end
	if trigger_content.subwindow then
		trigger_content.subwindow.update();
	end
end
--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

function parseFunction(sInput)
	local bVariable = false;
	for char in sInput:gmatch(".") do
		-- statements
	end
end

function buildTwoParameterExpression(aNameParts, fLeft, fRight)
	local fNamedFunction = self;
	for _,sName in ipairs(aNameParts) do
		fNamedFunction = fNamedFunction[sName];
	end
	return function(rContext) return fNamedFunction(fLeft(rContext), fRight(rContext)) end;
end
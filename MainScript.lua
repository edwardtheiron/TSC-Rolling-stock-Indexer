--include=SectionsInspect.lua

function Initialise() -- core Simulator function

	PROBE_COUPLINGS = 1818190203
	VL10K_PROBE = 419201
    VL10K_RESPONSE = 419210
	VL10K_INDEX = 419211
    PrevLength = 0
    RVN = Call("GetRVNumber")

end

function Update(time) -- core Simulator function

    isDeadLoco = Call("GetIsDeadEngine") == 1
    if isDeadLoco then Print(RVN," is broken section") Call("SetRVNumber",RVN .. " - Broken") Call("EndUpdate") return end

    ConsistLen = Call("GetConsistLength")
	if ConsistLen ~= PrevLength then
		PrevLength = ConsistLen
		ProbeFront = Call("SendConsistMessage", PROBE_COUPLINGS, "blah", 0) == 1
		ProbeRear = Call("SendConsistMessage", PROBE_COUPLINGS, "blah", 1) == 1		
	end   

	Sections:Update(ProbeFront,ProbeRear)

end



function OnConsistMessage (msg, argument, direction) -- core Simulator function
	
    if msg == VL10K_PROBE or msg == VL10K_RESPONSE or msg == VL10K_INDEX then -- later will be split
		Sections:OCM (msg, argument, direction) -- receiving messages from other sections
    end

end

function OnControlValueChange(name, index, value) -- core Simulator function
    
    if name == "MainControlSwitch" then	
		if value == 0 then
			Call("SetControlValue","Number_sections",0,0) 
			Call("SetControlValue","Index",0,0)	
			Call("SendConsistMessage",VL10K_PROBE, "RESET", 1)
		elseif value == 1 then		
			TailResponse = { 
				[0] = {},
				[1] = {},
			}
			Timer("PlayerInit",0.2) 
			Sections:PlayerInit() -- init of inspection
        end 
    end 

end


function alert(text1,text2,length)	
	if length then
		SysCall("ScenarioManager:ShowAlertMessageExt", tostring(text1), tostring(text2), length, 0)
	elseif text2 then
		SysCall("ScenarioManager:ShowAlertMessageExt", tostring(text1), tostring(text2), 2, 0)
	else
		SysCall("ScenarioManager:ShowAlertMessageExt", tostring(""), tostring(text1), 2, 0)
	end
end


function string:split(delimiter)
    local result = { }
    local from  = 1
    local delim_from, delim_to = string.find( self, delimiter, from  )
    while delim_from do
      table.insert( result, string.sub( self, from , delim_from-1 ) )
      from  = delim_to + 1
      delim_from, delim_to = string.find( self, delimiter, from  )
    end
    table.insert( result, string.sub( self, from  ) )
    return result
end

function print(...) -- for some reaseon TSC uses Print with first letter capital. I wanted to use lowercase and advanced version, so here it is
	--local stime = os.date ("!%X", Call("GetSimulationTime")) -- you can add timestamp
	local result = Call("GetRVNumber") .. " "
	for i = 1, arg.n do
		result = result .. " " .. tostring ( arg[i] )
	end
 	Print(result)
end


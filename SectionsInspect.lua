Sections = {
	--TotalStatus = "none", -- must be "Head_Found" for all correct sections
	NumberOfSections = 0, -- 2,3,4 are only valid configurations. others are invalid
	--PrevNumberOfSections = 0,
	Index = 0,
	KUCount = 0,
	["#1:RearToRear#2:FrontToFront#3:RearToRear"] = 4,
	["#1:RearToFront#2:RearToRear"] = 3,
	["#1:RearToRear#2:FrontToRear"] = 3,
	["#1:RearToRear"] = 2,	
	
} -- main table that holds data (instead of controls) and methods


TailResponse = { -- table to store responses from all possible units in consist
	[0] = {},
	[1] = {},
}

-- 4 methods called from OnConsistMessage once message is received : 

function Sections:Probe (msg, argument, direction)  -- the first one that gathers general info

	if Call("GetControlValue","avt_ku",0) == 1 then 

		Call("SetControlValue","Number_sections",0,0)
		Call("SetControlValue","Index",0,0)		
		self.NumberOfSections = 0
		self.Index = 0				
		Call("SendConsistMessage",VL10K_KU_WAS_ON,"KU_WAS_ON",1)
		Call("SendConsistMessage",VL10K_KU_WAS_ON,"KU_WAS_ON",0)
		return 
	end				
	if string.find(argument,"RESET") then 
		Call("SetControlValue","Number_sections",0,0) 
		Call("SetControlValue","Index",0,0)	
		self.NumberOfSections = 0
		self.Index = 0
		Call("SendConsistMessage",msg, argument, direction) 
	end
				
	local param = string.split(argument,"#")	
	
	if param[4] then -- 4 sections
		local newArg = argument .. ( direction == 1 and ( "ToFront" ) or ( "ToRear" ) )
		if direction == 0 then
			Call("SendConsistMessage",VL10K_PROBE, newArg .. "#4:Front" , 0)
			Call("SendConsistMessage",VL10K_RESPONSE, newArg, 1)
		else
			Call("SendConsistMessage",VL10K_PROBE, newArg .. "#4:Rear" , 1)
			Call("SendConsistMessage",VL10K_RESPONSE, newArg, 0)
		end				
	
	elseif param[3] then -- 3 sections
		local newArg = argument .. ( direction == 1 and ( "ToFront" ) or ( "ToRear" ) )
		if direction == 0 then
			Call("SendConsistMessage",VL10K_PROBE, newArg .. "#3:Front" , 0)
			Call("SendConsistMessage",VL10K_RESPONSE, newArg, 1)
		else
			Call("SendConsistMessage",VL10K_PROBE, newArg .. "#3:Rear" , 1)
			Call("SendConsistMessage",VL10K_RESPONSE, newArg, 0)
		end			
	elseif param[2] then -- 2 sections
		local newArg = argument .. ( direction == 1 and ( "ToFront" ) or ( "ToRear" ) )
		if direction == 0 then
			Call("SendConsistMessage",VL10K_PROBE, newArg .. "#2:Front" , 0)
			Call("SendConsistMessage",VL10K_RESPONSE, newArg, 1)
		else
			Call("SendConsistMessage",VL10K_PROBE, newArg .. "#2:Rear" , 1)
			Call("SendConsistMessage",VL10K_RESPONSE, newArg, 0)
		end
	end	

end



function Sections:Response (msg, argument, direction) -- handles responses

	local param = string.split(argument,"#")
	if Call("GetControlValue","avt_ku",0) == 1 then
		TailResponse[direction][ ( table.getn(TailResponse[direction]) + 1 ) or 0 ] = argument
		--print(table.insert(TailResponse[direction], argument))
		-- table.insert
	else
		Call("SendConsistMessage",msg,argument,direction)
	end
end

function Sections:Indexer (msg, argument, direction) -- sends index info
	local t = string.split(argument,":")
	t[1], t[2] = tonumber(t[1]), tonumber(t[2])
	t[2] = t[2] + 1
	if t[1] == t[2] then
		Call("SetControlValue","Number_sections",0,t[1])
		Call("SetControlValue","Index",0,t[2])		
		self.NumberOfSections = t[1]
		self.Index = t[2]				
		Call("SendConsistMessage",VL10K_INDEX,"0:-1",direction)
		if t[1] > 0 then alert("Sections Numeration done","Number of Sections is " .. t[2] )	end		
	else				
		Call("SetControlValue","Number_sections",0,t[1])
		Call("SetControlValue","Index",0,t[2])
		self.NumberOfSections = t[1]
		self.Index = t[2]
		Call("SendConsistMessage",VL10K_INDEX,t[1] .. ":" ..t[2],direction)
	end
end

function Sections:KU (msg, argument, direction)  -- handles main switch error. when 2 or more switches are on 
	Call("SetControlValue","Number_sections",0,0)
	Call("SetControlValue","Index",0,0)		
	self.NumberOfSections = 0
	self.Index = 0			
	
	if Call("GetControlValue","avt_ku",0) == 1 then
		Sections.KUCount = Sections.KUCount + 1
	else				
		Call("SendConsistMessage",msg,argument,direction)
	end
end

-- "#2:RearToRear#3:FrontToFront#4:RearToRear
-- "#2:RearToFront#3:RearToRear
-- "#2:RearToRear#3:FrontToRear
-- "#2:RearToRear

-- called when KU becomes 1
function Sections:PlayerInit() -- starts after fliping main switch
	if PlayerInit then return end
	PlayerInit = true
	if ProbeFront then Call("SendConsistMessage",VL10K_PROBE,"#1:Front",0) end
	if ProbeRear then Call("SendConsistMessage",VL10K_PROBE,"#1:Rear",1) end
	
end

-- main method called to handle different stages of inspection
-- main logic works only when timer expires. the timer itself starts when player turns the main swith on
function Sections:Update(probeFront,probeRear)
	if Timer("PlayerInit") then
		Timer("PlayerInit","clear")
		PlayerInit = false

		if TailResponse[1][1] then alert("Error!","You can't start from middle section!") return end
		if self.KUCount > 0 then alert("Another KU was found on") return end
		
		
		local num = self[TailResponse[0][1]] or self[TailResponse[0][2]] or self[TailResponse[0][3]] or 0		

		if num ~= 0 then
			self.NumberOfSections = num
			self.Index = 1
			Call("SetControlValue","Number_sections",0,num)
			Call("SetControlValue","Index",0,1)
			Call("SendConsistMessage",VL10K_INDEX,num .. ":1",1)
		else
			alert("Error!","Wrong sections configuration")
		end
	end
	
end


-- function Sections:OnSave()

-- end

-- function Sections:OnLoad()

-- end

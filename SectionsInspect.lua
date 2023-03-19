Sections = {
	NumberOfSections = 0, -- 2,3,4 are only valid configurations. others are invalid
	Index = 0,
	["#1:RearToRear#2:FrontToFront#3:RearToRear"] = 4,
	["#1:RearToFront#2:RearToRear"] = 3,
	["#1:RearToRear#2:FrontToRear"] = 3,
	["#1:RearToRear"] = 2,	
	-- templates that are actually only valid options
	
} -- master table that holds data (instead of controls) and methods

TailResponse = { 
	[0] = {},
	[1] = {},
} -- temp table to hold responses from other units

-- Method called from OnConsistMessage once message is received 
function Sections:OCM(msg, argument, direction)
		-- future versions will have separate methods for each msg ID
		if msg == VL10K_PROBE then

			if Call("GetControlValue","MainControlSwitch",0) == 1 then Call("SendConsistMessage",VL10K_PROBE,"KU_WAS_ON",direction == 0 and 1 or 0) return end				
			if string.find(argument,"RESET") then Call("SetControlValue","Number_sections",0,0) Call("SetControlValue","Index",0,0)	Call("SendConsistMessage",msg, argument, direction) end
		
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

		elseif msg == VL10K_INDEX then
			local t = string.split(argument,":")
			t[1], t[2] = tonumber(t[1]), tonumber(t[2])
			t[2] = t[2] + 1
			if t[1] == t[2] then
				Call("SetControlValue","Number_sections",0,t[2])
				Call("SetControlValue","Index",0,t[2])			
				alert("Sections Numeration done")				
			else				
				Call("SetControlValue","Number_sections",0,t[1])
				Call("SetControlValue","Index",0,t[2])				
				Call("SendConsistMessage",VL10K_INDEX,t[1] .. ":" ..t[2],direction)
			end
			
		elseif msg == VL10K_RESPONSE then
			local param = string.split(argument,"#")
			if Call("GetControlValue","MainControlSwitch",0) == 1 then
				TailResponse[direction][ ( table.getn(TailResponse[direction]) + 1 ) or 0 ] = argument
				-- table.insert would be better possibly
			else
				Call("SendConsistMessage",msg,argument,direction)
			end
		
		elseif string.find(argument, "KU_WAS_ON") then
			if Call("GetControlValue","avt_ku",0) == 1 then -- Power.KU
				alert("Another KU")
			else
				Call("SendConsistMessage",msg,argument,direction)
			end
		end

end --


-- called when KU becomes 1
function Sections:PlayerInit()
	if PlayerInit then return end
	PlayerInit = true
	if ProbeFront then Call("SendConsistMessage",VL10K_PROBE,"#1:Front",0) end
	if ProbeRear then Call("SendConsistMessage",VL10K_PROBE,"#1:Rear",1) end
	
end

-- main method called every frame to handle different stages of inspection
function Sections:Update(probeFront,probeRear)
	if Timer("PlayerInit") then
		Timer("PlayerInit","clear")
		PlayerInit = false

		if TailResponse[1][1] then alert("Error!","You can't start from middle section!") return end
		
		local num = self[TailResponse[0][1]] or self[TailResponse[0][2]] or self[TailResponse[0][3]] or 0		

		if num ~= 0 and not TailResponse[1][1] then --filters if there are sections ahead of our cab (which is should not be) and filters config by templates in main table
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
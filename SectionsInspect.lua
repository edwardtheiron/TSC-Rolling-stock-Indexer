Sections = {
	TotalStatus = "none", -- must be "Head_Found" for all correct sections
	NumberOfSections = 0, -- 2,3,4 are only valid configurations. others are invalid
	Index = 0,
} -- master table that holds data (instead of controls) and methods

AdjacentSections = { Count = 0, Front = "none", Rear = "none", Status = "none" }

-- Inspection triggers when ConsistLength is changed (or forced other way. cab change?)
function Sections:Inspect(probeFront,probeRear)
	
	-- TODO: previous data must be wiped
	
	if isDeadLoco then AdjacentSections.Status = "Invalid" return end
	
	if probeFront then
		--AdjacentSections.Front = "Vehicle"	
		Call("SendConsistMessage", VL10K_PROBE, "SECTIONS_INSPECT#VLFront", 0)
	end
	
	if probeRear then 
		--AdjacentSections.Rear = "Vehicle"	
		Call("SendConsistMessage", VL10K_PROBE, "SECTIONS_INSPECT#VLRear", 1)
	end

	-- "SECTIONS_INSPECT#VLRear" - example
	-- next step is reading these messages inside OCM method
	
	Timer("SECTIONS_INSPECT", 0.05)
	
end
--[[
---------  CHEAT SHEET  ---------
--- FRONT <- 0 SEND 1 -> REAR ---
---------------------------------
--- FRONT -> 1 OCM 0  <- REAR ---
---------------------------------
-- <>
-- <<>
-- <>>
-- <><>
]]--

-- Method called from ConsistMessage once message is received 
function Sections:OCM(msg, argument, direction)
	if not isDeadLoco then
		if string.find(argument,"SECTIONS_INSPECT") then

			local t = string.split(argument,"#")

			AdjacentSections.Count = AdjacentSections.Count + 1 
			
			if direction == 1 then 
				AdjacentSections.Front = t[2]	
			else
				AdjacentSections.Rear = t[2]	
			end -- if no msg came, status(es) will remain 'none' or vehicle
			--print(t[1],t[2],t[3],AdjacentSections.Rear,"####")
			-- At the end we should get info on Adjacent Sections. If they are and their orientation and ofc their count
		elseif string.find(argument,"TAIL_CHECK#") then
			
			local status = AdjacentSections.Status
			local t = string.split(argument,"#")
			if status == "Invalid" or status == "Broken" then 
				Call("SendConsistMessage",msg,"TAIL_CHECK_FAIL#" .. t[2],direction == 0 and 1 or 0) 
				--Call("SendConsistMessage",VL10K_PROBE,"SET_INVALID",direction) 
				return 
			end			
				
			t[2] = t[2] + 1
			
			if t[2] < 4 then
			
				if AdjacentSections.Status == "Middle" then
					Call("SendConsistMessage",VL10K_PROBE,"TAIL_CHECK#" .. t[2],direction)
					self.Index = t[2]
				else
					AdjacentSections.Status = nil
					AdjacentSections.Status = "Tail"
					Call("SendConsistMessage",msg,"TAIL_CHECK_SUCCES#" .. t[2],direction == 0 and 1 or 0)
					self.NumberOfSections = t[2]
					self.Index = t[2]
					alert("TAIL_CHECK_SUCCES#Tail",t[2])
					Call("SetControlValue", "Number_sections", 0, t[2])
				end
			else -- 4th section
				print("4th section")
				if direction == 0 then
					--if AdjacentSections.Status == "Middle" then
					if AdjacentSections.Rear == "VLRear" then
						AdjacentSections.Status = nil 
						AdjacentSections.Status = "Tail"
						Call("SendConsistMessage",msg,"TAIL_CHECK_SUCCES#" .. t[2],1)
						self.NumberOfSections = t[2]
						self.Index = t[2]
						alert("TAIL_CHECK_SUCCES#Tail",t[2])
						Call("SetControlValue", "Number_sections", 0, t[2])
					else
						AdjacentSections.Status = nil
						AdjacentSections.Status = "Invalid"		
						alert("TAIL_CHECK_FAIL#Tail",t[2])						
						Call("SendConsistMessage",msg,"TAIL_CHECK_FAIL#" .. t[2],1) 
					end
					--end	
				else
					AdjacentSections.Status = nil
					AdjacentSections.Status = "Invalid"		
					alert("TAIL_CHECK_FAIL#Tail",t[2])
					Call("SendConsistMessage",msg,"TAIL_CHECK_FAIL#" .. t[2],1) 
				end
				
				-- if middle facing front to invalid then Status = "Tail", Send response to Head
				
			end
		elseif string.find(argument,"TAIL_CHECK_FAIL") then
			-- if middle facing front to invalid then Status = "Tail", Send response to Head
			if AdjacentSections.Status == "Middle" and direction == 1 then -- came from front				
				AdjacentSections.Status = "Tail"
				local t = string.split(argument,"#")
				Self.NumberOfSections = t[2]
				if t[2] == 2 then
					--standard
					Call("SendConsistMessage",msg,"TAIL_CHECK_SUCCES#" .. t[2],direction)
					alert("TAIL_CHECK_SUCCES#D",t[2])
					Call("SetControlValue", "Number_sections", 0, t[2])
				elseif t[2] == 3 then
					Call("SendConsistMessage",msg,"TAIL_CHECK_SUCCES#" .. t[2],direction)
					alert("TAIL_CHECK_SUCCES#J",t[2])
					Call("SetControlValue", "Number_sections", 0, t[2])
				end
				
				
			end
		elseif string.find(argument,"TAIL_CHECK_SUCCES") then
			local t = string.split(argument,"#")
			self.NumberOfSections = t[2]
			local status = AdjacentSections.Status
			if status == "Middle" then
				Call("SendConsistMessage",msg,argument,direction)
			elseif status == "Head" or status == "Tail" then
				--message returned to sender
				if AdjacentSections.Rear == "VLRear" then
					AdjacentSections.Status = "Driver"
					Call("SetControlValue", "Number_sections", 0, t[2])
				else
					AdjacentSections.Status = "Invalid"
					alert("Head is invalid")
					--Call("SendConsistMessage", "Number_sections", 0, t[2])				
				end
			end
		end
	end
end --

-- called when KU becomes 1
function Sections:PlayerInit()
	if PlayerInit then return end
	PlayerInit = true
	local status = AdjacentSections.Status
	if status == "Head" or status == "Tail" or status == "Driver" then
		Call("SendConsistMessage",VL10K_PROBE,"TAIL_CHECK#1",1)
		self.Index = 1
		Timer("PlayerInit",0.05)
		alert("PlayerInit started")
	elseif status == "Middle" then
		alert("You can't use middle section as main. Sorry!")
	elseif status == "Invalid" then
		alert("Sections configuration is invalid")
	end
end

-- main method called every frame to handle different stages of inspection
function Sections:Update(probeFront,probeRear)

	if Timer("SECTIONS_INSPECT") then 		
	
		Timer("SECTIONS_INSPECT", "clear")		
		local Count = AdjacentSections.Count
		
		if Count == 0 then
		
			AdjacentSections.Status = "Invalid"
			
		elseif Count == 1 then

			if AdjacentSections.Rear == "none" then -- not VL10k unit at rear side or just empty rear side				
				AdjacentSections.Status = "Invalid"						
			elseif probeFront then	
				AdjacentSections.Front = "Vehicle"
				AdjacentSections.Status = "Tail"
			else	
				AdjacentSections.Status = "Head"				
			end
			
		elseif Count == 2 then 
			AdjacentSections.Status = "Middle"		
		end
		
		Timer("Status",0.05)	
	end

	if Timer("Status") then
		Timer("Status","clear")

		Print(AdjacentSections.Count," #In front there is_",AdjacentSections.Front," #At the rear there is_",AdjacentSections.Rear," #Status is_",AdjacentSections.Status)
		
	end
	
	if Timer("PlayerInit")	then
		Timer("PlayerInit","clear")
		Call("SetRVNumber",RVN .. " - " .. AdjacentSections.Status)
	end
end


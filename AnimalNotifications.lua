-- Mod for Farming Simulator 17
-- Mod: Animal Notifications
-- Author: MCB  with contributions from MX11(added german translations, made sound path universal, added dryGrass to sheep feed section)

local modDesc = loadXMLFile("modDesc", g_currentModDirectory .. "modDesc.xml");

animalNotification = {};
animalNotification.version = getXMLString(modDesc, "modDesc.version");
animalNotification.modDirectory = g_currentModDirectory;

addModEventListener(animalNotification);

function animalNotification:loadMap()
	--animal bools and counters
	self.chickenIssues = 0;
	self.sheepIssues = 0;
	self.cowIssues = 0;
	self.pigIssues = 0;

	self.haveChickenIssues = false;
	self.haveSheepIssues = false;
	self.haveCowIssues = false;
	self.havePigIssues = false;

	self.numSheep = 0;
	self.numCows = 0;
	self.numPigs = 0;

	self.haveChickens = false;
	self.haveSheep = false;
	self.haveCows = false;
	self.havePigs = false;

	self.numSheepChanged = false;
	self.numCowsChanged = false;
	self.numPigsChanged = false;

	--animal births
	self.chickBirthCompare = 0;
	self.sheepBirthCompare = 0;
	self.cowBirthCompare = 0;
	self.pigBirthCompare = 0;
	self.birthTimerDuration = 0.25;

	--thresholds
	self.feedWarnLevel = 0.2; --20 percent
	self.eggThreshold = 60;
	self.woolThreshold = 1950;
	self.productivityThreshold = 40;
	self.cleanlinessThreshold = 20;
	self.manureThreshold = 395000;
	self.slurryThreshold = 795000;
	self.sheepWaterThreshold = 1300 * self.feedWarnLevel; --minFill * feedWarnLevel
	self.sheepGrassThreshold = 2700 * self.feedWarnLevel;
	self.cowWaterThreshold = 3100 * self.feedWarnLevel;
	self.cowStrawThreshold = 6300 * self.feedWarnLevel;
	self.cowGrassThreshold = 6300 * self.feedWarnLevel;
	self.silageThreshold = 15800 * self.feedWarnLevel;
	self.tmrThreshold = 9400 * self.feedWarnLevel;
	self.pigWaterThreshold = 900 * self.feedWarnLevel;
	self.pigStrawThreshold = 1900 * self.feedWarnLevel;
	self.cornThreshold = 4100 * self.feedWarnLevel;
	self.grainThreshold = 2100 * self.feedWarnLevel;
	self.proteinThreshold = 1600 * self.feedWarnLevel;
	self.rootThreshold = 410 * self.feedWarnLevel;

	--notify ({active message bool, [timerEndTime]})
	self.notify = {}

	self.notify.generalMessageActive = {false};

	self.notify.eggMessageActive = {false};
	self.notify.chickenBirthActive = {false};

	self.notify.productivityMessageSheepActive = {false};
	self.notify.cleanlinessMessageSheepActive = {false};
	self.notify.waterMessageSheepActive = {false};
	self.notify.grassMessageSheepActive = {false};
	self.notify.woolMessageActive = {false};
	self.notify.sheepBirthActive = {false};

	self.notify.productivityMessagePigActive = {false};
	self.notify.cleanlinessMessagePigActive = {false};
	self.notify.waterMessagePigActive = {false};
	self.notify.strawMessagePigActive = {false};
	self.notify.cornMessageActive = {false};
	self.notify.grainMessageActive = {false};
	self.notify.proteinMessageActive = {false};
	self.notify.root_cropsMessageActive = {false};
	self.notify.liquidManureMessagePigActive = {false};
	self.notify.manureMessagePigActive = {false};
	self.notify.pigBirthActive = {false};

	self.notify.productivityMessageCowActive = {false};
	self.notify.cleanlinessMessageCowActive = {false};
	self.notify.waterMessageCowActive = {false};
	self.notify.strawMessageCowActive = {false};
	self.notify.grassMessageCowActive = {false};
	self.notify.silageMessageActive = {false};
	self.notify.tmrMessageActive = {false};
	self.notify.liquidManureMessageCowActive = {false};
	self.notify.manureMessageCowActive = {false};
	self.notify.cowBirthActive = {false};

	--notifications ({key, message})
	self.notifications = {};

	--snooze notifications
	self.snooze = false;
	self.snoozeTimerStart = 0;
	self.snoozeTimerEnd = 0;
	self.snoozeDuration = 9;

	--timeScale
	self.timeScale = g_currentMission.loadingScreen.missionInfo.timeScale;

	--set up sound
	self.previousActiveNotifications = 0;
	self.notificationSound = createSample("notify");
	loadSample(self.notificationSound, getAppBasePath().."data/maps/sounds/radio.wav", false);

	--20 minute initial animal update lag
	self.initializing = true;
	self.initialMilliseconds = 0;
	self.initialMinutes = 0;
end;

function animalNotification:makeNotification(issue, animal, numAnimals)
	local message = "";

	if issue == "general" then
		message = g_i18n:getText("AN_GENERAL");

	elseif issue == "egg" then
		message = g_i18n:getText("AN_COLLECTEGGS");

	elseif issue == "wool" then
		message = g_i18n:getText("AN_WOOLPALLET");

	elseif issue == "birth" then
		message = string.format(g_i18n:getText("AN_ANIMALBORN"), g_i18n:getText("shopItem_"..animal));

	elseif issue == "cleanliness" then
		message = string.format(g_i18n:getText("AN_CLEANAREA"), g_i18n:getText("shopItem_"..animal));

	elseif issue == "productivity" then
		message = string.format(g_i18n:getText("AN_PRODUCTIVITYLOW"), g_i18n:getText("shopItem_"..animal));

	elseif issue == "slurry" then
		message = string.format(g_i18n:getText("AN_SLURRYTANKFULL"), g_i18n:getText("shopItem_"..animal));

	elseif issue == "manure" then
		message = string.format(g_i18n:getText("AN_MANUREFULL"), g_i18n:getText("shopItem_"..animal));

	else
		if numAnimals == 1 then
			message = string.format(g_i18n:getText("AN_ANIMALNEEDS1"), g_i18n:getText("shopItem_"..animal), issue);
			
		elseif animal == "sheep" then
			message = string.format(g_i18n:getText("AN_ANIMALNEEDS2"), g_i18n:getText("shopItem_"..animal), issue);
		else
			message = string.format(g_i18n:getText("AN_ANIMALNEEDS3"), g_i18n:getText("shopItem_"..animal), issue);
		end;
	end;

	return(message);
end;

function animalNotification:checkChickens()
	local newAnimalThreshold = g_currentMission.husbandries.chicken.newAnimalPercentage;

	--eggs
	if math.floor(g_currentMission.husbandries.chicken.numActivePickupObjects) >= self.eggThreshold then
		if self.notify.eggMessageActive[1] == false then
			local message = animalNotification:makeNotification("egg", nil, nil);
			table.insert(self.notifications, {"egg", message});
			self.notify.eggMessageActive[1] = true;
			self.chickenIssues = self.chickenIssues + 1;
		end;
	elseif self.notify.eggMessageActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "egg" then
				table.remove(self.notifications, k);
				self.notify.eggMessageActive[1] = false;
				self.chickenIssues = self.chickenIssues - 1;
			end;
		end;
	end;

	--births
	if newAnimalThreshold ~= nill and self.chickBirthCompare - newAnimalThreshold > 0 then
		if self.notify.chickenBirthActive[1] == false then
			local message = animalNotification:makeNotification("birth", "chicken", nil);
			table.insert(self.notifications, {"chickenBirth", message});
			self.notify.chickenBirthActive[1] = true;
			--set timer
			if self.notify.chickenBirthActive[2] == nil then
				self.notify.chickenBirthActive[3] = g_currentMission.environment.realHourTimer/1000/60;
				self.notify.chickenBirthActive[2] = (self.notify.chickenBirthActive[3] - self.birthTimerDuration) % 60; --timerEnd = currentTime + duration * timeScale
			end;
		end;
	elseif self.notify.chickenBirthActive[1] then
		if self.timeScaleChanged then
			self.notify.chickenBirthActive[2] = (self.notify.chickenBirthActive[3] - self.birthTimerDuration) % 60; --recalculate endTime if timeScale changes
		end;
		if g_currentMission.environment.realHourTimer/1000/60 < self.notify.chickenBirthActive[2] then --is currentTime > timerEnd
			for k, v in pairs(self.notifications) do
				if v[1] == "chickenBirth" then
					table.remove(self.notifications, k);
					self.notify.chickenBirthActive[1] = false;
					self.notify.chickenBirthActive[2] = nil;
					self.notify.chickenBirthActive[3] = nil;
				end;
			end;
		end;
	end;
	self.chickBirthCompare = newAnimalThreshold;

	if self.chickenIssues > 0 then
		self.havechickenIssues = true;
	else
		self.havechickenIssues = false;
	end;
end;

function animalNotification:checkSheep()
	local newAnimalThreshold = g_currentMission.husbandries.sheep.newAnimalPercentage;
	--sheep thresholds
	local maxFill = 0;
	local minFill = 0;

	if self.numSheepChanged then
		--sheepWater threshold
		maxFill = 90 * self.numSheep;
		minFill = 1300;
		if maxFill > minFill then
			self.sheepWaterThreshold = maxFill * self.feedWarnLevel;
		end;

		--sheepGrass threshold
		maxFill = 180 * self.numSheep;
		minFill = 2700;
		if maxFill > minFill then
			self.sheepGrassThreshold = maxFill * self.feedWarnLevel;
		end;
	end;
	--check as long as the problem exists
	--wool
	if g_currentMission.husbandries.sheep.currentPallet ~= nil then
		if math.floor(g_currentMission.husbandries.sheep.currentPallet.fillLevel) >= self.woolThreshold then
			if self.notify.woolMessageActive[1] == false then
				local message = animalNotification:makeNotification("wool", nil, nil);
				table.insert(self.notifications, {"wool", message});
				self.notify.woolMessageActive[1] = true;
				self.sheepIssues = self.sheepIssues + 1;
			end;
		elseif self.notify.woolMessageActive[1] then
			for k, v in pairs(self.notifications) do
				if v[1] == "wool" then
					table.remove(self.notifications, k);
					self.notify.woolMessageActive[1] = false;
					self.sheepIssues = self.sheepIssues - 1;
				end;
			end;
		end;
	end;

	--births
	if newAnimalThreshold ~= nill and self.sheepBirthCompare - newAnimalThreshold > 0 then
		if self.notify.sheepBirthActive[1] == false then
			local message = animalNotification:makeNotification("birth", "sheep", nil);
			table.insert(self.notifications, {"sheepBirth", message});
			self.notify.sheepBirthActive[1] = true;
			--set timer
			if self.notify.sheepBirthActive[2] == nil then
				self.notify.sheepBirthActive[3] = g_currentMission.environment.realHourTimer/1000/60; --time start
				self.notify.sheepBirthActive[2] = (self.notify.sheepBirthActive[3] - self.birthTimerDuration) % 60; --timerEnd = currentTime + duration * timeScale
			end;
		end;
	elseif self.notify.sheepBirthActive[1] then
		if self.timeScaleChanged then
			self.notify.sheepBirthActive[2] = (self.notify.sheepBirthActive[3] - self.birthTimerDuration) % 60;--recalculate endTime if timeScale changes
		end;
		if g_currentMission.environment.realHourTimer/1000/60 < self.notify.sheepBirthActive[2] then --is currentTime > timerEnd
			for k, v in pairs(self.notifications) do
				if v[1] == "sheepBirth" then
					table.remove(self.notifications, k);
					self.notify.sheepBirthActive[1] = false;
					self.notify.sheepBirthActive[2] = nil;
					self.notify.sheepBirthActive[3] = nil;
				end;
			end;
		end;
	end;
	self.sheepBirthCompare = newAnimalThreshold;

	--only check if sheep are owned
	--productivity
	if self.haveSheep and self.initializing == false and math.floor(g_currentMission.husbandries.sheep.productivity * 100) < self.productivityThreshold then
		if self.notify.productivityMessageSheepActive[1] == false then
			local message = animalNotification:makeNotification("productivity", "Sheep", nil);
			table.insert(self.notifications, {"sheepProductivity", message});
			self.notify.productivityMessageSheepActive[1] = true;
			self.sheepIssues = self.sheepIssues + 1;
		end;
	elseif self.haveSheep == false or self.notify.productivityMessageSheepActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "sheepProductivity" then
				table.remove(self.notifications, k);
				self.notify.productivityMessageSheepActive[1] = false;
				self.sheepIssues = self.sheepIssues - 1;
			end;
		end;
	end;

	--cleanliness
	if self.haveSheep and math.floor(g_currentMission.husbandries.sheep.cleanlinessFactor * 100) < self.cleanlinessThreshold then
		if self.notify.cleanlinessMessageSheepActive[1] == false then
			local message = animalNotification:makeNotification("cleanliness", "sheep", nil);
			table.insert(self.notifications, {"sheepCleanliness", message});
			self.notify.cleanlinessMessageSheepActive[1] = true;
			self.sheepIssues = self.sheepIssues + 1;
		end;
	elseif self.haveSheep == false or self.notify.cleanlinessMessageSheepActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "sheepCleanliness" then
				table.remove(self.notifications, k);
				self.notify.cleanlinessMessageSheepActive[1] = false;
				self.sheepIssues = self.sheepIssues - 1;
			end;
		end;
	end;

	--water
	if self.haveSheep and math.floor(g_currentMission.husbandries.sheep:getFillLevel(FillUtil.FILLTYPE_WATER)) < self.sheepWaterThreshold then
		if self.notify.waterMessageSheepActive[1] == false then
			local message = animalNotification:makeNotification("water", "sheep", g_currentMission.husbandries.sheep.totalNumAnimals);
			table.insert(self.notifications, {"sheepWater", message});
			self.notify.waterMessageSheepActive[1] = true;
			self.sheepIssues = self.sheepIssues + 1;
		elseif self.numSheepChanged then 
			local message = animalNotification:makeNotification("water", "sheep", self.numPigs);
			for k, v in pairs(self.notifications) do
				if v[1] == "sheepWater" then
					v[2] = message;
				end;
			end;
		end;
	elseif self.haveSheep == false or self.notify.waterMessageSheepActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "sheepWater" then
				table.remove(self.notifications, k);
				self.notify.waterMessageSheepActive[1] = false;
				self.sheepIssues = self.sheepIssues - 1;
			end;
		end;
	end;

		--grass
	if self.haveSheep and math.floor(g_currentMission.husbandries.sheep:getFillLevel(FillUtil.FILLTYPE_GRASS_WINDROW) + g_currentMission.husbandries.sheep:getFillLevel(FillUtil.FILLTYPE_DRYGRASS_WINDROW)) < self.sheepGrassThreshold then
		if self.notify.grassMessageSheepActive[1] == false then
			local message = animalNotification:makeNotification("grass", "sheep", g_currentMission.husbandries.sheep.totalNumAnimals);
			table.insert(self.notifications, {"sheepGrass", message});
			self.notify.grassMessageSheepActive[1] = true;
			self.sheepIssues = self.sheepIssues + 1;
		elseif self.numSheepChanged then 
			local message = animalNotification:makeNotification("grass", "sheep", self.numPigs);
			for k, v in pairs(self.notifications) do
				if v[1] == "sheepGrass" then
					v[2] = message;
				end;
			end;
		end;
	elseif self.haveSheep == false or self.notify.grassMessageSheepActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "sheepGrass" then
				table.remove(self.notifications, k);
				self.notify.grassMessageSheepActive[1] = false;
				self.sheepIssues = self.sheepIssues - 1;
			end;
		end;
	end;

	if self.sheepIssues > 0 then
		self.haveSheepIssues = true;
	else
		self.haveSheepIssues = false;
	end;
end;

function animalNotification:checkCows()
	local newAnimalThreshold = g_currentMission.husbandries.cow.newAnimalPercentage;
	--cow thresholds
	local maxFill = 0;
	local minFill = 0;

	if self.numCowsChanged then
		--cowWater threshold
		maxFill = 210 * self.numCows;
		minFill = 3100;
		if maxFill > minFill then
			self.cowWaterThreshold = maxFill * self.feedWarnLevel;
		end;

		--cowStraw threshold
		maxFill = 420 * self.numCows;
		minFill = 6300;
		if maxFill > minFill then
			self.cowStrawThreshold = maxFill * self.feedWarnLevel;
		end;

		--cowGrass threshold
		maxFill = 420 * self.numCows;
		minFill = 6300;
		if maxFill > minFill then
			self.cowGrassThreshold = maxFill * self.feedWarnLevel;
		end;

		--silage threshold
		maxFill = 1050 * self.numCows;
		minFill = 15800;
		if maxFill > minFill then
			self.silageThreshold = maxFill * self.feedWarnLevel;
		end;

		--tmr threshold
		maxFill = 630 * self.numCows;
		minFill = 9400;
		if maxFill > minFill then
			self.tmrThreshold = maxFill * self.feedWarnLevel;
		end;
	end;

	--check as long as the problem exists
	--liquidManure
	if math.floor(g_currentMission.husbandries.cow.liquidManureTrigger.fillLevel) > self.slurryThreshold then
		if self.notify.liquidManureMessageCowActive[1] == false then
			local message = animalNotification:makeNotification("slurry", "cow", nil);
			table.insert(self.notifications, {"cowSlurry", message});
			self.notify.liquidManureMessageCowActive[1] = true;
			self.cowIssues = self.cowIssues + 1;
		end;
	elseif self.notify.liquidManureMessageCowActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "cowSlurry" then
				table.remove(self.notifications, k);
				self.notify.liquidManureMessageCowActive[1] = false;
				self.cowIssues = self.cowIssues - 1;
			end;
		end;
	end;

	--manure
	if math.floor(g_currentMission.husbandries.cow.manureFillLevel) > self.manureThreshold then
		if self.notify.manureMessageCowActive[1] == false then
			local message = animalNotification:makeNotification("manure", "cow", nil);
			table.insert(self.notifications, {"cowManure", message});
			self.notify.manureMessageCowActive[1] = true;
			self.cowIssues = self.cowIssues + 1;
		end;
	elseif self.notify.manureMessageCowActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "cowManure" then
				table.remove(self.notifications, k);
				self.notify.manureMessageCowActive[1] = false;
				self.cowIssues = self.cowIssues - 1;
			end;
		end;
	end;

	--births
	if newAnimalThreshold ~= nill and self.cowBirthCompare - newAnimalThreshold > 0 then
		if self.notify.cowBirthActive[1] == false then
			local message = animalNotification:makeNotification("birth", "cow", nil);
			table.insert(self.notifications, {"cowBirth", message});
			self.notify.cowBirthActive[1] = true;
			--set timer
			if self.notify.cowBirthActive[2] == nil then
				self.notify.cowBirthActive[3] = g_currentMission.environment.realHourTimer/1000/60;
				self.notify.cowBirthActive[2] = (self.notify.cowBirthActive[3] - self.birthTimerDuration) % 60; --timerEnd = currentTime + duration * timeScale
			end;
		end;
	elseif self.notify.cowBirthActive[1] then
		if self.timeScaleChanged then
			self.notify.cowBirthActive[2] = (self.notify.cowBirthActive[3] - self.birthTimerDuration) % 60; --recalculate endTime if timeScale changes
		end;
		if g_currentMission.environment.realHourTimer/1000/60 < self.notify.cowBirthActive[2] then --is currentTime > timerEnd
			for k, v in pairs(self.notifications) do
				if v[1] == "cowBirth" then
					table.remove(self.notifications, k);
					self.notify.cowBirthActive[1] = false;
					self.notify.cowBirthActive[2] = nil;
					self.notify.cowBirthActive[3] = nil;
				end;
			end;
		end;
	end;
	self.cowBirthCompare = newAnimalThreshold;

	--only check if cows are owned
	--productivity
	if self.haveCows and self.initializing == false and math.floor(g_currentMission.husbandries.cow.productivity * 100) < self.productivityThreshold then
		if self.notify.productivityMessageCowActive[1] == false then
			local message = animalNotification:makeNotification("productivity", "Cow", nil);
			table.insert(self.notifications, {"cowProductivity", message});
			self.notify.productivityMessageCowActive[1] = true;
			self.cowIssues = self.cowIssues + 1;
		end;
	elseif self.haveCows == false or self.notify.productivityMessageCowActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "cowProductivity" then
				table.remove(self.notifications, k);
				self.notify.productivityMessageCowActive[1] = false;
				self.cowIssues = self.cowIssues - 1;
			end;
		end;
	end;

	--cleanliness
	if self.haveCows and math.floor(g_currentMission.husbandries.cow.cleanlinessFactor * 100) < self.cleanlinessThreshold then
		if self.notify.cleanlinessMessageCowActive[1] == false then
			local message = animalNotification:makeNotification("cleanliness", "cow", nil);
			table.insert(self.notifications, {"cowCleanliness", message});
			self.notify.cleanlinessMessageCowActive[1] = true;
			self.cowIssues = self.cowIssues + 1;
		end;
	elseif self.haveCows == false or self.notify.cleanlinessMessageCowActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "cowCleanliness" then
				table.remove(self.notifications, k);
				self.notify.cleanlinessMessageCowActive[1] = false;
				self.cowIssues = self.cowIssues - 1;
			end;
		end;
	end;

	--water
	if self.haveCows and math.floor(g_currentMission.husbandries.cow:getFillLevel(FillUtil.FILLTYPE_WATER)) < self.cowWaterThreshold then
		if self.notify.waterMessageCowActive[1] == false then
			local message = animalNotification:makeNotification("water", "cow", g_currentMission.husbandries.cow.totalNumAnimals);
			table.insert(self.notifications, {"cowWater", message});
			self.notify.waterMessageCowActive[1] = true;
			self.cowIssues = self.cowIssues + 1;
		elseif self.numCowsChanged then 
			local message = animalNotification:makeNotification("water", "cow", self.numPigs);
			for k, v in pairs(self.notifications) do
				if v[1] == "cowWater" then
					v[2] = message;
				end;
			end;
		end;
	elseif self.haveCows == false or self.notify.waterMessageCowActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "cowWater" then
				table.remove(self.notifications, k);
				self.notify.waterMessageCowActive[1] = false;
				self.cowIssues = self.cowIssues - 1;
			end;
		end;
	end;

	--straw
	if self.haveCows and math.floor(g_currentMission.husbandries.cow:getFillLevel(FillUtil.FILLTYPE_STRAW)) < self.cowStrawThreshold then
		if self.notify.strawMessageCowActive[1] == false then
			local message = animalNotification:makeNotification("straw", "cow", g_currentMission.husbandries.cow.totalNumAnimals);
			table.insert(self.notifications, {"cowStraw", message});
			self.notify.strawMessageCowActive[1] = true;
			self.cowIssues = self.cowIssues + 1;
		elseif self.numCowsChanged then 
			local message = animalNotification:makeNotification("straw", "cow", self.numPigs);
			for k, v in pairs(self.notifications) do
				if v[1] == "cowStraw" then
					v[2] = message;
				end;
			end;
		end;
	elseif self.haveCows == false or self.notify.strawMessageCowActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "cowStraw" then
				table.remove(self.notifications, k);
				self.notify.strawMessageCowActive[1] = false;
				self.cowIssues = self.cowIssues - 1;
			end;
		end;
	end;

	--grass
	if self.haveCows and math.floor(g_currentMission.husbandries.cow:getFillLevel(FillUtil.FILLTYPE_GRASS_WINDROW)) < self.cowGrassThreshold then
		if self.notify.grassMessageCowActive[1] == false then
			local message = animalNotification:makeNotification("grass", "cow", g_currentMission.husbandries.cow.totalNumAnimals);
			table.insert(self.notifications, {"cowGrass", message});
			self.notify.grassMessageCowActive[1] = true;
			self.cowIssues = self.cowIssues + 1;
		elseif self.numCowsChanged then 
			local message = animalNotification:makeNotification("grass", "cow", self.numPigs);
			for k, v in pairs(self.notifications) do
				if v[1] == "cowGrass" then
					v[2] = message;
				end;
			end;
		end;
	elseif self.haveCows == false or self.notify.grassMessageCowActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "cowGrass" then
				table.remove(self.notifications, k);
				self.notify.grassMessageCowActive[1] = false;
				self.cowIssues = self.cowIssues - 1;
			end;
		end;
	end;

	--silage
	if self.haveCows and math.floor(g_currentMission.husbandries.cow:getFillLevel(FillUtil.FILLTYPE_DRYGRASS_WINDROW) + g_currentMission.husbandries.cow:getFillLevel(FillUtil.FILLTYPE_SILAGE)) < self.silageThreshold then
		if self.notify.silageMessageActive[1] == false then
			local message = animalNotification:makeNotification("silage", "cow", g_currentMission.husbandries.cow.totalNumAnimals);
			table.insert(self.notifications, {"cowSilage", message});
			self.notify.silageMessageActive[1] = true;
			self.cowIssues = self.cowIssues + 1;
		elseif self.numCowsChanged then 
			local message = animalNotification:makeNotification("silage", "cow", self.numPigs);
			for k, v in pairs(self.notifications) do
				if v[1] == "cowSilage" then
					v[2] = message;
				end;
			end;
		end;
	elseif self.haveCows == false or self.notify.silageMessageActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "cowSilage" then
				table.remove(self.notifications, k);
				self.notify.silageMessageActive[1] = false;
				self.cowIssues = self.cowIssues - 1;
			end;
		end;
	end;

	--tmr
	if self.haveCows and math.floor(g_currentMission.husbandries.cow:getFillLevel(FillUtil.FILLTYPE_POWERFOOD)) < self.tmrThreshold then
		if self.notify.tmrMessageActive[1] == false then
			local message = animalNotification:makeNotification("Total Mixed Ration", "cow", g_currentMission.husbandries.cow.totalNumAnimals);
			table.insert(self.notifications, {"cowTMR", message});
			self.notify.tmrMessageActive[1] = true;
			self.cowIssues = self.cowIssues + 1;
		elseif self.numCowsChanged then 
			local message = animalNotification:makeNotification("Total Mixed Ration", "cow", self.numPigs);
			for k, v in pairs(self.notifications) do
				if v[1] == "cowTMR" then
					v[2] = message;
				end;
			end;
		end;
	elseif self.haveCows == false or self.notify.tmrMessageActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "cowTMR" then
				table.remove(self.notifications, k);
				self.notify.tmrMessageActive[1] = false;
				self.cowIssues = self.cowIssues - 1;
			end;
		end;
	end;

	if self.cowIssues > 0 then
		self.haveCowIssues = true;
	else
		self.haveCowIssues = false;
	end;
end;

function animalNotification:checkPigs()
	local newAnimalThreshold = g_currentMission.husbandries.pig.newAnimalPercentage;

	--pig thresholds
	local maxFill = 0;
	local minFill = 0;

	if self.numPigsChanged then
		--pigWater threshold
		maxFill = 60 * self.numPigs;
		minFill = 900;
		if maxFill > minFill then
			self.pigWaterThreshold = maxFill * self.feedWarnLevel;
		end;

		--pigStraw threshold
		maxFill = 120 * self.numPigs;
		minFill = 6300;
		if maxFill > minFill then
			self.pigStrawThreshold = maxFill * self.feedWarnLevel;
		end;

		--corn threshold
		maxFill = 270 * self.numPigs;
		minFill = 4100;
		if maxFill > minFill then
			self.cornThreshold = maxFill * self.feedWarnLevel;
		end;

		--grain threshold
		maxFill = 135 * self.numPigs;
		minFill = 2100;
		if maxFill > minFill then
			self.grainThreshold = maxFill * self.feedWarnLevel;
		end;

		--protein threshold
		maxFill = 108 * self.numPigs;
		minFill = 1600;
		if maxFill > minFill then
			self.proteinThreshold = maxFill * self.feedWarnLevel;
		end;

		--roots threshold
		maxFill = 27 * self.numPigs;
		minFill = 410;
		if maxFill > minFill then
			self.rootThreshold = maxFill * self.feedWarnLevel;
		end;
	end;

	--check as long as the problem exists
	--liquidManure
	if math.floor(g_currentMission.husbandries.pig.liquidManureTrigger.fillLevel) > self.slurryThreshold then
		if self.notify.liquidManureMessagePigActive[1] == false then
			local message = animalNotification:makeNotification("slurry", "pig", nil);
			table.insert(self.notifications, {"pigSlurry", message});
			self.notify.liquidManureMessagePigActive[1] = true;
			self.pigIssues = self.pigIssues + 1;
		end;
	elseif self.notify.liquidManureMessagePigActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "pigSlurry" then
				table.remove(self.notifications, k);
				self.notify.liquidManureMessagePigActive[1] = false;
				self.pigIssues = self.pigIssues - 1;
			end;
		end;
	end;

	--manure
	if math.floor(g_currentMission.husbandries.pig.manureFillLevel) > self.manureThreshold then
		if self.notify.manureMessagePigActive[1] == false then
			local message = animalNotification:makeNotification("manure", "pig", nil);
			table.insert(self.notifications, {"pigManure", message});
			self.notify.manureMessagePigActive[1] = true;
			self.pigIssues = self.pigIssues + 1;
		end;
	elseif self.notify.manureMessagePigActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "pigManure" then
				table.remove(self.notifications, k);
				self.notify.manureMessagePigActive[1] = false;
				self.pigIssues = self.pigIssues - 1;
			end;
		end;
	end;

	--births
	if newAnimalThreshold ~= nill and self.pigBirthCompare - newAnimalThreshold > 0 then
		if self.notify.pigBirthActive[1] == false then
			local message = animalNotification:makeNotification("birth", "pig", nil);
			table.insert(self.notifications, {"pigBirth", message});
			self.notify.pigBirthActive[1] = true;
			--set timer
			if self.notify.pigBirthActive[2] == nil then
				self.notify.pigBirthActive[3] = g_currentMission.environment.realHourTimer/1000/60;
				self.notify.pigBirthActive[2] = (self.notify.pigBirthActive[3] - self.birthTimerDuration) % 60; --timerEnd = currentTime + duration * timeScale
			end;
		end;
	elseif self.notify.pigBirthActive[1] then
		if self.timeScaleChanged then
			self.notify.pigBirthActive[2] = (self.notify.pigBirthActive[3] - self.birthTimerDuration) % 60; --recalculate endTime if timeScale changes
		end;
		if g_currentMission.environment.realHourTimer/1000/60 < self.notify.pigBirthActive[2] then --is currentTime < timerEnd
			for k, v in pairs(self.notifications) do
				if v[1] == "pigBirth" then
					table.remove(self.notifications, k);
					self.notify.pigBirthActive[1] = false;
					self.notify.pigBirthActive[2] = nil;
					self.notify.pigBirthActive[3] = nil;
				end;
			end;
		end;
	end;
	self.pigBirthCompare = newAnimalThreshold;

	--only check if pigs are owned
	--productivity
	if self.havePigs and self.initializing == false and math.floor(g_currentMission.husbandries.pig.productivity * 100) < self.productivityThreshold then
		if self.notify.productivityMessagePigActive[1] == false then
			local message = animalNotification:makeNotification("productivity", "Pig", nil);
			table.insert(self.notifications, {"pigProductivity", message});
			self.notify.productivityMessagePigActive[1] = true;
			self.pigIssues = self.pigIssues + 1;
		end;
	elseif self.havePigs == false or self.notify.productivityMessagePigActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "pigProductivity" then
				table.remove(self.notifications, k);
				self.notify.productivityMessagePigActive[1] = false;
				self.pigIssues = self.pigIssues - 1;
			end;
		end;
	end;

	--cleanliness
	if self.havePigs and math.floor(g_currentMission.husbandries.pig.cleanlinessFactor * 100) < self.cleanlinessThreshold then
		if self.notify.cleanlinessMessagePigActive[1] == false then
			local message = animalNotification:makeNotification("cleanliness", "pig", nil);
			table.insert(self.notifications, {"pigCleanliness", message});
			self.notify.cleanlinessMessagePigActive[1] = true;
			self.pigIssues = self.pigIssues + 1;
		end;
	elseif self.havePigs == false or self.notify.cleanlinessMessagePigActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "pigCleanliness" then
				table.remove(self.notifications, k);
				self.notify.cleanlinessMessagePigActive[1] = false;
				self.pigIssues = self.pigIssues - 1;
			end;
		end;
	end;

	--water
	if self.havePigs and math.floor(g_currentMission.husbandries.pig:getFillLevel(FillUtil.FILLTYPE_WATER)) < self.pigWaterThreshold then
		if self.notify.waterMessagePigActive[1] == false then
			local message = animalNotification:makeNotification("water", "pig", self.numPigs);
			table.insert(self.notifications, {"pigWater", message});
			self.notify.waterMessagePigActive[1] = true;
			self.pigIssues = self.pigIssues + 1;
		elseif self.numPigsChanged then 
			local message = animalNotification:makeNotification("water", "pig", self.numPigs);
			for k, v in pairs(self.notifications) do
				if v[1] == "pigWater" then
					v[2] = message;
				end;
			end;
		end;
	elseif self.havePigs == false or self.notify.waterMessagePigActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "pigWater" then
				table.remove(self.notifications, k);
				self.notify.waterMessagePigActive[1] = false;
				self.pigIssues = self.pigIssues - 1;
			end;
		end;
	end;

	--straw
	if self.havePigs and math.floor(g_currentMission.husbandries.pig:getFillLevel(FillUtil.FILLTYPE_STRAW)) < self.pigStrawThreshold then
		if self.notify.strawMessagePigActive[1] == false then
			local message = animalNotification:makeNotification("straw", "pig", self.numPigs);
			table.insert(self.notifications, {"pigStraw", message});
			self.notify.strawMessagePigActive[1] = true;
			self.pigIssues = self.pigIssues + 1;
		elseif self.numPigsChanged then 
			local message = animalNotification:makeNotification("straw", "pig", self.numPigs);
			for k, v in pairs(self.notifications) do
				if v[1] == "pigStraw" then
					v[2] = message;
				end;
			end;
		end;
	elseif self.havePigs == false or self.notify.strawMessagePigActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "pigStraw" then
				table.remove(self.notifications, k);
				self.notify.strawMessagePigActive[1] = false;
				self.pigIssues = self.pigIssues - 1;
			end;
		end;
	end;

	--corn
	if self.havePigs and math.floor(g_currentMission.husbandries.pig:getFillLevel(FillUtil.FILLTYPE_MAIZE)) < self.cornThreshold then
		if self.notify.cornMessageActive[1] == false then
			local message = animalNotification:makeNotification("corn", "pig", self.numPigs);
			table.insert(self.notifications, {"pigCorn", message});
			self.notify.cornMessageActive[1] = true;
			self.pigIssues = self.pigIssues + 1;
		elseif self.numPigsChanged then 
			local message = animalNotification:makeNotification("corn", "pig", self.numPigs);
			for k, v in pairs(self.notifications) do
				if v[1] == "pigCorn" then
					v[2] = message;
				end;
			end;
		end;
	elseif self.havePigs == false or self.notify.cornMessageActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "pigCorn" then
				table.remove(self.notifications, k);
				self.notify.cornMessageActive[1] = false;
				self.pigIssues = self.pigIssues - 1;
			end;
		end;
	end;

	--grain
	if self.havePigs and math.floor(g_currentMission.husbandries.pig:getFillLevel(FillUtil.FILLTYPE_WHEAT) + g_currentMission.husbandries.pig:getFillLevel(FillUtil.FILLTYPE_BARLEY)) < self.grainThreshold then
		if self.notify.grainMessageActive[1] == false then
			local message = animalNotification:makeNotification("grain", "pig", self.numPigs);
			table.insert(self.notifications, {"pigGrain", message});
			self.notify.grainMessageActive[1] = true;
			self.pigIssues = self.pigIssues + 1;
		elseif self.numPigsChanged then 
			local message = animalNotification:makeNotification("grain", "pig", self.numPigs);
			for k, v in pairs(self.notifications) do
				if v[1] == "pigGrain" then
					v[2] = message;
				end;
			end;
		end;
	elseif self.havePigs == false or self.notify.grainMessageActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "pigGrain" then
				table.remove(self.notifications, k);
				self.notify.grainMessageActive[1] = false;
				self.pigIssues = self.pigIssues - 1;
			end;
		end;
	end;

	--protein
	if self.havePigs and math.floor(g_currentMission.husbandries.pig:getFillLevel(FillUtil.FILLTYPE_RAPE) + g_currentMission.husbandries.pig:getFillLevel(FillUtil.FILLTYPE_SUNFLOWER) + g_currentMission.husbandries.pig:getFillLevel(FillUtil.FILLTYPE_SOYBEAN)) < self.proteinThreshold then
		if self.notify.proteinMessageActive[1] == false then
			local message = animalNotification:makeNotification("protein", "pig", self.numPigs);
			table.insert(self.notifications, {"pigProtein", message});
			self.notify.proteinMessageActive[1] = true;
			self.pigIssues = self.pigIssues + 1;
		elseif self.numPigsChanged then 
			local message = animalNotification:makeNotification("protein", "pig", self.numPigs);
			for k, v in pairs(self.notifications) do
				if v[1] == "pigProtein" then
					v[2] = message;
				end;
			end;
		end;
	elseif self.havePigs == false or self.notify.proteinMessageActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "pigProtein" then
				table.remove(self.notifications, k);
				self.notify.proteinMessageActive[1] = false;
				self.pigIssues = self.pigIssues - 1;
			end;
		end;
	end;

	--root crops
	if self.havePigs and math.floor(g_currentMission.husbandries.pig:getFillLevel(FillUtil.FILLTYPE_POTATO) + g_currentMission.husbandries.pig:getFillLevel(FillUtil.FILLTYPE_SUGARBEET)) < self.rootThreshold then
		if self.notify.root_cropsMessageActive[1] == false then
			local message = animalNotification:makeNotification("root crops", "pig", self.numPigs);
			table.insert(self.notifications, {"pigRoots", message});
			self.notify.root_cropsMessageActive[1] = true;
			self.pigIssues = self.pigIssues + 1;
		elseif self.numPigsChanged then 
			local message = animalNotification:makeNotification("root crops", "pig", self.numPigs);
			for k, v in pairs(self.notifications) do
				if v[1] == "pigRoots" then
					v[2] = message;
				end;
			end;
		end;
	elseif self.havePigs == false or self.notify.root_cropsMessageActive[1] then
		for k, v in pairs(self.notifications) do
			if v[1] == "pigRoots" then
				table.remove(self.notifications, k);
				self.notify.root_cropsMessageActive[1] = false;
				self.pigIssues = self.pigIssues - 1;
			end;
		end;
	end;

	if self.pigIssues > 0 then
		self.havePigIssues = true;
	else
		self.havePigIssues = false;
	end;
end;

function animalNotification:keyEvent(unicode, sym, modifier, isDown)
end;

function animalNotification:mouseEvent(posX, posY, isDown, isUp, button)
end;

function animalNotification:deleteMap()
	for k, v in pairs(self.notifications) do
		 v = nil;
	end;

	for k, v in pairs(self.notify) do
		 v = nil;
	end;
end;

function animalNotification:update(dt)
	-- if InputBinding.hasEvent(InputBinding.MENU_ACCEPT) then
		
	-- end;

	--20 minute initial animal update lag
	self.initializing = true;

	if self.initializing then
		if self.initialMilliseconds + (dt * self.timeScale) >= 60000 then
			self.initialMilliseconds = self.initialMilliseconds - 60000;
			self.initialMinutes = self.initialMinutes + 1;
			if self.initialMinutes > 20 then
				self.initializing = false;
			end;
		end;
	end;
	
	--timeScale
	if self.timeScale ~= g_currentMission.loadingScreen.missionInfo.timeScale then
		self.timeScaleChanged = true;
		self.timeScale = g_currentMission.loadingScreen.missionInfo.timeScale
	else
		self.timeScaleChanged = false;
	end;

	--chickens
	if g_currentMission.husbandries.chicken.totalNumAnimals > 0 then
		self.haveChickens = true;
	else
		self.haveChickens = false;
	end;
	if self.haveChickens or self.haveChickenIssues then
		animalNotification:checkChickens();
	end;

	--sheep
	if self.numSheep ~= g_currentMission.husbandries.sheep.totalNumAnimals then
		self.numSheep = g_currentMission.husbandries.sheep.totalNumAnimals;
		self.numSheepChanged = true;
	else
		self.numSheepChanged = false;
	end;
	if self.numSheep > 0 then
		self.haveSheep = true;
	else
		self.haveSheep = false;
	end;
	if self.haveSheep or self.haveSheepIssues then
		animalNotification:checkSheep();
	end;

	--cows
	if self.numCows ~= g_currentMission.husbandries.cow.totalNumAnimals then
		self.numCows = g_currentMission.husbandries.cow.totalNumAnimals;
		self.numCowsChanged = true;
	else
		self.numCowsChanged = false;
	end;
	if self.numCows > 0 then
		self.haveCows = true;
	else
		self.haveCows = false;
	end;
	if self.haveCows or self.haveCowIssues then
		animalNotification:checkCows();
	end;

	--pigs
	if self.numPigs ~= g_currentMission.husbandries.pig.totalNumAnimals then
		self.numPigs = g_currentMission.husbandries.pig.totalNumAnimals;
		self.numPigsChanged = true;
	else
		self.numPigsChanged = false;
	end;

	if self.numPigs > 0 then
		self.havePigs = true;
	else
		self.havePigs = false;
	end;
	if self.havePigs or self.havePigIssues then
		animalNotification:checkPigs();
	end;

	--snooze notifications
	if InputBinding.hasEvent(InputBinding.NOTE_DELAY) and self.snooze == false then
		self.snooze = true;
		self.snoozeTimerStart = g_currentMission.environment.realHourTimer/1000/60;
		self.snoozeTimerEnd = (self.snoozeTimerStart - self.snoozeDuration) % 60;--((self.snoozeTimerStart - self.snoozeDuration * self.timeScale) % 60) / 100; --timerEnd = currentTime + duration * timeScale
	end;

	if self.snooze then
		if self.timeScaleChanged then
			self.snoozeTimerEnd = (self.snoozeTimerStart - self.snoozeDuration) % 60; --recalculate if timeScale changes
		end;
		if g_currentMission.environment.realHourTimer/1000/60 < self.snoozeTimerEnd then
			self.snooze = false;
		end;
	end;
end;

function animalNotification:draw()
	local activeNotices = 0;
	if self.snooze == false then
		local posX = g_currentMission.infoBarBgOverlay.x + 0.0055;
		local posY = 0.875;
		local fontSize = 0.015;
		local spacing = 0;
		local bgWidth = g_currentMission.infoBarBgOverlay.width;
		local bgHeight = 0.03;
		local bgPosX = g_currentMission.infoBarBgOverlay.x;
		local bgPosY = g_currentMission.infoBarBgOverlay.y - bgHeight;
		local bgSpacing = 0;
		activeNotices = #self.notifications;

		setTextAlignment(RenderText.ALIGN_LEFT);

		if activeNotices > 9 then
			local message = animalNotification:makeNotification("general", nil, nil);
			local notificationBg = Overlay:new("notificationBg", Utils.getFilename("notifcationBg.dds", animalNotification.modDirectory), bgPosX, bgPosY - bgSpacing, bgWidth, bgHeight);
			notificationBg:render();
			renderText(posX, posY - spacing, fontSize, message);
		else
			for i = activeNotices, 1, -1 do
				if self.notifications[i][2] ~= nil then
					local notificationBg = Overlay:new("notificationBg", Utils.getFilename("notifcationBg.dds", animalNotification.modDirectory), bgPosX, bgPosY - bgSpacing, bgWidth, bgHeight);
					notificationBg:render();
					renderText(posX, posY - spacing, fontSize, self.notifications[i][2]);
				end;
				spacing = spacing + bgHeight;
				bgSpacing = bgSpacing + bgHeight;
			end;
		end;
	end;

	if activeNotices ~= self.previousActiveNotifications then
		if activeNotices > self.previousActiveNotifications then
			playSample(self.notificationSound, 1, 1, 0);
		end;
		self.previousActiveNotifications = activeNotices;
	end;
end;

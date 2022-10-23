--[[

    littleDialogue.lua
    Written by MrDoubleA

]]

local configFileReader = require("configFileReader")
local textplus = require("textplus")
local tplusUtils = require("textplus/tplusutils")

local littleDialogue = {}


local smallScreen
pcall(function() smallScreen = require("smallScreen") end)


function littleDialogue.onInitAPI()
    registerEvent(littleDialogue,"onTick")
    registerEvent(littleDialogue,"onDraw")

    registerEvent(littleDialogue,"onMessageBox")
end


local function getBoundaries()
    local b = camera.bounds

    if smallScreen ~= nil and smallScreen.croppingEnabled then
        local widthDifference  = (camera.width  - smallScreen.width ) * 0.5
        local heightDifference = (camera.height - smallScreen.height) * 0.5

        b.left   = b.left   + widthDifference
        b.right  = b.right  - widthDifference
        b.top    = b.top    + heightDifference
        b.bottom = b.bottom - heightDifference
    end

    return b
end


littleDialogue.boxes = {}

local boxInstanceFunctions = {}
local boxMT = {
    __index = boxInstanceFunctions,
}


local STATE = {
    IN     = 0,
    STAY   = 1,
    SCROLL = 2,
    OUT    = 3,
    SCROLL_ANSWERS = 4,

    REMOVE = -1,
}


local customTags = {}
local selfClosingTags = {}

littleDialogue.customTags = customTags
littleDialogue.selfClosingTags = selfClosingTags


-- Questions
local currentlyUpdatingBox,currentlyUpdatingPage


do
    local questionsMap = {}

    function littleDialogue.registerAnswer(name,answer)
        questionsMap[name] = questionsMap[name] or {}

        answer.text = answer.text or answer[1] or ""
        answer.chosenFunction = answer.chosenFunction or answer[2]
        answer.addText = answer.addText or answer[3]

        table.insert(questionsMap[name],answer)
    end

    function littleDialogue.deregisterQuestion(name)
        questionsMap[name] = nil
    end


    function customTags.question(fmt,out,args)
        if currentlyUpdatingBox == nil or currentlyUpdatingPage == nil then
            Misc.warn("Invalid use of question tag.")
            return fmt
        end

        local name = args[1]
        local answers = questionsMap[name]

        if answers == nil then
            Misc.warn("Invalid question '".. name.. "'.")
            return fmt
        end


        for _,answer in ipairs(answers) do
            currentlyUpdatingBox:addQuestion(currentlyUpdatingPage,answer)
        end

        return fmt
    end

    table.insert(selfClosingTags,"question")
end


-- Handle settings
do
    local settingsList

    local extraSettingsList = {
        "font","boxImage","arrowImage","selectorImage",
        "openSound","closeSound","scrollSound","typewriterSound","moveSelectionSound","chooseAnswerSound",
    }


    local function loadImage(settings,styleName,name,imageFilename)
        settings[name] = Graphics.loadImage(Misc.resolveFile("littleDialogue/".. styleName.. "/".. imageFilename) or Misc.resolveFile("littleDialogue/".. imageFilename))
    end
    local function loadSound(settings,styleName,name,soundFilename)
        settings[name] = Misc.resolveSoundFile("littleDialogue/".. styleName.. "/".. soundFilename) or Misc.resolveSoundFile("littleDialogue/".. soundFilename)
    end

    local function findFont(styleName)
        local folderPath = "littleDialogue/".. styleName.. "/font.ini"

        if Misc.resolveFile(folderPath) ~= nil then
            return folderPath
        end

        return "littleDialogue/font.ini"
    end


    littleDialogue.styles = {}

    function boxInstanceFunctions:setStyle(style)
        if self.styleName == style then
            return
        end


        local styleSettings = littleDialogue.styles[style]

        if styleSettings == nil then
            error("Invalid box style '".. style.. "'.")
            return
        end


        self.styleName = style

        self.settings = {}

        for _,name in ipairs(settingsList) do
            if self.overwriteSettings[name] ~= nil then
                self.settings[name] = self.overwriteSettings[name]
            elseif styleSettings[name] ~= nil then
                self.settings[name] = styleSettings[name]
            else
                self.settings[name] = littleDialogue.defaultBoxSettings[name]
            end
        end

        self.maxWidth = self.settings.textMaxWidth
        self.typewriterFinished = (not self.settings.typewriterEnabled)
        self.priority = self.settings.priority
    end

    function littleDialogue.registerStyle(name,settings)
        if settingsList == nil then
            settingsList = table.append(table.unmap(littleDialogue.defaultBoxSettings),extraSettingsList)
        end

        -- Find images/sounds
        loadImage(settings,name,"boxImage","box.png")
        loadImage(settings,name,"arrowImage","arrow.png")
        loadImage(settings,name,"selectorImage","selector.png")

        loadSound(settings,name,"openSound","open")
        loadSound(settings,name,"closeSound","close")
        loadSound(settings,name,"scrollSound","scroll")
        --loadSound(settings,name,"typewriterSound","typewriter")
        loadSound(settings,name,"moveSelectionSound","scroll")
        loadSound(settings,name,"chooseAnswerSound","choose")

        settings.typewriterSound = SFX.open(Misc.resolveSoundFile("littleDialogue/".. name.. "/typewriter") or Misc.resolveSoundFile("littleDialogue/typewriter"))

        settings.font = settings.font or textplus.loadFont(findFont(name))


        littleDialogue.styles[name] = settings
    end


    function customTags.boxStyle(fmt,out,args)
        if currentlyUpdatingBox == nil or currentlyUpdatingPage == nil then
            Misc.warn("Invalid use of boxStyle tag.")
            return fmt
        end

        currentlyUpdatingBox._newStyle = args[1] or currentlyUpdatingBox.styleName

        return fmt
    end

    customTags.boxstyle = customTags.boxStyle

    table.insert(selfClosingTags,"boxStyle")
    table.insert(selfClosingTags,"boxstyle")


    local keyCodeNames = {
        [VK_MENU] = "key_alt",[VK_SHIFT] = "key_shift",[VK_CONTROL] = "key_control",[VK_TAB] = "key_tab",
        [VK_BACK] = "key_backspace",[VK_PRIOR] = "key_pageUp",[VK_NEXT] = "key_pageDown",[VK_HOME] = "key_home",
        [VK_END] = "key_end",[VK_DELETE] = "key_delete",[VK_SPACE] = "key_space",[VK_RETURN] = "key_enter",
        [VK_UP] = "button_up",[VK_RIGHT] = "button_right",[VK_DOWN] = "button_down",[VK_LEFT] = "button_left",
    }

    function customTags.playerKey(fmt,out,args)
        local keyName = (args[1] or ""):lower()
        local keyCode = inputConfig1[keyName]

        if keyCode == nil then
            return fmt
        end


        local imageName

        if Player.count() > 1 or Misc.GetSelectedControllerName(1) ~= "Keyboard" then
            imageName = "button_".. keyName
        elseif keyCode >= 65 and keyCode <= 90 then
            imageName = string.char(keyCode)
        elseif keyCodeNames[keyCode] then
            imageName = keyCodeNames[keyCode]
        else
            imageName = "button_".. keyName
        end


        local imagePath

        if currentlyUpdatingBox ~= nil then
            imagePath = imagePath or Misc.resolveGraphicsFile("littleDialogue/".. currentlyUpdatingBox.styleName.. "/keys/".. imageName.. ".png")
        end

        imagePath = imagePath or Misc.resolveGraphicsFile("littleDialogue/keys/".. imageName.. ".png")


        if imagePath == nil then
            return fmt
        end

        local imageFmt = table.clone(fmt)
        imageFmt.posFilter = function(x,y, fmt,img, width,height)
            return x,y + height*0.5 - fmt.font.ascent*fmt.yscale*0.5
        end

        out[#out+1] = {img = Graphics.loadImage(imagePath),fmt = imageFmt}

        return fmt
    end

    customTags.playerkey = customTags.playerKey

    table.insert(selfClosingTags,"playerKey")
    table.insert(selfClosingTags,"playerkey")

    -- Portraits
    local portraitData = {}

    function littleDialogue.getPortraitData(name)
        if portraitData[name] == nil then
            local txtPath = Misc.resolveFile("littleDialogue/portraits/".. name.. ".txt")
            local data

            if txtPath ~= nil then
                data = configFileReader.rawParse(txtPath,false)
            else
                data = {}
            end

            data.idleFrames = data.idleFrames or 1
            data.idleFrameDelay = data.idleFrameDelay or 1
            data.speakingFrames = data.speakingFrames or 1
            data.speakingFrameDelay = data.speakingFrameDelay or 1


            local imagePath = Misc.resolveGraphicsFile("littleDialogue/portraits/".. name.. ".png")

            if imagePath ~= nil then
                data.image = Graphics.loadImage(imagePath)
                data.width = data.image.width
                data.height = data.image.height / (data.idleFrames + data.speakingFrames)
            else
                data.width = 0
                data.height = 0
            end


            portraitData[name] = data
        end

        return portraitData[name]
    end

    function customTags.portrait(fmt,out,args)
        if currentlyUpdatingBox == nil or currentlyUpdatingPage == nil then
            Misc.warn("Invalid use of portrait tag.")
            return fmt
        end

        local name = args[1]

        if name == nil then
            currentlyUpdatingBox.portraitData = nil
        else
            currentlyUpdatingBox.portraitData = littleDialogue.getPortraitData(name)
        end

        return fmt
    end

    table.insert(selfClosingTags,"portrait")


    -- shake tag
    -- at the time I made this I didn't know tremble existed lol
    --[[function customTags.shake(fmt,out,args)
        fmt = table.clone(fmt)

        fmt.shake = args[1] or 0.75

        fmt.posFilter = function(x,y, fmt,img, width,height)
            return x + RNG.random(-fmt.shake,fmt.shake),y + RNG.random(-fmt.shake,fmt.shake)
        end

        return fmt
    end]]

    -- characterName tag
    littleDialogue.characterNames = {
        [1 ] = "Mario",
        [2 ] = "Luigi",
        [3 ] = "Peach",
        [4 ] = "Toad",
        [5 ] = "Link",
        [6 ] = "Megaman",
        [7 ] = "Wario",
        [8 ] = "Bowser",
        [9 ] = "Klonoa",
        [10] = "Ninja Bomberman",
        [11] = "Rosalina",
        [12] = "Snake",
        [13] = "Zelda",
        [14] = "Ultimate Rinka",
        [15] = "Uncle Broadsword",
        [16] = "Samus",
    }

    function customTags.characterName(fmt,out,args)
        local text = ""

        for index,p in ipairs(Player.get()) do
            text = text.. (littleDialogue.characterNames[p.character] or "Player")

            if index < Player.count()-1 then
                text = text.. ", "
            elseif index < Player.count() then
                text = text.. " and "
            end
        end

        local segment = tplusUtils.strToCodes(text)
        segment.fmt = fmt

        out[#out+1] = segment

        return fmt
    end

    table.insert(selfClosingTags,"characterName")
end



littleDialogue.BOX_STATE = STATE


function littleDialogue.create(args)
    local box = setmetatable({},boxMT)

    box.isValid = true

    box.text = args.text or ""
    box.speakerObj = args.speakerObj or player
    box.uncontrollable = args.uncontrollable or false
    box.silent = args.silent or false

    box.pauses = args.pauses
    if box.pauses == nil then
        box.pauses = true
    end

    box.keepOnScreen = args.keepOnScreen
    if box.keepOnScreen == nil then
        box.keepOnScreen = true
    end



    box.openingProgress = 0
    box.state = STATE.IN

    box.page = 1

    box.answersPageIndex = {}
    box.answersPageTarget = 1

    box.selectedAnswer = 1


    box.mainWidth = 0
    box.mainHeight = 0


    box.typewriterLimit = 0
    box.typewriterDelay = 0
    box.typewriterFinished = true

    
    box.portraitData = nil
    box.portraitFrame = 0
    box.portraitTimer = 0


    box.overwriteSettings = args.settings or {}
    box:setStyle(args.style or littleDialogue.defaultStyleName)


    box:updateLayouts()
    

    if box.pauses then
        Misc.pause(true)
    end

    if not box.silent and box.settings.openSoundEnabled then
        SFX.play(box.settings.openSound)
    end


    table.insert(littleDialogue.boxes,box)

    return box
end



function boxInstanceFunctions:addQuestion(pageIndex,answer)
    local maxWidth = self.maxWidth
    if self.settings.selectorImage ~= nil then
        maxWidth = maxWidth - self.settings.selectorImage.width
    end
    if self.portraitData ~= nil then
        maxWidth = maxWidth - self.portraitData.width
    end

    local layout = textplus.layout(answer.text,maxWidth,{font = self.settings.font,color = self.settings.textColor,xscale = self.settings.textXScale,yscale = self.settings.textYScale},customTags,selfClosingTags)


    local answerPageCount = #self.answerPages[pageIndex]
    local answerPage = self.answerPages[pageIndex][answerPageCount]

    if answerPageCount == 0 or answerPage.height+layout.height+self.settings.answerGap >= self.settings.answerPageMaxHeight then
        -- Create new page of answers
        local firstAnswerIndex = 1
        if answerPageCount > 0 then
            firstAnswerIndex = answerPage.firstAnswerIndex + #answerPage.answers
        end

        answerPageCount = answerPageCount + 1

        answerPage = {answers = {},width = 0,height = 0,firstAnswerIndex = firstAnswerIndex}
        self.answerPages[pageIndex][answerPageCount] = answerPage
    else
        answerPage.height = answerPage.height + self.settings.answerGap
    end



    local width = layout.width
    if self.settings.selectorImage ~= nil then
        width = width + self.settings.selectorImage.width
    end

    answerPage.width = math.max(answerPage.width,width)
    answerPage.height = answerPage.height + layout.height

    local answerObj = {
        text = answer.text,layout = layout,
        chosenFunction = answer.chosenFunction,
        addText = answer.addText,
    }


    table.insert(answerPage.answers,answerObj)
    table.insert(self.plainAnswerList[pageIndex],answerObj)

    self.totalAnswersCount[pageIndex] = self.totalAnswersCount[pageIndex] + 1
end


function boxInstanceFunctions:updateLayouts()
    self.pageText = string.split(self.text,"|",true)
    self.pages = #self.pageText

    self.pageFormattedText = {}
    self.pageLayouts = {}

    self.pageCharacterLists = {}

    self.answerPages = {}
    self.plainAnswerList = {}
    self.totalAnswersCount = {}

    self.answersHeight = 0


    currentlyUpdatingBox = self
    self._newStyle = self.styleName

    for index,pageText in ipairs(self.pageText) do
        currentlyUpdatingPage = index

        self.answerPages[index] = {}
        self.plainAnswerList[index] = {}
        self.totalAnswersCount[index] = 0
        self.answersPageIndex[index] = self.answersPageIndex[index] or 1


        local formattedText = textplus.parse(pageText,{font = self.settings.font,color = self.settings.textColor,xscale = self.settings.textXScale,yscale = self.settings.textYScale},customTags,selfClosingTags)

        if self._newStyle ~= self.styleName then -- change style
            self:setStyle(self._newStyle)
            self:updateLayouts()
            return
        end


        local arrowWidth = 0
        if index < self.pages and #self.answerPages[index] == 0 and not self.uncontrollable and self.settings.arrowImage ~= nil then
            arrowWidth = self.settings.arrowImage.width
        end

        local maxWidth = self.maxWidth - arrowWidth
        if self.portraitData ~= nil then
            maxWidth = maxWidth - self.portraitData.width - self.settings.portraitGap
        end


        local layout = textplus.layout(formattedText,maxWidth)

        local width = layout.width + arrowWidth
        local height = layout.height


        -- Question stuff
        local tallestAnswerPageHeight = 0
        local widestAnswerPageWidth = 0

        for answerPageIndex,answerPage in ipairs(self.answerPages[index]) do
            widestAnswerPageWidth = math.max(widestAnswerPageWidth, answerPage.width)
            tallestAnswerPageHeight = math.max(tallestAnswerPageHeight, answerPage.height)
        end

        self.answersHeight = math.max(self.answersHeight,tallestAnswerPageHeight)


        width = math.max(widestAnswerPageWidth,width)
        height = height + tallestAnswerPageHeight


        local answerPageCount = #self.answerPages[index]

        if answerPageCount > 0 then
            height = height + self.settings.questionGap

            if answerPageCount > 1 and self.settings.arrowImage ~= nil then
                height = height + self.settings.arrowImage.height*2
            end
        end


        if self.portraitData ~= nil then
            width = width + self.portraitData.width + self.settings.portraitGap
            height = math.max(height,self.portraitData.height)
        end


        self.mainWidth = math.max(self.mainWidth,width)
        self.mainHeight = math.max(self.mainHeight,height)


        self.pageFormattedText[index] = formattedText
        self.pageLayouts[index] = layout


        -- Simplify the character list
        self.pageCharacterLists[index] = {}

        local lineCount = #layout
        for lineIndex,line in ipairs(layout) do
            for i = 1,#line,4 do
                local segment = line[i]

                if segment.img ~= nil then
                    table.insert(self.pageCharacterLists[index],-2)
                else
                    local startIdx = line[i+1]
                    local endIdx = line[i+2]

                    for charIdx = startIdx,endIdx do
                        table.insert(self.pageCharacterLists[index],segment[charIdx])
                    end
                end
            end

            if lineIndex < lineCount then
                table.insert(self.pageCharacterLists[index],-1)
            end
        end

        
        --[[local debug = ""
        for _,char in ipairs(self.pageCharacterLists[index]) do
            if char > 0 then
                debug = debug.. string.char(char)
            else
                debug = debug.. "_"
            end
        end
        Misc.dialog(debug,#debug,#self.pageCharacterLists[index])]]
    end

    currentlyUpdatingBox = nil
    currentlyUpdatingPage = nil


    self.totalWidth  = self.mainWidth  + self.settings.borderSize*2
    self.totalHeight = self.mainHeight + self.settings.borderSize*2
end


function boxInstanceFunctions:addDialogue(text,deleteFurtherText)
    if deleteFurtherText == nil or deleteFurtherText then
        -- Delete any text after this page
        local searchStart = 1
        local pageIndex = 1

        while (true) do
            local foundStart,foundEnd = self.text:find("|",searchStart,true)

            if foundStart == nil then
                break
            end

            pageIndex = pageIndex + 1

            if pageIndex <= math.ceil(self.page) then
                searchStart = foundEnd + 1
            else
                self.text = self.text:sub(1,foundStart-1)
                break
            end
        end
    end


    self.maxWidth = self.mainWidth


    if self.text == "" or self.text:sub(-1) == "|" then
        self.text = self.text.. text
    else
        self.text = self.text.. "|".. text
    end

    self:updateLayouts()
end


function boxInstanceFunctions:progress()
    local answer = self.plainAnswerList[self.page][self.selectedAnswer]

    if answer ~= nil then
        if answer.addText ~= nil then
            self:addDialogue(answer.addText,true)
        end

        if answer.chosenFunction ~= nil then
            answer.chosenFunction(self)
        end

        if not self.silent and self.settings.chooseAnswerSoundEnabled then
            SFX.play(self.settings.chooseAnswerSound)
        end
    end

    if self.page < self.pages then
        self.state = STATE.SCROLL

        self.selectedAnswer = 1

        self.typewriterLimit = 0
        self.typewriterFinished = (not self.settings.typewriterEnabled)

        if not self.silent and self.settings.scrollSoundEnabled and answer == nil then
            SFX.play(self.settings.scrollSound)
        end
    else
        self.state = STATE.OUT

        if not self.silent and self.settings.closeSoundEnabled and answer == nil then
            SFX.play(self.settings.closeSound)
        end

        player:mem(0x11E,FIELD_BOOL,false)
    end
end

function boxInstanceFunctions:update()
    if self.state == STATE.STAY then
        local formattedText = self.pageCharacterLists[self.page]
        local characterCount = #formattedText

        if not self.typewriterFinished then
            self.typewriterDelay = self.typewriterDelay - 1
            
            if self.typewriterDelay <= 0 then
                self.typewriterLimit = self.typewriterLimit + 1

                if self.typewriterLimit < characterCount then
                    local character = formattedText[self.typewriterLimit]
                    local nextCharacter = formattedText[self.typewriterLimit + 1]

                    if self.settings.typewriterDelayCharacters[character] and not self.settings.typewriterDelayCharacters[nextCharacter] then
                        self.typewriterDelay = self.settings.typewriterDelayLong
                    else
                        self.typewriterDelay = self.settings.typewriterDelayNormal
                    end
                else
                    self.typewriterFinished = true
                    self.portraitTimer = 0
                end

                if not self.silent and self.settings.typewriterSoundEnabled then
                    SFX.play{sound = self.settings.typewriterSound,delay = self.settings.typewriterSoundDelay}
                end
            end
        end


        if not self.uncontrollable then
            if self.typewriterFinished then
                local count = self.totalAnswersCount[self.page]

                if count > 0 then
                    local answerPageIndex = self.answersPageIndex[self.page]
                    local answerPage = self.answerPages[self.page][answerPageIndex]

                    if player.rawKeys.up == KEYS_PRESSED and self.selectedAnswer > 1 then
                        self.selectedAnswer = self.selectedAnswer - 1

                        if not self.silent and self.settings.moveSelectionSoundEnabled then
                            SFX.play(self.settings.moveSelectionSound)
                        end
                    elseif player.rawKeys.down == KEYS_PRESSED and self.selectedAnswer < count then
                        self.selectedAnswer = self.selectedAnswer + 1
                        
                        if not self.silent and self.settings.moveSelectionSoundEnabled then
                            SFX.play(self.settings.moveSelectionSound)
                        end
                    end

                    if self.selectedAnswer < answerPage.firstAnswerIndex then
                        self.state = STATE.SCROLL_ANSWERS
                        self.answersPageTarget = answerPageIndex - 1
                    elseif self.selectedAnswer > answerPage.firstAnswerIndex+(#answerPage.answers - 1) then
                        self.state = STATE.SCROLL_ANSWERS
                        self.answersPageTarget = answerPageIndex + 1
                    end
                end

                if player.rawKeys.jump == KEYS_PRESSED then
                    self:progress()
                end
            else
                if player.rawKeys.jump == KEYS_PRESSED then
                    self.typewriterLimit = characterCount
                    self.typewriterFinished = true
                    self.portraitTimer = 0
                end
            end
        end
    elseif self.state == STATE.SCROLL then
        local target = math.floor(self.page)+1

        self.page = math.min(target,self.page + self.settings.pageScrollSpeed)

        if self.page == target then
            self.state = STATE.STAY
        end
    elseif self.state == STATE.SCROLL_ANSWERS then
        local current = self.answersPageIndex[self.page]
        local target = self.answersPageTarget

        if current < target then
            self.answersPageIndex[self.page] = math.min(target,current + self.settings.pageScrollSpeed)
        elseif current > target then
            self.answersPageIndex[self.page] = math.max(target,current - self.settings.pageScrollSpeed)
        else
            self.state = STATE.STAY
        end
    elseif self.state == STATE.IN then
        self.openingProgress = math.min(1,self.openingProgress + self.settings.openSpeed)
        
        if self.openingProgress == 1 then
            self.state = STATE.STAY
        end
    elseif self.state == STATE.OUT then
        self.openingProgress = math.max(0,self.openingProgress - self.settings.openSpeed)

        if self.openingProgress == 0 then
            self.state = STATE.REMOVE

            if self.pauses then
                Misc.unpause()
            end
        end
    end

    -- Profile animation
    local portraitData = self.portraitData

    if portraitData ~= nil then
        if self.typewriterFinished or self.state ~= STATE.STAY then
            self.portraitFrame = (math.floor(self.portraitTimer / portraitData.idleFrameDelay) % portraitData.idleFrames)
        else
            self.portraitFrame = (math.floor(self.portraitTimer / portraitData.speakingFrameDelay) % portraitData.speakingFrames) + portraitData.idleFrames
        end

        self.portraitTimer = self.portraitTimer + 1
    end
end


local textBuffer = Graphics.CaptureBuffer(600,600)
local answerBuffer = Graphics.CaptureBuffer(600,600)

local function drawBufferDebug(buffer,priority,x,y,usedWidth,usedHeight)
    Graphics.drawBox{x = x,y = y,width = usedWidth,height = usedHeight,priority = priority,color = Color.black}

    Graphics.drawBox{x = x + usedWidth,y = y,width = buffer.width - usedWidth,height = usedHeight,color = Color.darkred}
    Graphics.drawBox{x = x,y = y + usedHeight,width = buffer.width,height = buffer.height - usedHeight,color = Color.darkred}

    Graphics.drawBox{texture = buffer,priority = priority,x = x,y = y}
end


local function drawAnswers(self,pageIndex,textX,mainTextY)
    answerBuffer:clear(self.priority)

    for answersPageIndex = math.floor(self.answersPageIndex[pageIndex]), math.ceil(self.answersPageIndex[pageIndex]) do
        local answerPage = self.answerPages[pageIndex][answersPageIndex]

        if answerPage ~= nil then
            local answerX = textX
            local answerY = math.floor((-(self.answersPageIndex[pageIndex] - 1) + (answersPageIndex - 1)) * (self.answersHeight + self.settings.answerGap))

            if self.settings.selectorImage ~= nil then
                answerX = answerX + self.settings.selectorImage.width
            end

            for answerIndex,answer in ipairs(answerPage.answers) do
                local totalIndex = (answerPage.firstAnswerIndex + (answerIndex - 1))
                local answerColor

                if pageIndex == self.page and totalIndex == self.selectedAnswer and self.typewriterFinished and self.state ~= STATE.SCROLL then
                    answerColor = self.settings.answerSelectedColor

                    if self.settings.selectorImage ~= nil then
                        Graphics.drawBox{
                            texture = self.settings.selectorImage,target = answerBuffer,priority = self.priority,
                            x = textX,y = answerY + answer.layout.height*0.5 - self.settings.selectorImage.height*0.5
                        }
                    end
                else
                    answerColor = self.settings.answerUnselectedColor
                end

                textplus.render{layout = answer.layout,x = answerX,y = answerY,color = answerColor,priority = self.priority,target = answerBuffer}

                answerY = answerY + answer.layout.height + self.settings.answerGap
            end
        end
    end

    -- Draw those answers to the text buffer
    local answersY = mainTextY + self.pageLayouts[pageIndex].height + self.settings.questionGap

    local answerPageCount = #self.answerPages[pageIndex]

    if answerPageCount > 1 and self.settings.arrowImage ~= nil then
        local offset = (math.floor(lunatime.drawtick()/32)%2)*2

        local iconX = self.mainWidth*0.5 - self.settings.arrowImage.width*0.5
        local iconHeight = self.settings.arrowImage.height

        local answerPageIndex = self.answersPageIndex[self.page]

        if math.floor(self.page) == self.page and math.floor(answerPageIndex) == answerPageIndex and self.typewriterFinished then
            if answerPageIndex > 1 then
                Graphics.drawBox{texture = self.settings.arrowImage,target = textBuffer,priority = self.priority,height = -iconHeight,x = iconX,y = answersY - offset + iconHeight}
            end

            if answerPageIndex < answerPageCount then
                Graphics.drawBox{texture = self.settings.arrowImage,target = textBuffer,priority = self.priority,x = iconX,y = answersY + self.answersHeight + iconHeight + offset}
            end
        end

        answersY = answersY + iconHeight
    end

    Graphics.drawBox{
        texture = answerBuffer,target = textBuffer,priority = self.priority,
        x = 0,y = answersY,width = self.mainWidth,height = self.answersHeight,
        sourceWidth = self.mainWidth,sourceHeight = self.answersHeight,
    }
end


local function drawMainBox(self,priority,sceneCoords,opacity,x,y,width,height,cutoffWidth,cutoffHeight)
    local image = self.settings.boxImage

    if image == nil then
        return
    end

    local vertexCoords = {}
    local textureCoords = {}

    local vertexCount = 0

    local segmentWidth = image.width / 3
    local segmentHeight = image.height / 3

    local segmentCountX = math.max(2,math.ceil(width / segmentWidth))
    local segmentCountY = math.max(2,math.ceil(height / segmentHeight))

    for segmentIndexX = 1, segmentCountX do
        for segmentIndexY = 1, segmentCountY do
            local thisX = x
            local thisY = y
            local thisWidth = math.min(width * 0.5,segmentWidth)
            local thisHeight = math.min(height * 0.5,segmentHeight)
            local thisSourceX = 0
            local thisSourceY = 0

            if segmentIndexX == segmentCountX then
                thisX = thisX + width - thisWidth
                thisSourceX = image.width - thisWidth
            elseif segmentIndexX > 1 then
                thisX = thisX + thisWidth + (segmentIndexX-2)*segmentWidth
                thisWidth = math.min(segmentWidth,width - segmentWidth - (thisX - x))
                thisSourceX = segmentWidth
            end

            if segmentIndexY == segmentCountY then
                thisY = thisY + height - thisHeight
                thisSourceY = image.height - thisHeight
            elseif segmentIndexY > 1 then
                thisY = thisY + thisHeight + (segmentIndexY-2)*segmentHeight
                thisHeight = math.min(segmentHeight,height - segmentHeight - (thisY - y))
                thisSourceY = segmentHeight
            end
            

            -- Handle cutoff
            if cutoffWidth ~= nil and cutoffHeight ~= nil then
                local cutoffLeft = x + width*0.5 - cutoffWidth*0.5
                local cutoffRight = cutoffLeft + cutoffWidth
                local cutoffTop = y + height*0.5 - cutoffHeight*0.5
                local cutoffBottom = cutoffTop + cutoffHeight

                -- Handle X
                local offset = math.max(0,cutoffLeft - thisX)

                thisWidth = thisWidth - offset
                thisSourceX = thisSourceX + offset
                thisX = thisX + offset

                thisWidth = math.min(thisWidth,cutoffRight - thisX)

                -- Handle Y
                local offset = math.max(0,cutoffTop - thisY)

                thisHeight = thisHeight - offset
                thisSourceY = thisSourceY + offset
                thisY = thisY + offset

                thisHeight = math.min(thisHeight,cutoffBottom - thisY)
            end

            -- Add vertices
            if thisWidth > 0 and thisHeight > 0 then
                local x1 = thisX
                local y1 = thisY
                local x2 = x1 + thisWidth
                local y2 = y1 + thisHeight

                vertexCoords[vertexCount+1 ] = x1 -- top left
                vertexCoords[vertexCount+2 ] = y1
                vertexCoords[vertexCount+3 ] = x1 -- bottom left
                vertexCoords[vertexCount+4 ] = y2
                vertexCoords[vertexCount+5 ] = x2 -- top right
                vertexCoords[vertexCount+6 ] = y1
                vertexCoords[vertexCount+7 ] = x1 -- bottom left
                vertexCoords[vertexCount+8 ] = y2
                vertexCoords[vertexCount+9 ] = x2 -- top right
                vertexCoords[vertexCount+10] = y1
                vertexCoords[vertexCount+11] = x2 -- bottom right
                vertexCoords[vertexCount+12] = y2

                local x1 = thisSourceX / image.width
                local y1 = thisSourceY / image.height
                local x2 = (thisSourceX + thisWidth) / image.width
                local y2 = (thisSourceY + thisHeight) / image.height

                textureCoords[vertexCount+1 ] = x1 -- top left
                textureCoords[vertexCount+2 ] = y1
                textureCoords[vertexCount+3 ] = x1 -- bottom left
                textureCoords[vertexCount+4 ] = y2
                textureCoords[vertexCount+5 ] = x2 -- top right
                textureCoords[vertexCount+6 ] = y1
                textureCoords[vertexCount+7 ] = x1 -- bottom left
                textureCoords[vertexCount+8 ] = y2
                textureCoords[vertexCount+9 ] = x2 -- top right
                textureCoords[vertexCount+10] = y1
                textureCoords[vertexCount+11] = x2 -- bottom right
                textureCoords[vertexCount+12] = y2

                vertexCount = vertexCount + 12
            end
        end
    end

    --Text.print(#vertexCoords,32,96)

    Graphics.glDraw{
        texture = image,
        priority = priority,
        color = Color.white.. opacity,
        sceneCoords = sceneCoords,
        vertexCoords = vertexCoords,
        textureCoords = textureCoords,
    }
end


function boxInstanceFunctions:draw()
    local obj = self.speakerObj
    if obj.isValid == false then
        obj = nil
    end
    
    local x,y = 0,0
    local sceneCoords = false

    if obj ~= nil then
        x = obj.x + self.settings.offsetFromSpeakerX
        y = obj.y + self.settings.offsetFromSpeakerY

        if obj.width ~= nil then
            x = x + obj.width*0.5
        end

        sceneCoords = true
    end

    y = y - self.totalHeight*0.5

    -- Apply bounds to make sure it's not off screen
    if self.keepOnScreen then
        local b = getBoundaries()

        x = math.clamp(x,b.left + self.totalWidth *0.5 + 16,b.right  - self.totalWidth *0.5 - 16)
        y = math.clamp(y,b.top  + self.totalHeight*0.5 + 16,b.bottom - self.totalHeight*0.5 - 16)
    end


    local scaleX  = math.lerp(self.settings.openStartScaleX ,1,self.openingProgress)
    local scaleY  = math.lerp(self.settings.openStartScaleY ,1,self.openingProgress)
    local opacity = math.lerp(self.settings.openStartOpacity,1,self.openingProgress)

    local boxWidth = self.totalWidth * scaleX
    local boxHeight = self.totalHeight * scaleY

    local boxCutoffWidth
    local boxCutoffHeight


    if self.settings.windowingOpeningEffectEnabled and self.openingProgress < 1 then
        local blackProgress = math.min(1,self.openingProgress*2)
        local mainProgress = math.max(0,self.openingProgress*2 - 1)

        scaleX  = math.lerp(self.settings.openStartScaleX ,1,blackProgress)
        scaleY  = math.lerp(self.settings.openStartScaleY ,1,blackProgress)
        opacity = math.lerp(self.settings.openStartOpacity,1,blackProgress)

        boxCutoffWidth  = math.lerp(self.settings.openStartScaleX,1,mainProgress) * self.totalWidth
        boxCutoffHeight = math.lerp(self.settings.openStartScaleY,1,mainProgress) * self.totalHeight

        boxWidth = self.totalWidth
        boxHeight = self.totalHeight

        Graphics.drawBox{
            color = Color.black.. opacity,sceneCoords = sceneCoords,priority = self.priority,centred = true,
            x = x,y = y,width = self.totalWidth * scaleX,height = self.totalHeight * scaleY,
        }
    end

    drawMainBox(self,self.priority,sceneCoords,opacity,x - boxWidth*0.5,y - boxHeight*0.5,boxWidth,boxHeight,boxCutoffWidth,boxCutoffHeight)


    if self.openingProgress >= 1 or self.settings.showTextWhileOpening then
        textBuffer:clear(self.priority)

        -- Character portrait
        local portraitData = self.portraitData
        local textX = 0

        if portraitData ~= nil and portraitData.image ~= nil then
            Graphics.drawBox{
                texture = portraitData.image,target = textBuffer,priority = self.priority,

                x = 0,y = 0,

                width = portraitData.width,height = portraitData.height,
                sourceWidth = portraitData.width,sourceHeight = portraitData.height,
                sourceX = 0,sourceY = self.portraitFrame * portraitData.height,
            }

            textX = textX + portraitData.width + self.settings.portraitGap
        end


        -- Text
        for index = math.floor(self.page), math.ceil(self.page) do
        --for index = math.floor(self.page), self.pages do
            local y = math.floor((-(self.page - 1) + (index - 1)) * self.mainHeight)
            local limit

            if self.settings.typewriterEnabled then
                if index > self.page then
                    limit = 0
                    --break
                elseif index == self.page and self.state ~= STATE.SCROLL then
                    limit = self.typewriterLimit
                end
            end

            textplus.render{layout = self.pageLayouts[index],limit = limit,x = textX,y = y,priority = self.priority,target = textBuffer}

            drawAnswers(self,index,textX,y)
        end


        -- Arrow
        if math.floor(self.page) == self.page and self.page < self.pages and #self.answerPages[self.page] == 0 and not self.uncontrollable and self.typewriterFinished and self.settings.arrowImage ~= nil then
            local offset = (math.floor(lunatime.drawtick()/32)%2)*2

            Graphics.drawBox{
                texture = self.settings.arrowImage,target = textBuffer,priority = self.priority,
                x = self.mainWidth - self.settings.arrowImage.width,y = self.mainHeight - self.settings.arrowImage.height + offset,
            }
        end


        local drawWidth  = math.max(0,self.totalWidth *scaleX - self.settings.borderSize*2)
        local drawHeight = math.max(0,self.totalHeight*scaleY - self.settings.borderSize*2)

        if boxCutoffWidth ~= nil then
            drawWidth = math.min(drawWidth,boxCutoffWidth)
        end
        if boxCutoffHeight ~= nil then
            drawHeight = math.min(drawHeight,boxCutoffHeight)
        end
        
        Graphics.drawBox{
            texture = textBuffer,priority = self.priority,
            sceneCoords = sceneCoords,centred = true,
            color = Color.white.. opacity,

            x = x,y = y,
            width = drawWidth,height = drawHeight,
            sourceWidth = drawWidth,sourceHeight = drawHeight,
            sourceX = self.mainWidth*0.5 - drawWidth*0.5,sourceY = self.mainHeight*0.5 - drawHeight*0.5,
        }


        --drawBufferDebug(textBuffer,self.priority,0,96,self.mainWidth,self.mainHeight)
        --drawBufferDebug(answerBuffer,self.priority,textBuffer.width,96,self.mainWidth,self.answersHeight)
    end
end



function littleDialogue.onTick()
    for k=#littleDialogue.boxes,1,-1 do
        local box = littleDialogue.boxes[k]

        if box.state ~= STATE.REMOVE then
            if not box.pauses then
                box:update()
            end
        else
            table.remove(littleDialogue.boxes,k)
            box.isValid = false
        end
    end
end

function littleDialogue.onDraw()
    for k=#littleDialogue.boxes,1,-1 do
        local box = littleDialogue.boxes[k]

        if box.state ~= STATE.REMOVE then
            if box.pauses then
                box:update()
            end

            box:draw()
        else
            table.remove(littleDialogue.boxes,k)
            box.isValid = false
        end
    end
end

function littleDialogue.onMessageBox(eventObj,text,playerObj,npcObj)
    littleDialogue.create{
        text = text,
        speakerObj = npcObj or playerObj or player,
    }

    eventObj.cancelled = true
end



littleDialogue.defaultBoxSettings = {
    -- Text formatting related
    textXScale = 2,          -- X scale of text.
    textYScale = 2,          -- Y scale of text.
    textMaxWidth = 384,      -- The maximum text width before it goes to a new line.
    textColor = Color.white, -- The tint of the text.

    
    -- Question related
    questionGap = 16, -- The gap between each a question and all of its answers.
    answerGap = 0,    -- The gap between each answer for a question.

    answerPageMaxHeight = 160, -- The maximum height of an answers list before it splits off into another page.

    answerUnselectedColor = Color.white,    -- The color of an answer when it's not being hovered over.
    answerSelectedColor = Color(1,1,0.25), -- The color of an answer when it is being hovered over.


    -- Typewriter effect related
    typewriterEnabled = false, -- If the typewriter effect is enabled.
    typewriterDelayNormal = 2, -- The usual delay between each character.
    typewriterDelayLong = 16,  -- The extended delay after any of the special delaying characters, listed below.
    typewriterSoundDelay = 5,  -- How long there must between each sound.

    typewriterDelayCharacters = table.map{string.byte("."),string.byte(","),string.byte("!"),string.byte("?")},


    -- Other
    borderSize = 8, -- How much is added around the text to get the full size (pixels).
    priority = 6,   -- The render priority of boxes.

    offsetFromSpeakerX = 0,   -- How horizontally far away the box is from the NPC saying it.
    offsetFromSpeakerY = -40, -- How vertically far away the box is from the NPC saying it.

    pageOffset = 0, -- How far away each text page is from each other.

    openSpeed = 0.05, -- How much the scale increases per frame while opening/closing.
    pageScrollSpeed = 0.05,

    portraitGap = 8,

    windowingOpeningEffectEnabled = false,
    showTextWhileOpening = false,

    openStartScaleX = 0,
    openStartScaleY = 0,
    openStartOpacity = 1,


    -- Sound effect related
    openSoundEnabled          = true, -- If a sound is played when the box opens.
    closeSoundEnabled         = true, -- If a sound is played when the box closes.
    scrollSoundEnabled        = true, -- If a sound is played when the box scrolls between pages.
    moveSelectionSoundEnabled = true, -- If a sound is played when the option selector moves.
    chooseAnswerSoundEnabled  = true, -- If a sound is played when an answer to a question is chosen.
    typewriterSoundEnabled    = true, -- If a sound is played when a letter appears with the typewriter effect.
}



-- Register each style.
littleDialogue.registerStyle("default",{
    
})

littleDialogue.registerStyle("yi",{
    borderSize = 32,

    openSpeed = 0.025,

    windowingOpeningEffectEnabled = true,
})


-- Default box style.
littleDialogue.defaultStyleName = "default"


return littleDialogue
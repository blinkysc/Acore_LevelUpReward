--
-- Created by IntelliJ IDEA.
-- User: Silvia
-- Date: 28/02/2021
-- Time: 23:16
-- To change this template use File | Settings | File Templates.
-- Originally created by Honey for Azerothcore
-- requires ElunaLua module

-- Updated By: Ragundah
-- Date: 13/05/2021

--Players will receive rewards when their characters reach the levels in brackets. 
------------------------------------------------------------------------------------------------
-- ADMIN GUIDE:  -  compile the core with ElunaLua module
--               -  adjust config in this file
--               -  create a character who appears as sender of the mails with senderGUID
--               -  add this script to ../lua_scripts/
------------------------------------------------------------------------------------------------


--
-- Modified version of LevelUpReward.lua
-- Added account-based bot detection

local Config_Gold = {}
local Config_ItemId = {}
local Config_ItemAmount = {}
local LUR_playerCounter = {}

-- [Previous config settings remain the same]
Config_Gold[10] = 10000
Config_Gold[20] = 70000
Config_Gold[30] = 180000
Config_Gold[40] = 350000
Config_Gold[50] = 650000
Config_Gold[61] = 600000
Config_Gold[65] = 800000
Config_Gold[71] = 1000000
Config_Gold[75] = 1800000
Config_Gold[80] = 5000000

-- [Previous item configs remain the same]
Config_ItemId[29] = 5740
Config_ItemAmount[29] = 5
-- [... other item configurations ...]

-- General Settings Config
local Config_mailText = 2
local Config_senderGUID = 10667
local Config_mailStationery = 41
local Config_maxGMRank = 0
local Config_preventReturn = true

-- Mail text configurations remain the same
local Config_mailSubject1 = "Chromies reward for You!"
local Config_mailText1 = "!\n\nYou've done well while advancing on ChromieCraft. Here is a small reward to celebrate your heroic deeds. Go forth!\n\nKind regards,\nChromie"
local Config_mailSubject2 = "Chromies reward for You!"
local Config_mailText2A = " and congratulations! \n\nThe bronze Dragonflight would like to inform you that you were the "
local Config_mailText2B = " adventurer to reach the "
local Config_mailText2C = " level of mastery.\nYour adventures have made me take notice of you, take this small reward as a token of my appreciation.\nGo forth!\n\nKind regards,\nChromie"

local Config_customDbName = 'ac_eluna'

-- Function to check if a player is a bot by checking account properties
local function IsPlayerBot(player)
    -- Get the account name for the player
    local accountId = player:GetAccountId()
    if not accountId then return false end
    
    -- Query the account table for the bot pattern
    local query = AuthDBQuery(string.format(
        "SELECT username FROM account WHERE id = %d AND username LIKE 'RNDBOT%%'",
        accountId
    ))
    
    -- If we found a match, this is a bot account
    if query then
        return true
    end
    
    return false
end

-- Database initialization
CharDBQuery('CREATE DATABASE IF NOT EXISTS `'..Config_customDbName..'`;')
CharDBQuery('CREATE TABLE IF NOT EXISTS `'..Config_customDbName..'`.`levelup_reward` (`level` INT NOT NULL, `counter` INT DEFAULT 0, PRIMARY KEY (`level`) );')

local n
for n = 2,80,1 do
    LUR_playerCounter[n] = 0
end

Data_SQL = CharDBQuery('SELECT `level`, `counter` FROM `'..Config_customDbName..'`.`levelup_reward`;')
if Data_SQL ~= nil then
    local levelRow
    repeat
        levelRow = Data_SQL:GetUInt32(0)
        LUR_playerCounter[levelRow] = Data_SQL:GetUInt32(1)
    until not Data_SQL:NextRow()
end

local PLAYER_EVENT_ON_LEVEL_CHANGE = 13

local function PreventReturn(playerGUID)
    if Config_preventReturn == true then
        CharDBExecute('UPDATE `mail` SET `messageType` = 3 WHERE `sender` = '..Config_senderGUID..' AND `receiver` = '..playerGUID..' AND `messageType` = 0;')
    end
end

local function GrantReward(event, player, oldLevel)
    -- Check if player is a bot using account information
    if IsPlayerBot(player) then
        -- Optionally log bot detection
        -- print(string.format("LevelUpReward: Skipping reward for bot account (character: %s)", player:GetName()))
        return false
    end
    
    -- Then proceed with the normal reward logic for real players
    if oldLevel ~= nil and player:GetGMRank() <= Config_maxGMRank then
        if Config_mailText == 1 then
            if Config_ItemId[oldLevel + 1] ~= nil then
                local playerName = player:GetName()
                local playerGUID = tostring(player:GetGUID())
                local itemAmount
                if Config_ItemAmount[oldLevel + 1] ~= nil then
                    itemAmount = Config_ItemAmount[oldLevel + 1]
                else
                    itemAmount = 1
                end
                if Config_Gold[oldLevel + 1] == nil then
                    Config_Gold[oldLevel + 1] = 0
                end
                SendMail(Config_mailSubject1, "Hello "..playerName..Config_mailText1, playerGUID, Config_senderGUID, Config_mailStationery, 0, Config_Gold[oldLevel + 1],0,Config_ItemId[oldLevel + 1], itemAmount)
                print("LevelUpReward has granted "..Config_Gold[oldLevel + 1].." copper and "..itemAmount.." of item "..Config_ItemId[oldLevel + 1].." to character "..playerName.." with guid "..playerGUID..".")
                PreventReturn(playerGUID)
                playerName = nil
                playerGUID = nil
                return false
            elseif Config_Gold[oldLevel + 1] ~= nil then
                local playerName = player:GetName()
                local playerGUID = tostring(player:GetGUID())
                SendMail(Config_mailSubject1, "Hello "..playerName..Config_mailText1, playerGUID, Config_senderGUID, Config_mailStationery, 0, Config_Gold[oldLevel + 1])
                print("LevelUpReward has granted "..Config_Gold[oldLevel + 1].." copper to character "..playerName.." with guid "..playerGUID..".")
                PreventReturn(playerGUID)
                playerName = nil
                playerGUID = nil
                return false
            end
        end

        -- [Rest of the original GrantReward function remains the same]
        local playerCounterStr
        local currentLevelStr
        local currentLevel = oldLevel + 1
        LUR_playerCounter[currentLevel] = LUR_playerCounter[currentLevel] + 1
        CharDBExecute('REPLACE INTO `'..Config_customDbName..'`.`levelup_reward` VALUES ('..currentLevel..', '..LUR_playerCounter[currentLevel]..');')
        
        -- [Mail sending logic remains the same...]
    end
end

RegisterPlayerEvent(PLAYER_EVENT_ON_LEVEL_CHANGE, GrantReward)


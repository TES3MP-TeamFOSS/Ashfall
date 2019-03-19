-- FossMail - Release 2 - For tes3mp 0.7.0

--For now, all items are displayed using their refIds. In the future, the itemData resource can be used to get the proper names to display.

-------------------
local config = {}

config.maxLength = 1234 --The "length" of characters a message is limited to. Because the way GUIs are currently set up in tes3mp, it's possible that a long message can push the close button off the end of the screen :P Not yet implemented because of some code weirdness

config.notificationColor = color.MediumSpringGreen --The color of the chat notification
config.messageSubjectColor = "#AD0DFF" --The color of the subject header in message view
config.messageToFromColor = "#D177FF" --The color of the to/from section in message view
config.messageTextColor = "#FFFFFF" --The color of the message text in message view
config.messageAttachmentsColor = "#A080FF" --The color of the attachments section in message view
config.mailBaseColor = color.Default --The base color the message display defaults to if something breaks horribly. Might not actually get used anywhere...

config.useReadColors = false --If true, the list of messages will use special colors for displaying read/unread messages. If enabled, the colors interfere with some of the GUI things, so you don't have feedback on what you are currently moused over/selected (because 0.6.1 limitations)
--These color choices suck, by the way :P
config.unreadColor = color.Violet
config.readColor = color.DarkViolet --The color for messages that have already been read

config.loginDisplayWhenZero = true --If set to true, the player will be notified on how many messages they have, even if they have 0

--GUI IDs. You will probably never have to edit these
config.mainGUI = 4055
config.composingGUI = 4056
config.composingSubjectGUI = 4057
config.composingTextGUI = 4058
config.composingRecipientGUI = 4059
config.composingItemAddGUI = 4060
config.composingItemAddNumberPrompt = 4061
config.sendErrorGUI = 4062
config.composingContinueGUI = 4063
config.viewListGUI = 4064
config.viewMessageGUI = 4065
config.viewMessageClaimGUI = 4066
config.deleteConfirmGUI = 4067
config.deleteConfirmAttachmentsGUI = 4068
config.composingItemRemoveGUI = 4069
config.composingItemRemoveNumberPrompt = 4070

-------------------
local FossMail = {}
local mailData = {messages = {}, mailId = 1}
local externalScripts = {}

local showMainGUI, showComposingGUI, showComposingSubject, showComposingText, showComposingRecipient, showComposingItemAdd, showComposingItemAddNumberPrompt, showSendError, showComposingContinue, showViewList, showViewMessage, showClaimNotify, showDeleteConfirm, showDeleteConfirmAttachments, showComposingItemRemove, showComposingItemRemoveNumberPrompt
-------------------

local function Save()
  jsonInterface.save("FossMail.json", mailData)
end

local function Load()
  mailData = jsonInterface.load("FossMail.json")
end

FossMail.OnServerPostInit = function()
   local file = io.open(tes3mp.GetModDir() .. "/FossMail.json", "r")
  if file ~= nil then
    io.close()
    Load()
  else
    Save()
  end
end

-------------------
local function getName(pid)
  return string.lower(Players[pid].accountName)
end

local function getLoginName(playerName)
  local player = logicHandler.GetPlayerByName(playerName)
  return player.data.login.name
end

local function addItem(playerName, refId, amount, charge) --playerName is the name of the player to add the item to (capitalization doesn't matter). refId is the refId of the item. amount is the amount of item to add (can be negative if you want to subtract items). charge is optional, denoting the item's charge.
  --Set the charge to default, if not provided
  local charge = charge or -1

  --Find the player
  local player = logicHandler.GetPlayerByName(playerName)

  --Check we found the player before proceeding
  if player then
    --Look through their inventory to find where an existing instance of the item is, if they have any
    local itemLoc = inventoryHelper.getItemIndex(player.data.inventory, refId, charge)

    --If they have the item in their inventory (with a matching charge), edit that item's data. Otherwise make some new data.
    if itemLoc then
      player.data.inventory[itemLoc].count = player.data.inventory[itemLoc].count + amount

      --If the total is now 0 or lower, remove the entry from the player's inventory.
      if player.data.inventory[itemLoc].count < 1 then
        player.data.inventory[itemLoc] = nil
      end
    else
      --Only create a new entry for the item if the amount is actually above 0, otherwise we'll have negative items.
      if amount > 0 then
        table.insert(player.data.inventory, {refId = refId, count = amount, charge = charge})
      end
    end

    --How we save the character is different depending on whether or not the player is online
    if player:IsLoggedIn() then
      --If the player is logged in, we have to update their inventory to reflect the changes
      player:Save()
      player:LoadInventory()
      player:LoadEquipment()
      player:LoadQuickKeys()
    else
      --If the player isn't logged in, we have to temporarily set the player's logged in variable to true, otherwise the Save function won't save the player's data
      player.loggedIn = true
      player:Save()
      player.loggedIn = false
    end

    return true
  else
    --Couldn't find any existing player with that name
    return false
  end
end

local function newNotify(playerName)
  local player = logicHandler.GetPlayerByName(playerName)

  --It's entirely possible that the player doesn't exist, or that they're not logged in.
  if player and player:IsLoggedIn() then
    tes3mp.SendMessage(player.pid, config.notificationColor .. "You've received a new message. Type /mail to view.\n" .. color.Default)
  end
end

local function loginNotify(pid)
  local messageCount = 0

  for _, mdata in pairs(mailData.messages) do
    if string.lower(mdata.target) == getName(pid) and mdata.deleted ~= true then
      messageCount = messageCount +1
    end
  end

  if config.loginDisplayWhenZero == true or messageCount > 0 then
    tes3mp.SendMessage(pid, config.notificationColor .. "You've have " .. messageCount .. " messages in your mailbox. Type /mail to view.\n" .. color.Default)
  end
end

local function getCharactersLength(text)
  local newLineAdd = 80 --The worst case scenario of how many extra characters a newline could add

  --Start off using a base of the length of the text
  local length = #text

  --For every newline, we assume the worst case scenario - that the newline has used up 80 characters-worth of space
  for newLine in string.gmatch(text, "\n") do
    length = length + newLineAdd - 2
  end

  return length
end


local function getFormattedMessage(mdata, mode)
  local text = config.mailBaseColor

  local subject
  if not mdata.subject or mdata.subject == "" then
    subject = "*No Subject*"
  else
    subject = mdata.subject
  end

  text = text .. config.messageSubjectColor .. "= " .. subject .. " =\n"

  if mode == "compose" then
    --To
    local to
    if not mdata.target or mdata.target == "" then
      to = "*No Recipient*"
    else
      to = mdata.target
    end

    text = text .. config.messageToFromColor .. "To: " .. to .. "\n\n"
  else --Assume mode is "view"
    --From
    text = text .. config.messageToFromColor .. "From: " .. mdata.sender .. "\n\n"
  end

  --Message
  local message
  if not mdata.message then
    message = ""
  else
    message = mdata.message
  end

  text = text .. config.messageTextColor .. message --Don't start a new line afterwards because this might be the end of the message

  --Attachments
  if mdata.attachments ~= nil and not tableHelper.isEmpty(mdata.attachments) then
    --Build a list of all the items attached. For now, charge data gets stripped
    local attachText = config.messageAttachmentsColor .. "\nAttachments"

    if mdata.unclaimed == true or mdata.unclaimed == nil then
      attachText = attachText .. ": "
    elseif mdata.unclaimed ~= nil then
      attachText = attachText .. " (Claimed): "
    end

    for index, adata in ipairs(mdata.attachments) do
      if adata.type == "item" then
        attachText = attachText .. adata.refId .. " x" .. adata.count
      elseif adata.type == "function" then
        attachText = attachText .. adata.text
      end

      if mdata.attachments[index+1] ~= nil then
        attachText = attachText .. ", "
      end
    end

    text = text .. attachText
  end

  return text
end


local function sendMailMessage(mdata)
  local newMessage = {}

  if mdata.generated ~= true then
    if not tableHelper.isEmpty(mdata.attachments) then
      --Note: Player-created messages should only ever have item attachments, so it's safe to assume that we'll only be working with item attachments
      local sendPlayer = logicHandler.GetPlayerByName(mdata.sender)
      local hasItems = true
      local hasEquipped = false --For equipment hack

      --Check that the player still has the correct items in their inventory at the recorded positions, and has enough of them. If they don't, then we should abort
      for index, item in ipairs(mdata.attachments) do
        if sendPlayer.data.inventory[item.slotId] and sendPlayer.data.inventory[item.slotId].refId == item.refId and sendPlayer.data.inventory[item.slotId].count >= item.count then
          --Everything is good
          --TODO: Determine less hacky way of doing the following:
          --Reject if the player has an item equipped sharing the same refId (because currently there's no easy way to tell if they're trying to send the item that they're wearing to remove it from their equipment)
          for k, eqitem in pairs(sendPlayer.data.equipment) do
            if eqitem.refId == item.refId then
              hasEquipped = true
              break
            end
          end
        else
          hasItems = false
          break
        end
      end

      if not hasItems then
        return false, "items"
      elseif hasEquipped then
        return false, "equipment"
      end

      --If we get here, that means that the player has all the items in their inventory.
      --That means we should remove them all...
      for index, item in ipairs(mdata.attachments) do
        sendPlayer.data.inventory[item.slotId].count = sendPlayer.data.inventory[item.slotId].count - item.count
        -- If the item count is now 0 (or somehow less). remove the entry from the player's inventory
        if sendPlayer.data.inventory[item.slotId].count < 1 then
          sendPlayer.data.inventory[item.slotId] = nil
        end
      end

      sendPlayer:Save()
      sendPlayer:LoadInventory()
      sendPlayer:LoadEquipment()
      sendPlayer:LoadQuickKeys()
    end
  end

  newMessage.attachments = mdata.attachments

  --Add the flag to the message data denoting that the attachments are unclaimed, if there are any
  if not tableHelper.isEmpty(mdata.attachments) then
    newMessage.unclaimed = true
  end

  --Construct the message data
  newMessage.id = mailData.mailId
  mailData.mailId = mailData.mailId + 1

  newMessage.subject = mdata.subject
  newMessage.target = mdata.target
  newMessage.message = mdata.message
  newMessage.sender = mdata.sender

  newMessage.generated = mdata.generated

  newMessage.read = false
  newMessage.deleted = false

  --Save the message to message data
  mailData.messages[newMessage.id] = newMessage
  Save()
  --Try to notify the recipient that they've got new mail
  newNotify(newMessage.target)
  return true
end

--Makes a nicely formatted entry for displaying the message on the message list
local function getMailTitle(mailId)
  local mdata = mailData.messages[mailId]
  local out = ""

  --Read/Unread indicators
  local mcolor = ""
  local last = ""
  if config.useReadColors then
    --Determine the color to use
    if mdata.read == true then
      mcolor = config.readColor
    else
      mcolor = config.unreadColor
    end

    --last = color.Default
  else
    if mdata.read == true then
      last = " (Read)"
    else
      --Don't think we need an indicator for unread
    end
  end

  out = out .. mcolor .. mdata.subject .. " - From " .. mdata.sender .. last

  return out
end

local function claimAttachments(pid, mdata)
  for _, adata in ipairs(mdata.attachments) do
    if adata.type == "item" then
      addItem(getName(pid), adata.refId, adata.count, adata.charge)
    elseif adata.type == "function" then
      externalScripts[adata.scriptName][adata.funcName](pid, mdata, adata.args)
    end
  end

  --Update the mail's data so the items can't be claimed again
  mdata.unclaimed = false
  Save()
end

local function deleteMailMessage(mdata)
  --For now, messages are just "deleted" by editing a flag, rather than actually deleting the data :P
  mdata.deleted = true
  Save()
end

local function getPlayerMailCount(pname, mode)
 local messageCount = 0

 for _, mdata in pairs(mailData.messages) do
   if string.lower(mdata.target) == string.lower(pname) and mdata.deleted ~= true then
     if mode == "any" then
	  messageCount = messageCount +1
	 elseif mode == "unread" and mdata.read ~= true then
	  messageCount = messageCount +1
	 elseif mode == "read" and mdata.read == true then
	  messageCount = messageCount +1
	 end
   end
 end

 return messageCount
end
-------------------
local composing = {}
local itemsList = {}
local selectedItem = {}
local mailIdList = {}
local selectedMessage = {}
local selectedAttachmentIndex = {}

local function attachItem(pid, idata, count)
  --Check the item from that slot ID isn't already attached to the message
  local alreadyAttached = false
  for index, aitem in ipairs(composing[getName(pid)].attachments) do
    if aitem.slotId == idata.slotId then
      alreadyAttached = index
      break
    end
  end

  --If the item is already attached, adjust its count to the new one. Otherwise, make a new entry for it
  if alreadyAttached then
    composing[getName(pid)].attachments[alreadyAttached].count = count
  else
    local item = {}
    item.slotId = idata.slotId
    item.refId = idata.refId
    item.count = count
    item.charge = idata.charge
    item.type = "item"

    table.insert(composing[getName(pid)].attachments, item)
  end
end

showSendError = function(pid, reason)
  local message = "The message couldn't be sent: "
  if reason == "target" then
    message = message .. "please enter a recipient."
  elseif reason == "not exist" then
    message = message .. "no player with that name exists."
  elseif reason == "send self" then
    message = message .. "you can't send a message to yourself!"
  elseif reason == "items" then
    message = message .. "you don't have all the items that you tried to attach in your inventory. All the attachments have been removed."
    composing[getName(pid)].attachments = {}
  elseif reason == "equipment" then
    message = message .. "you can't send items of the same type that you currently have equipped - sorry!"
  end

  return tes3mp.MessageBox(pid, config.sendErrorGUI, message)
end

showComposingItemRemoveNumberPrompt = function(pid)
  local message = "How many would you like to remove?"

  return tes3mp.InputDialog(pid, config.composingItemRemoveNumberPrompt, "Remove", message)
end

local function onComposingItemRemoveNumberPrompt(pid, count)
  local adata = composing[getName(pid)].attachments[selectedAttachmentIndex[getName(pid)]]

  adata.count = adata.count - math.min(math.max(count, 1), adata.count)

  if adata.count < 1 then
    table.remove(composing[getName(pid)].attachments, selectedAttachmentIndex[getName(pid)])
  end

  return showComposingGUI(pid)
end

showComposingItemRemove = function(pid)
  local message = "Select an attachment to remove."

  --Generate a list of options
  local options = composing[getName(pid)].attachments
  local list = "* CLOSE *\n"

  for i=1, #options do
    list = list .. options[i].refId .. " (x" .. options[i].count .. ")"
    if not (i == #options) then
      list = list .. "\n"
    end
  end

  return tes3mp.ListBox(pid, config.composingItemRemoveGUI, message, list)
end

local function onComposingItemRemoveSelect(pid, index)
  selectedAttachmentIndex[getName(pid)] = index

  if composing[getName(pid)].attachments[index].count > 1 then
    showComposingItemRemoveNumberPrompt(pid)
  else
    return table.remove(composing[getName(pid)].attachments, index), showComposingGUI(pid)
  end
end

showComposingItemAddNumberPrompt = function(pid)
  local message = "How many would you like to add?"

  return tes3mp.InputDialog(pid, config.composingItemAddNumberPrompt, "Add", message)
end

local function onComposingItemAddNumberPrompt(pid, count)
  local item = selectedItem[getName(pid)]

  return attachItem(pid, item, math.min(math.max(count, 1), item.count)), showComposingGUI(pid) --Makes the minimum 1, and the maximum the amount they have of the item.
end

showComposingItemAdd = function(pid)
  local message = "Select an item from your inventory to attach."
  --Generate a list of options
  local options = {}
  local list = "* CLOSE *\n"
  local pinv = Players[pid].data.inventory

  for slotId, idata in pairs(pinv) do
    local addition = {slotId = slotId, refId = idata.refId, count = idata.count, charge = idata.charge}
    table.insert(options, addition)
  end
  for i=1, #options do
    list = list .. options[i].refId .. " (x" .. options[i].count .. ")"
    if not (i == #options) then
      list = list .. "\n"
    end
  end

  itemsList[getName(pid)] = options

  return tes3mp.ListBox(pid, config.composingItemAddGUI, message, list)
end

local function onComposingItemAddSelect(pid, index)
  selectedItem[getName(pid)] = itemsList[getName(pid)][index]

  if selectedItem[getName(pid)].count > 1 then
    return showComposingItemAddNumberPrompt(pid)
  else
    return attachItem(pid, selectedItem[getName(pid)], 1), showComposingGUI(pid)
  end
end

showComposingRecipient = function(pid)
  local message = "Enter the player's name."

  return tes3mp.InputDialog(pid, config.composingRecipientGUI, "Enter Player Name", message)
end

local function onComposingRecipientPrompt(pid, data)
  if data == nil or data == "" then
    composing[getName(pid)].target = ""
  else
    composing[getName(pid)].target = data
  end
  return showComposingGUI(pid)
end

showComposingText = function(pid)
  local message = "Enter the message." --Ruled to not inform players that \n starts a newline :P

  return tes3mp.InputDialog(pid, config.composingTextGUI, "Message", message)
end

local function onComposingTextPrompt(pid, data)
  --TODO: Ensure text isn't over the maximum character limit
  if data == nil or data == "" then
    composing[getName(pid)].message = ""
  else
    composing[getName(pid)].message = data
  end
  return showComposingGUI(pid)
end

showComposingSubject = function(pid)
  local message = "Enter a subject."

  return tes3mp.InputDialog(pid, config.composingSubjectGUI, "Subject", message)
end

local function onComposingSubjectPrompt(pid, data)
  if data == nil or data == "" then
    composing[getName(pid)].subject = ""
  else
    composing[getName(pid)].subject = data
  end
  return showComposingGUI(pid)
end

showComposingGUI = function(pid)
  --local message = "Here are some instructions on how stuff works. Hey look - a preview!\n\n" --Probably clear enough to not need any instructions?

  local message = getFormattedMessage(composing[getName(pid)], "compose")

  return tes3mp.CustomMessageBox(pid, config.composingGUI, message, "Set Subject;Set Recipient;Set Text;Add Item Attachment;Remove Attachment;Send;Close")
end

local function onComposingSubject(pid)
  return showComposingSubject(pid)
end

local function onComposingText(pid)
  return showComposingText(pid)
end

local function onComposingRecipient(pid)
  return showComposingRecipient(pid)
end

local function onComposingItemAdd(pid)
  return showComposingItemAdd(pid)
end

local function onComposingItemRemove(pid)
  return showComposingItemRemove(pid)
end

local function onComposingSend(pid)
  local mdata = composing[getName(pid)]

  --Make checks to make sure that all the required data is there
  if not mdata.target or mdata.target == "" then
    return showSendError(pid, "target")
  elseif not mdata.subject or mdata.subject == "" then
    --We won't force the player to enter a subject, so if they've left it blank we'll just make it "No Subject"
    mdata.subject = "No Subject"
  end

  --Make checks to make sure that all the data is valid
  if logicHandler.GetPlayerByName(mdata.target) == nil then --The target player doesn't exist
    return showSendError(pid, "not exist")
  elseif getLoginName(mdata.target) == getLoginName(getName(pid)) then
    --Player shouldn't be allowed to send messages to themselves!
    return showSendError(pid, "send self")
  end

  --Add additional data before sending it off
  mdata.sender = getLoginName(getName(pid))
  mdata.generated = false

  local success, reason = sendMailMessage(mdata)

  if success then
    composing[getName(pid)] = nil
    return tes3mp.MessageBox(pid, -1, "Message Sent!")
  else
    return showSendError(pid, reason)
  end
end

showComposingContinue = function(pid)
  local message = "It looks like you were in the middle of writing a message. Would you like to continue that one, or start a new one?"

  return tes3mp.CustomMessageBox(pid, config.composingContinueGUI, message, "Continue;Start New")
end

local function onComposingContinueContinue(pid) --Well that's not a confusing name :P
  return showComposingGUI(pid)
end

local function onComposingContinueNew(pid)
  --Do setup for the data we'll need to display during composition
  composing[getName(pid)] = {}
  composing[getName(pid)].subject = ""
  composing[getName(pid)].target = ""
  composing[getName(pid)].message = ""
  composing[getName(pid)].attachments = {}
  return showComposingGUI(pid)
end

showClaimNotify = function(pid, reason)
  local message

  if reason == "success" then
    message = "Attachments have successfully been claimed."
  elseif reason == "no attachments" then
    message = "There are no attachments to claim."
  elseif reason == "already claimed" then
    message = "You've already claimed the attachments for this message."
  end

  return tes3mp.MessageBox(pid, config.viewMessageClaimGUI, message)
end

local function onClaimNotifySelect(pid)
  return showViewMessage(pid)
end

showViewMessage = function(pid)
  --Set the message as read
  selectedMessage[getName(pid)].read = true
  Save()

  --local message = "Here are some instructions on how stuff works. Hey look - a message! \n\n" --I've decided that the interface is clear enough that it probably doesn't actually need instructions

  local message = getFormattedMessage(selectedMessage[getName(pid)], "view")

  return tes3mp.CustomMessageBox(pid, config.viewMessageGUI, message, "Claim Items;Send Reply;Delete;Close")
end

local function onViewMessageClaim(pid)
  if tableHelper.isEmpty(selectedMessage[getName(pid)].attachments) then
    --There aren't any attachments to claim...
    return showClaimNotify(pid, "no attachments")
  else
    if selectedMessage[getName(pid)].unclaimed == true then
      claimAttachments(pid, selectedMessage[getName(pid)])
      return showClaimNotify(pid, "success")
    else
      --The attachments have already been claimed...
      return showClaimNotify(pid, "already claimed")
    end
  end
end

local function onViewMessageReply(pid)
  --Do special setup for the data we'll need to display during composition
  composing[getName(pid)] = {}
  composing[getName(pid)].subject = "RE: " .. selectedMessage[getName(pid)].subject
  composing[getName(pid)].target = selectedMessage[getName(pid)].sender
  composing[getName(pid)].message = ""
  composing[getName(pid)].attachments = {}
  return showComposingGUI(pid)
end

showDeleteConfirmAttachments = function(pid)
  local message = "The message you're about to delete contains unclaimed attachments, are you sure you want to proceed?"

  return tes3mp.CustomMessageBox(pid, config.deleteConfirmAttachmentsGUI, message, "Claim and Delete;Delete Anyway;Cancel")
end

local function onDeleteConfirmAttachmentsClaim(pid)
  claimAttachments(pid, selectedMessage[getName(pid)])
  deleteMailMessage(selectedMessage[getName(pid)])
  return showViewList(pid)
end

local function onDeleteConfirmAttachmentsDelete(pid)
  deleteMailMessage(selectedMessage[getName(pid)])
  return showViewList(pid)
end

showDeleteConfirm = function(pid)
  local message = "Are you sure you want to delete this message?"

  return tes3mp.CustomMessageBox(pid, config.deleteConfirmGUI, message, "Delete;Cancel")
end

local function onDeleteConfirmDelete(pid)
  deleteMailMessage(selectedMessage[getName(pid)])
  return showViewList(pid)
end

local function onViewMessageDelete(pid)
  --Do checks to make sure that there aren't unclaimed items.
  if selectedMessage[getName(pid)].unclaimed == true then
    return showDeleteConfirmAttachments(pid)
  else
    return showDeleteConfirm(pid)
  end
end

showViewList = function(pid)
  local message = "Here are all the messages you've received. Select one to open it."

  --K, this is going to be a little bit messy. Ultimately what we want is to have a list of all the player's messages, but these need to be sorted by: Most recent unread to least recent unread, followed by most recent read to least recent read.
  local ultimateSorted = {} --This table will ultimately contain the keys in an indexed format, sorted as we want it.
  local unreadMessages = {} --Unsorted messages that are unread. Added to below
  local readMessages = {} --Unsorted message that are read. Added to below
  --We begin by going through all the messages...
  for mailId, mdata in pairs(mailData.messages) do
    if string.lower(mdata.target) == getName(pid) and mdata.deleted ~= true then --We only want to deal with non-deleted messages that are addressed to the player
      --Now we sort the messages into read/unread...
      if mdata.read then
        table.insert(readMessages, mailId)
      else
        table.insert(unreadMessages, mailId)
      end
    end
  end

  --We'll need this in just a minute. It'll be used to sort the tables from highest to lowest
  local function highToLowSort(a,b) return a>b end

  --Now, we sort the indexed tables containing the mail IDs by the mail IDs, from highest first to lowest...
  table.sort(unreadMessages, highToLowSort)
  --And for readMessages too...
  table.sort(readMessages, highToLowSort)

  --Finally, we go through both the now sorted tables and add them to the ultimateSorted table...
  for _, mailId in ipairs(unreadMessages) do
    table.insert(ultimateSorted, mailId)
  end
  for _, mailId in ipairs(readMessages) do
    table.insert(ultimateSorted, mailId)
  end

  --Generate a list of options
  local options = {}
  local list = "* CLOSE *\n"

  for _, mailId in ipairs(ultimateSorted) do
    table.insert(options, mailId)
  end
  for i=1, #options do
    list = list .. getMailTitle(options[i])
    if not (i == #options) then
      list = list .. "\n"
    end
  end

  mailIdList[getName(pid)] = options

  return tes3mp.ListBox(pid, config.viewListGUI, message, list)
end

local function onViewListSelect(pid, index)
  selectedMessage[getName(pid)] = mailData.messages[mailIdList[getName(pid)][index]]
  return showViewMessage(pid)
end

showMainGUI = function(pid)
  local message = "Welcome to your mailbox, you have " .. getPlayerMailCount(getName(pid), "unread") .. " unread messages in your inbox (" .. getPlayerMailCount(getName(pid), "any") .. " total). What would you like to do?"

  return tes3mp.CustomMessageBox(pid, config.mainGUI, message, "View Messages;Compose;Close")
end

local function onMainView(pid)
  return showViewList(pid)
end

local function onMainCompose(pid)
  if composing[getName(pid)] ~= nil and not tableHelper.isEmpty(composing[getName(pid)]) then
    return showComposingContinue(pid)
  else
    --Do setup for the data we'll need to display during composition
    composing[getName(pid)] = {}
    composing[getName(pid)].subject = ""
    composing[getName(pid)].target = ""
    composing[getName(pid)].message = ""
    composing[getName(pid)].attachments = {}
    return showComposingGUI(pid)
  end
end

FossMail.OnGUIAction = function(eventStatus, pid, idGui, data)
  if idGui == config.mainGUI then --Main GUI
    if tonumber(data) == 0 then --View Messages
      onMainView(pid)
    elseif tonumber(data) == 1 then --Compose
      onMainCompose(pid)
    else --Close
      --Do Nothing
    end


  elseif idGui == config.composingGUI then -- Composing: Main GUI
     if tonumber(data) == 0 then -- Set Subject
      onComposingSubject(pid)
    elseif tonumber(data) == 1 then -- Set Recipient
      onComposingRecipient(pid)
    elseif tonumber(data) == 2 then -- Set Text
      onComposingText(pid)
    elseif tonumber(data) == 3 then -- Add Item Attachment
      onComposingItemAdd(pid)
    elseif tonumber(data) == 4 then -- Remove Item Attachment
      onComposingItemRemove(pid)
    elseif tonumber(data) == 5 then -- Send
      onComposingSend(pid)
    else --Close
      --Do Nothing
    end
  elseif idGui == config.composingSubjectGUI then -- Composing: Subject Prompt
    onComposingSubjectPrompt(pid, data)
  elseif idGui == config.composingTextGUI then -- Composing: Text Prompt
    onComposingTextPrompt(pid, data)
  elseif idGui == config.composingRecipientGUI then -- Composing: Recipient Prompt
    onComposingRecipientPrompt(pid, data)
  elseif idGui == config.composingItemAddGUI then -- Composing: Add Item List
    if tonumber(data) == 0 or tonumber(data) == 18446744073709551615 then --Close/Nothing Selected
      --Do nothing
      showComposingGUI(pid)
    else
      onComposingItemAddSelect(pid, tonumber(data))
    end
  elseif idGui == config.composingItemAddNumberPrompt then -- Composing: Add Item Count Prompt
    if tonumber(data) ~= nil then --Valid number entered
      onComposingItemAddNumberPrompt(pid, tonumber(data))
    else
       showComposingItemAddNumberPrompt(pid) --Prompt again until a valid number is entered
    end
  elseif idGui == config.sendErrorGUI then -- Sending Error GUI
     showComposingGUI(pid)
  elseif idGui == config.composingContinueGUI then -- Confirm Continue Message GUI
    if tonumber(data) == 0 then -- Continue Message
      onComposingContinueContinue(pid)
    else -- New Message
      onComposingContinueNew(pid)
    end
  elseif idGui == config.viewListGUI then -- View List
    if tonumber(data) == 0 or tonumber(data) == 18446744073709551615 then --Close/Nothing Selected
      --Do nothing
       showMainGUI(pid)
    else
      onViewListSelect(pid, tonumber(data))
    end
  elseif idGui == config.viewMessageGUI then -- View Message
    if tonumber(data) == 0 then --Claim
      onViewMessageClaim(pid)
    elseif tonumber(data) == 1 then --Reply
      onViewMessageReply(pid)
    elseif tonumber(data) == 2 then --Delete
      onViewMessageDelete(pid)
    else --Close
      --Do nothing
      showViewList(pid)
    end
  elseif idGui == config.viewMessageClaimGUI then -- Claim Notification
    onClaimNotifySelect(pid)
  elseif idGui == config.deleteConfirmGUI then -- View Message: Regular Delete Confirm
    if tonumber(data) == 0 then --Delete
      onDeleteConfirmDelete(pid)
    else --Cancel
      showViewMessage(pid)
    end
  elseif idGui == config.deleteConfirmAttachmentsGUI then -- View Message: Attachments Delete Confirm
    if tonumber(data) == 0 then --Claim and Delete
      onDeleteConfirmAttachmentsClaim(pid)
    elseif tonumber(data) == 1 then --Delete Anyway
      onDeleteConfirmAttachmentsDelete(pid)
    else --Cancel
      showViewMessage(pid)
    end
  elseif idGui == config.composingItemRemoveGUI then -- Composing: Remove Attachment List
    if tonumber(data) == 0 or tonumber(data) == 18446744073709551615 then --Close/Nothing Selected
      --Do nothing
       showComposingGUI(pid)
    else
      onComposingItemRemoveSelect(pid, tonumber(data))
    end
  elseif idGui == config.composingItemRemoveNumberPrompt then -- Composing: Remove Attachment Number Prompt
    if tonumber(data) ~= nil then --Valid number entered
       onComposingItemRemoveNumberPrompt(pid, tonumber(data))
    else
       showComposingItemRemoveNumberPrompt(pid) --Prompt again until a valid number is entered
    end
  end
end

-------------------
FossMail.Save = function()
  return Save()
end

FossMail.Load = function()
  return Load()
end

FossMail.OnCommand = function(pid, args)
  showMainGUI(pid)
end

FossMail.OnPlayerConnect = function(eventStatus, pid)
  return loginNotify(pid)
end

--Used for outside scripts registering special attachments. They should be registered every time the server launches, as the functions aren't stored anywhere.
FossMail.RegisterFunction = function(scriptName, funcName, func)
  if externalScripts[scriptName] == nil then
    externalScripts[scriptName] = {}
  end

  externalScripts[scriptName][funcName] = func
end

--Used for outside scripts for sending messages. The message data should be properly formatted as outlined in the readme.
FossMail.SendMessage = function(messageData)
  return sendMailMessage(messageData)
end

customCommandHooks.registerCommand("mail", FossMail.OnCommand)
customEventHooks.registerHandler("OnGUIAction", FossMail.OnGUIAction)
customEventHooks.registerHandler("OnPlayerConnect", FossMail.OnPlayerConnect)
customEventHooks.registerHandler("OnServerpostinit", FossMail.OnServerpostinit)

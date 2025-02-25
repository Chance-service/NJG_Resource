local BaseDataHelper = require("BaseDataHelper")
--local MainConfig = require("Mail.MailConfig")
local Mail_pb = require("Mail_pb");
local HP = require("HP_pb");


local MailDataHelper = BaseDataHelper:new()
MailDataHelper.mailInvalidateList = {}
MailDataHelper.mailAreanAll = {}
MailDataHelper.mails = {}
MailDataHelper.commonMails = {}
MailDataHelper.systemMails = {}
MailDataHelper.lastMail = {}
MailDataHelper.requestId = 0
MailDataHelper.SystemMail = {}
MailDataHelper.newCommonMail = false
MailDataHelper.newSystemMail = false

MailDataHelper.mailArenaHasGotIds = {}

function MailDataHelper:onReceiveMailPacket(eventName,handler)
    if eventName == "luaReceivePacket" then
	    local msg = Mail_pb.OPMailInfoRet()
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)
        local nCurMails = #MailDataHelper.mails--接收数据包前的邮件个数
        local nFinalMails = 0;--接收数据包后的邮件个数
	    if msg~=nil then
		    local maxSize = table.maxn(msg.mails);
		    if maxSize > 0 then
			    self.lastMail = msg.mails[maxSize]
		    end
		    for i=1,maxSize,1 do
			    local mail = msg.mails[i];
			    local mailId = mail.id;
				local isMonthMail = false
				if mail.mailId == 7 then
					isMonthMail = true
				end
			    if self.mailInvalidateList[mailId] ~=nil and not isMonthMail then--月卡的邮件需要重新刷新
				    CCLuaLog("already in the list");
			    else					
				    self.mailInvalidateList[mailId] = true
					local function addMonthCard(tab,newMail)
						for index,mail in pairs(tab) do
							if mail.mailId == 7 and mail.id == newMail.id then
								tab[index] = newMail
								return true
							end
						end
					end
				    if mail.type == Mail_pb.ARENA_ALL then
					    table.insert(self.mailAreanAll , mail)
					    if mail.mailId == 10 then--竞技场被打的记录
							table.insert(self.mails , mail)
						end
				    else
						if mail.mailId == 7 then
							if not addMonthCard(self.mails,mail) then
								table.insert(self.mails , mail)
							end
						else
							table.insert(self.mails , mail)
						end
					    if mail:HasField("mailClassify") then
						    --if mail.mailClassify == 2 then
                            --    MailDataHelper.newSystemMail = true
                            --    RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.MAIL_SYSTEM_TAB, 1, true)
                            --else
                            --    MailDataHelper.newCommonMail = true
                            --    RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.MAIL_NORMAL_TAB, 1, true)
                            --end
					    end
				    end
			    end
		    end
		    table.sort(MailDataHelper.mails,
		    function ( e1, e2 )			
			    if not e2 then return true end
			    if not e1 then return false end
			    if e1.type == Mail_pb.Reward and e2.type ~= Mail_pb.Reward then return true end
			    if e1.type ~= Mail_pb.Reward and e2.type == Mail_pb.Reward then return false end
			    if e1.type == Mail_pb.Reward and e2.type == Mail_pb.Reward then 
				    --mailId = 7 为月卡
				    if e1.mailId == 7 and e2.mailId ~= 7 then return true end 
				    if e1.mailId ~= 7 and e2.mailId == 7 then return false end
				    return e1.id + 0 > e2.id + 0
			    end
			    return e1.id + 0 > e2.id + 0
		    end
		    );
			
		    -- new mail notice
		    if maxSize > 0 then
                nFinalMails = #MailDataHelper.mails
                if nFinalMails ~= nCurMails then
                    local msg = MsgMainFrameGetNewInfo:new()
			        msg.type = Const_pb.NEW_MAIL;
			        MessageManager:getInstance():sendMessageForScript(msg)
                end
			    local msg = MsgMainFrameRefreshPage:new()
			    msg.pageName = "MailPage";
			    MessageManager:getInstance():sendMessageForScript(msg)
				
			    local msg1 = MsgMainFrameRefreshPage:new()
			    msg1.pageName = "ArenaRecordPage";
			    MessageManager:getInstance():sendMessageForScript(msg1)
		    end
	    end						

	    self:RefreshMail()
    end
end

function MailDataHelper:RefreshMail()
    self.commonMails = {}
    self.systemMails = {}
    for i=1,#self.mails do
        local mail = self.mails[i]
        if mail:HasField("mailClassify") then
            if mail.mailClassify == 2 then
                table.insert(self.systemMails , mail)
            else
                table.insert(self.commonMails , mail)
            end
        end
    end
    if #self.systemMails > 0 then
        RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.MAIL_SYSTEM_TAB, 1, true)
    else
        RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.MAIL_SYSTEM_TAB, 1, false)
    end
    if #self.commonMails > 0 then
        RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.MAIL_NORMAL_TAB, 1, true)
    else
        RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.MAIL_NORMAL_TAB, 1, false)
    end
end


function MailDataHelper:ResetMailData()
    self.mailInvalidateList = {}
    self.mailAreanAll = {}
    self.mails = {}
    self.lastMail = {}
    self.requestId = 0
    self.mailArenaHasGotIds = {}
end

function MailDataHelper:onReceiveMailGetInfo( msg)
    local type = 1
    if msg:HasField("mailClassify") then
        if msg.mailClassify==1 then
            type = 1
        else
            type = 2
        end
    end
    
    if msg:HasField("type") and msg.type~=0 then
        if msg.type == 1 then
            local i = 1
            while i <= #MailDataHelper:getVariableByKey("mails") do
                local mail = MailDataHelper:getVariableByKeyAndIndex("mails",i);
                if mail~=nil and mail.type ~= Mail_pb.Reward and mail.mailClassify==type and mail.mailId ~= 106 then
                    table.remove(MailDataHelper:getVariableByKey("mails"), i);
                    MailDataHelper:removeVariableByKey("mailInvalidateList",i)
                else
                    i = i+1
                end
            end
        elseif msg.type == 2 then
            local i = 1
            while i <= #MailDataHelper:getVariableByKey("mails") do
                local mail = MailDataHelper:getVariableByKeyAndIndex("mails",i);
                if mail~=nil and mail.type == Mail_pb.Reward and mail.mailClassify==type then
                    table.remove(MailDataHelper:getVariableByKey("mails"), i);
                    MailDataHelper:removeVariableByKey("mailInvalidateList",i)
                else
                    i = i+1
                end
            end
        end
    else
        local deleteId = msg.id;

        local maxSize = table.maxn(MailDataHelper:getVariableByKey("mails"));

        local deleteIndex = 0;
        local count = 1;

        for i =1, maxSize, 1 do
            local mail = MailDataHelper:getVariableByKeyAndIndex("mails",i);

            if mail.id == deleteId then
                deleteIndex = i;
            end
        end

        table.remove(MailDataHelper:getVariableByKey("mails"), deleteIndex);
        MailDataHelper:removeVariableByKey("mailInvalidateList",deleteId)
    end
    --table.remove(MailDataHelper:mailInvalidateList , deleteId)
    MailDataHelper:RefreshMail()
end

function MailDataHelper:removeMailById(id)
	local deleteId = id;

	local maxSize = table.maxn(MailDataHelper:getVariableByKey("mails"));

	local deleteIndex = 0;
	local count = 1;

	for i =1, maxSize, 1 do
		local mail = MailDataHelper:getVariableByKeyAndIndex("mails",i);

		if mail.id == deleteId then
			deleteIndex = i;
		end
	end

	table.remove(MailDataHelper:getVariableByKey("mails"), deleteIndex);
	MailDataHelper:removeVariableByKey("mailInvalidateList",deleteId)
	
	MailDataHelper:RefreshMail()
end

function MailDataHelper:sendClosesNewInfoMessage()
    local GameConfig = require("GameConfig")
	local msg = MsgMainFrameGetNewInfo:new()
	msg.type = GameConfig.NewPointType.TYPE_MAIL_CLOSE;
	MessageManager:getInstance():sendMessageForScript(msg)
end

return MailDataHelper
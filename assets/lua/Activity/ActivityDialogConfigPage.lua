local ActivityDialogConfig = require("Activity.ActivityDialogConfig");
local NodeHelper = require("NodeHelper");
local GuideManager = require("Guide.GuideManager")
local thisPageName = "ActivityDialogConfigPage"
local m_NowId = nil --当前选择的ID
local m_NowIdx = nil --当前选择的对话索引
local m_DialogShow1 = nil
local m_DialogShow2 = nil
local m_NowConfigInfo = nil --当前显示的对话信息
local option = {
    ccbiFile = "Act_TimeLimitGhostNewBie.ccbi",
    handlerMap = {
        --按钮点击事件
        onClose = "onClose"
    }
}

local m_DialogShowIdx = {
    left = 1,
    right = 2
}

local ActivityDialogConfigBase = {}
function ActivityDialogConfigBase:onEnter(container)
    local getNode = container:getVarNode("mNewBie")

    --下拉动画节点
    m_DialogShow1 = ScriptContentBase:create("NavigationPopUp01.ccbi")
    getNode:addChild(m_DialogShow1)
    m_DialogShow1:release()
    -- NodeHelper:setStringForLabel(DiaglogShow1, { mName = common:getLanguageString(thisActivityInfo.activityCfg.name)});--名字

    ---箱子动画节点
    m_DialogShow2 = ScriptContentBase:create("NavigationPopUp02.ccbi")
    m_DialogShow2:release()
    getNode:addChild(m_DialogShow2)

    m_NowConfigInfo = ActivityDialogConfig[m_NowId]
    m_NowIdx = 1 --默认从一开始
    self:onChangDialog()
end

--改变对话信息
function ActivityDialogConfigBase:onChangDialog()
    local dialogInfo = m_NowConfigInfo[m_NowIdx]
    if dialogInfo.index == m_DialogShowIdx.left then --左边对话框
        m_DialogShow1:setVisible(true)
        m_DialogShow2:setVisible(false)
        --改变主角图片
        if not dialogInfo.pic or dialogInfo.pic == " " or dialogInfo.pic == "" then
            local headPic = GuideManager.rolePic[UserInfo.roleInfo.itemId]
            m_DialogShow1:getVarSprite("mPic2"):setTexture(headPic)
        else
            m_DialogShow1:getVarSprite("mPic2"):setTexture(dialogInfo.pic)
        end
        --改变名字
        if not dialogInfo.name or dialogInfo.name == " " or dialogInfo.name == "" then
            NodeHelper:setStringForLabel(m_DialogShow1, { mNewGuideName = "" })
        else
            NodeHelper:setStringForLabel(m_DialogShow1, { mNewGuideName = common:getLanguageString(dialogInfo.name) })
        end
        --对话内容
        NodeHelper:setStringForLabel(m_DialogShow1, { mNewGuideSpeaking01 = common:getLanguageString(dialogInfo.text) })
    elseif dialogInfo.index == m_DialogShowIdx.right then --右边对话框
        m_DialogShow1:setVisible(false)
        m_DialogShow2:setVisible(true)
        --改变主角图片
        if not dialogInfo.pic or dialogInfo.pic == " " or dialogInfo.pic == "" then
            local headPic = GuideManager.rolePic[UserInfo.roleInfo.itemId]
            m_DialogShow2:getVarSprite("mPic1"):setTexture(headPic)
        else
            m_DialogShow2:getVarSprite("mPic1"):setTexture(dialogInfo.pic)
        end
        --改变名字
        if not dialogInfo.name or dialogInfo.name == " " or dialogInfo.name == "" then
            NodeHelper:setStringForLabel(m_DialogShow2, { mNewGuideName = "" })
        else
            NodeHelper:setStringForLabel(m_DialogShow2, { mNewGuideName = common:getLanguageString(dialogInfo.name) })
        end
        --对话内容
        NodeHelper:setStringForLabel(m_DialogShow2, { mNewGuideSpeaking02 = common:getLanguageString(dialogInfo.text) });
    end
end

function ActivityDialogConfigBase.onFunction()

end

function ActivityDialogConfigBase:onExecute(container)

end

function ActivityDialogConfigBase:onExit(container)

end

function ActivityDialogConfigBase:onClose(container)
    if m_NowConfigInfo == nil or m_NowIdx >= (#m_NowConfigInfo) then
        PageManager.popPage(thisPageName)
    else
        m_NowIdx = m_NowIdx + 1
        self:onChangDialog()
    end
end


function ActivityDialogConfigBase_setAlreadySelItem(id)
    m_NowId = id
end

local CommonPage = require("CommonPage")
local ActivityDialogConfigPage = CommonPage.newSub(ActivityDialogConfigBase, thisPageName, option)
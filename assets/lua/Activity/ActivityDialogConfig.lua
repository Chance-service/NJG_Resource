--[[
--
--index:1对话框显示左边，2显示右边
--pic:显示的图片资源，如果不填，代表用自己的资源图片
--name:显示对话框中的名字，如果不填默认自己的名字
--text:对话内容
--]]--
local ActivityDialogConfig = {
	[105] = {
		[1] = {
			pic = "UI/NewBieGuide/u_GuideRole_JinChuanYiYuan.png",
			name = "@Role_145",
			text = "@NewbieGuideStr100",
			index = 1,
		},
		[2] = {
			pic = "UI/NewBieGuide/u_GuideRole_JinChuanYiYuan.png",
			name = "@Role_145",
			text = "@NewbieGuideStr101",
			index = 1,
		},
		[3] = {
			pic = "UI/NewBieGuide/u_GuideRole_JinChuanYiYuan.png",
			name = "@Role_145",
			text = "@NewbieGuideStr102",
			index = 1,
		},
		[4] = {
			pic = "",
			name = "",
			text = "@NewbieGuideStr103",
			index = 2,
		},
		[5] = {
			pic = "UI/NewBieGuide/u_GuideRole_JinChuanYiYuan.png",
			name = "@Role_145",
			text = "@NewbieGuideStr104",
			index = 1,
		},
		[6] = {
			pic = "",
			name = "",
			text = "@NewbieGuideStr105",
			index = 2,
		},
		[7] = {
			pic = "UI/NewBieGuide/u_GuideRole_JinChuanYiYuan.png",
			name = "@Role_145",
			text = "@NewbieGuideStr106",
			index = 1,
		},
		[7] = {
			pic = "UI/NewBieGuide/u_GuideRole_JinChuanYiYuan.png",
			name = "@Role_145",
			text = "@NewbieGuideStr107",
			index = 1,
		}
	},
	[106] = {
		[1] = {
			pic = "UI/NewBieGuide/u_GuideRole_GuoJia.png",
			name = "@Role_121",
			text = "@NewbieGuideStr108",
			index = 1,
		}
	},
	[107] = {
		[1] = {
			pic = "UI/NewBieGuide/u_GuideRole_ZhangJiao.png",
			name = "@Role_160",
			text = "@NewbieGuideStr109",
			index = 1,
		}
	}
}

return ActivityDialogConfig;
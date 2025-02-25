local thisPageName = "GuideStoryManager"

local GuideStoryManager = { }

GuideStoryManager.PAGE_DATA = {
    mainSpineData = { path = "", spine = nil },
    txtSpineData = { path = "", spine = nil },
    nextSpine = { path = "", spine = nil, txtSpine = nil },
}
GuideStoryManager.SPINE_LIST = { }

GuideStoryManager.AYSNC_LOAD_SPINE_IDX = 1
GuideStoryManager.AYSNC_RELEASE_SPINE_IDX = 1
GuideStoryManager.ASYNC_LOAD_PER_COUNT = 1
GuideStoryManager.ASYNC_LOAD_TASKS = { }

GuideStoryManager.TEXTURE_DATA = {
    -- A
    ["NG_PhaseA_vid1"] = { texCount = 16, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseA_vid1-2"] = { texCount = 16, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseA_vid2"] = { texCount = 16, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseA_vid2-2"] = { texCount = 16, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseA_vid3"] = { texCount = 16, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseA_vid3-2"] = { texCount = 14, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseA_vid4"] = { texCount = 16, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseA_vid4-2"] = { texCount = 16, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseA_vid5"] = { texCount = 11, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseA_vid5-2"] = { texCount = 11, loadCount = 0, releaseCount = -10 },
    -- B
    ["NG_PhaseB_vid1"] = { texCount = 17, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseB_vid1-2"] = { texCount = 17, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseB_vid2"] = { texCount = 19, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseB_vid2-2"] = { texCount = 17, loadCount = 0, releaseCount = -10 },
    -- C
    ["NG_PhaseC_vid1"] = { texCount = 16, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseC_vid1-2"] = { texCount = 16, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseC_vid2"] = { texCount = 16, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseC_vid2-2"] = { texCount = 16, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseC_vid3"] = { texCount = 16, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseC_vid3-2"] = { texCount = 16, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseC_vid4"] = { texCount = 18, loadCount = 0, releaseCount = -10 },
    ["NG_PhaseC_vid4-2"] = { texCount = 15, loadCount = 0, releaseCount = -10 },
}

GuideStoryManager.ANI_NAME_DATA = {
    -- A
    ["NG_PhaseA_vid1"] = "animation", ["NG_PhaseA_vid1-2"] = "animation", ["NG_PhaseA_vid2"] = "animation", ["NG_PhaseA_vid2-2"] = "animation",
    ["NG_PhaseA_vid3"] = "animation", ["NG_PhaseA_vid3-2"] = "animation", ["NG_PhaseA_vid4"] = "animation", ["NG_PhaseA_vid4-2"] = "animation", 
    ["NG_PhaseA_vid5"] = "animation", ["NG_PhaseA_vid5-2"] = "animation",
    ["NG_PhaseA_txt1"] = "animation", ["NG_PhaseA_txt1-2"] = "animation", ["NG_PhaseA_txt2"] = "animation", ["NG_PhaseA_txt2-2"] = "animation",
    ["NG_PhaseA_txt3"] = "animation", ["NG_PhaseA_txt3-2"] = "animation", ["NG_PhaseA_txt4"] = "animation", ["NG_PhaseA_txt4-2"] = "animation", 
    ["NG_PhaseA_txt5"] = "animation", ["NG_PhaseA_txt5-2"] = "animation",
    -- B
    ["NG_PhaseB_vid1"] = "animation", ["NG_PhaseB_vid1-2"] = "animation", ["NG_PhaseB_vid2"] = "animation", ["NG_PhaseB_vid2-2"] = "animation", 
    ["NG_PhaseB_txt1"] = "animation", ["NG_PhaseB_txt1-2"] = "animation", ["NG_PhaseB_txt2"] = "animation", ["NG_PhaseB_txt2-2"] = "animation",
    -- C
    ["NG_PhaseC_vid1"] = "animation", ["NG_PhaseC_vid1-2"] = "animation", ["NG_PhaseC_vid2"] = "animation", ["NG_PhaseC_vid2-2"] = "animation",
    ["NG_PhaseC_vid3"] = "animation", ["NG_PhaseC_vid3-2"] = "animation", ["NG_PhaseC_vid4"] = "animation", ["NG_PhaseC_vid4-2"] = "animation",
    ["NG_PhaseC_txt1"] = "animation", ["NG_PhaseC_txt1-2"] = "animation", ["NG_PhaseC_txt2"] = "animation", ["NG_PhaseC_txt2-2"] = "animation",
    ["NG_PhaseC_txt3"] = "animation", ["NG_PhaseC_txt3-2"] = "animation", ["NG_PhaseC_txt4"] = "animation", ["NG_PhaseC_txt4-2"] = "animation"
}

-- ¼@±¡spine list
GuideStoryManager.PLAYING_LIST_IDX = 0
GuideStoryManager.PLAYING_SPINE_IDX = 1
GuideStoryManager.STORY_SPINE_LIST = {
    -- A
    [1] = { "NG_PhaseA_vid1", "NG_PhaseA_vid1-2", "NG_PhaseA_vid2", "NG_PhaseA_vid2-2", "NG_PhaseA_vid3",
            "NG_PhaseA_vid3-2", "NG_PhaseA_vid4", "NG_PhaseA_vid4-2", "NG_PhaseA_vid5", "NG_PhaseA_vid5-2" },
    -- B
    [2] = { "NG_PhaseB_vid1", "NG_PhaseB_vid1-2", "NG_PhaseB_vid2", "NG_PhaseB_vid2-2" },
    -- C
    [3] = { "NG_PhaseC_vid1", "NG_PhaseC_vid1-2", "NG_PhaseC_vid2", "NG_PhaseC_vid2-2",
            "NG_PhaseC_vid3", "NG_PhaseC_vid3-2", "NG_PhaseC_vid4", "NG_PhaseC_vid4-2" },
}
GuideStoryManager.TXT_SPINE_LIST = {
    -- A
    [1] = { "NG_PhaseA_txt1", "NG_PhaseA_txt1-2", "NG_PhaseA_txt2", "NG_PhaseA_txt2-2", "NG_PhaseA_txt3",
            "NG_PhaseA_txt3-2", "NG_PhaseA_txt4", "NG_PhaseA_txt4-2", "NG_PhaseA_txt5", "NG_PhaseA_txt5-2" },
    -- B
    [2] = { "NG_PhaseB_txt1", "NG_PhaseB_txt1-2", "NG_PhaseB_txt2", "NG_PhaseB_txt2-2" },
    -- C
    [3] = { "NG_PhaseC_txt1", "NG_PhaseC_txt1-2", "NG_PhaseC_txt2", "NG_PhaseC_txt2-2",
            "NG_PhaseC_txt3", "NG_PhaseC_txt3-2", "NG_PhaseC_txt4", "NG_PhaseC_txt4-2" },
}
GuideStoryManager.BGM_LIST = {
    [1] = { "NGIntroPt1.mp3" },
    [2] = { "NGIntroPt2.mp3" },
    [3] = { "NGIntroPt3.mp3" },
}

function GuideStoryManager_setStoryIdx(idx)
    GuideStoryManager.PLAYING_LIST_IDX = idx
end

function GuideStoryManager_resetData()
    GuideStoryManager.AYSNC_LOAD_SPINE_IDX = 1
    GuideStoryManager.AYSNC_RELEASE_SPINE_IDX = 1
    GuideStoryManager.PLAYING_SPINE_IDX = 1
    GuideStoryManager.ASYNC_LOAD_TASKS = { }
    for k, v in pairs(GuideStoryManager.PAGE_DATA) do
        GuideStoryManager.PAGE_DATA[k] = { path = "", spine = nil }
    end
    for k, v in pairs(GuideStoryManager.TEXTURE_DATA) do
        v.loadCount = 0
        v.releaseCount = -10
    end
    return GuideStoryManager
end

return GuideStoryManager
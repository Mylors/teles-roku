sub init()
    m.background = m.top.findNode("background")
    m.titleLabel = m.top.findNode("titleLabel")
    m.subtitleLabel = m.top.findNode("subtitleLabel")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.channelGrid = m.top.findNode("channelGrid")
    m.searchKeyboard = m.top.findNode("searchKeyboard")
    m.selectedChannelLabel = m.top.findNode("selectedChannelLabel")
    m.instructionsLabel = m.top.findNode("instructionsLabel")
    m.videoPlayer = m.top.findNode("videoPlayer")
    
    ' Set up observers
    m.channelGrid.observeField("itemSelected", "onChannelSelected")
    m.channelGrid.observeField("itemFocused", "onChannelFocused")
    m.videoPlayer.observeField("state", "onVideoPlayerStateChanged")
    m.searchKeyboard.observeField("text", "onSearchTextChanged")
    loadFavorites()
    loadChannelsData()
end sub

sub loadChannelsData()
    m.loadingLabel.visible = true
    m.channelGrid.visible = false
    m.searchKeyboard.visible = false
    m.selectedChannelLabel.visible = false
    
    m.jsonTask = CreateObject("roSGNode", "JsonTask")
    m.jsonTask.url = "https://cdn.jsdelivr.net/gh/Alplox/json-teles@refs/heads/main/channels.json"
    m.jsonTask.observeField("data", "onChannelsDataReceived")
    m.jsonTask.control = "RUN"
end sub

sub onChannelsDataReceived()
    m.loadingLabel.visible = false
    
    jsonData = m.jsonTask.data
    if jsonData <> invalid and jsonData.channels <> invalid
        m.allChannels = jsonData.channels
        
        m.channelGrid.visible = true
        m.searchKeyboard.visible = true
        m.selectedChannelLabel.visible = true
        m.searchKeyboard.setFocus(true)
        
        filterChannelGrid("")
    else
        m.loadingLabel.text = "Error al cargar la lista de canales."
    end if
end sub

sub onSearchTextChanged()
    query = LCase(m.searchKeyboard.text.Trim())
    filterChannelGrid(query)
end sub

sub filterChannelGrid(query as String)
    gridContent = CreateObject("roSGNode", "ContentNode")

    if query = ""
        for each channel in m.allChannels
            if m.favorites[channel.id] <> invalid
                m3u8Url = getPlayableM3u8(channel)
                if m3u8Url <> ""
                    createGridItem(gridContent, channel, m3u8Url)
                end if
            end if
        end for
    end if
    
    for each channel in m.allChannels
        channelName = ""
        if channel.name <> invalid then channelName = LCase(channel.name)
        
        if query = "" or Instr(1, channelName, query) > 0
            if channel.country <> invalid and LCase(channel.country) = "cl"
                m3u8Url = getPlayableM3u8(channel)
                if m3u8Url <> ""
                    createGridItem(gridContent, channel, m3u8Url)
                end if
            end if
        end if
    end for
    
    if query <> ""
        for each channel in m.allChannels
            channelName = ""
            if channel.name <> invalid then channelName = LCase(channel.name)
            
            if Instr(1, channelName, query) > 0
                if channel.country = invalid or LCase(channel.country) <> "cl"
                    m3u8Url = getPlayableM3u8(channel)
                    if m3u8Url <> ""
                        createGridItem(gridContent, channel, m3u8Url)
                    end if
                end if
            end if
        end for
    end if
    
    m.channelGrid.content = gridContent
    
    ' Reset focused label text
    m.selectedChannelLabel.text = ""
    if gridContent.getChildCount() > 0
        firstItem = gridContent.getChild(0)
        if firstItem <> invalid
            m.selectedChannelLabel.text = firstItem.title
        end if
    end if
end sub

sub onChannelFocused()
    selectedIndex = m.channelGrid.itemFocused
    gridContent = m.channelGrid.content
    if gridContent <> invalid
        selectedItem = gridContent.getChild(selectedIndex)
        if selectedItem <> invalid
            m.selectedChannelLabel.text = selectedItem.title
        end if
    end if
end sub

function getPlayableM3u8(channel as Object) as String
    m3u8Url = ""
    if channel.signals <> invalid
        for each sig in channel.signals
            if sig.type = "m3u8" and sig.url <> invalid and sig.url <> ""
                m3u8Url = sig.url
                exit for
            end if
        end for
    end if
    return m3u8Url
end function

sub createGridItem(parent as Object, channel as Object, m3u8Url as String)
    itemNode = parent.createChild("ContentNode")
    itemNode.id = channel.id
    
    title = channel.name
    if m.favorites[channel.id] <> invalid
        title = "[FAV] " + title
    end if
    itemNode.title = title
    
    logoUrl = channel.logo
    if logoUrl = invalid or logoUrl = ""
        logoUrl = "pkg:/images/channel_icon_fhd.jpg"
    end if
    itemNode.HDPosterUrl = logoUrl
    
    itemNode.url = m3u8Url
    itemNode.streamFormat = "hls"
    itemNode.live = true
end sub

sub loadFavorites()
    m.favorites = {}
    sec = CreateObject("roRegistrySection", "TelesFavorites")
    if sec.Exists("channelIds")
        idsStr = sec.Read("channelIds")
        ids = idsStr.Split(",")
        for each id in ids
            if id <> "" then m.favorites[id] = true
        end for
    end if
end sub

sub saveFavorites()
    sec = CreateObject("roRegistrySection", "TelesFavorites")
    ids = []
    for each id in m.favorites
        ids.Push(id)
    end for
    idsStr = ids.Join(",")
    sec.Write("channelIds", idsStr)
    sec.Flush()
end sub

sub toggleFavorite(channelId as String)
    if m.favorites[channelId] <> invalid
        m.favorites.Delete(channelId)
    else
        m.favorites[channelId] = true
    end if
    saveFavorites()
end sub

function findChannelIndexInGrid(channelId as String) as Integer
    gridContent = m.channelGrid.content
    if gridContent <> invalid
        count = gridContent.getChildCount()
        for i = 0 to count - 1
            item = gridContent.getChild(i)
            if item <> invalid and item.id = channelId
                return i
            end if
        end for
    end if
    return -1
end function

sub onChannelSelected()
    selectedIndex = m.channelGrid.itemSelected
    gridContent = m.channelGrid.content
    selectedItem = gridContent.getChild(selectedIndex)
    
    if selectedItem <> invalid and selectedItem.url <> ""
        videoContent = CreateObject("roSGNode", "ContentNode")
        videoContent.url = selectedItem.url
        videoContent.streamFormat = "hls"
        videoContent.title = selectedItem.title
        videoContent.live = true
        
        m.videoPlayer.content = videoContent
        m.videoPlayer.visible = true
        m.videoPlayer.control = "play"
        m.videoPlayer.setFocus(true)
        
        m.channelGrid.visible = false
        m.searchKeyboard.visible = false
        m.selectedChannelLabel.visible = false
        m.top.findNode("headerGroup").visible = false
        m.instructionsLabel.visible = false
    end if
end sub

sub onVideoPlayerStateChanged()
    state = m.videoPlayer.state
    if state = "finished" or state = "error"
        closeVideoPlayer()
    end if
end sub

sub closeVideoPlayer()
    m.videoPlayer.control = "stop"
    m.videoPlayer.content = invalid 
    m.videoPlayer.visible = false
    m.channelGrid.visible = true
    m.searchKeyboard.visible = true
    m.selectedChannelLabel.visible = true
    m.top.findNode("headerGroup").visible = true
    m.instructionsLabel.visible = true
    m.channelGrid.setFocus(true)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    
    if press
        if key = "back"
            if m.videoPlayer.visible
                closeVideoPlayer()
                handled = true
            else if m.channelGrid.isInFocusChain()
                m.searchKeyboard.setFocus(true)
                handled = true
            end if
        else if key = "right" or key = "down"
            if not m.channelGrid.isInFocusChain() and m.channelGrid.content <> invalid and m.channelGrid.content.getChildCount() > 0
                if m.channelGrid.itemFocused < 0
                    m.channelGrid.jumpToItem = 0
                end if
                m.channelGrid.setFocus(true)
                handled = true
            end if
        else if key = "left"
            if m.channelGrid.isInFocusChain()
                m.searchKeyboard.setFocus(true)
                handled = true
            end if
        else if key = "options"
            if m.channelGrid.isInFocusChain()
                selectedIndex = m.channelGrid.itemFocused
                gridContent = m.channelGrid.content
                if gridContent <> invalid and selectedIndex >= 0 and selectedIndex < gridContent.getChildCount()
                    selectedItem = gridContent.getChild(selectedIndex)
                    if selectedItem <> invalid
                        channelId = selectedItem.id
                        if channelId <> "" and channelId <> invalid
                            toggleFavorite(channelId)
    
                            query = LCase(m.searchKeyboard.text.Trim())
                            filterChannelGrid(query)
                            
                            ' Restore the focus index to the same channel
                            newIndex = findChannelIndexInGrid(channelId)
                            if newIndex >= 0
                                m.channelGrid.jumpToItem = newIndex
                            end if
                            
                            handled = true
                        end if
                    end if
                end if
            end if
        end if
    end if
    
    return handled
end function

sub init()
    m.activeBg = m.top.findNode("activeBg")
    m.focusBg = m.top.findNode("focusBg")
    m.iconPoster = m.top.findNode("iconPoster")
    m.titleLabel = m.top.findNode("titleLabel")
    m.countGroup = m.top.findNode("countGroup")
    m.countBg = m.top.findNode("countBg")
    m.countFocusBg = m.top.findNode("countFocusBg")
    m.countLabel = m.top.findNode("countLabel")
    m.boundNode = invalid
end sub

sub onContentChanged()
    if m.boundNode <> invalid
        m.boundNode.unobserveField("isActive")
        m.boundNode.unobserveField("badgeText")
        m.boundNode.unobserveField("title")
    end if

    m.boundNode = m.top.itemContent
    if m.boundNode <> invalid
        m.boundNode.observeField("isActive", "refreshItem")
        m.boundNode.observeField("badgeText", "refreshItem")
        m.boundNode.observeField("title", "refreshItem")
    end if

    refreshItem()
end sub

sub refreshItem()
    node = m.boundNode
    if node = invalid then return

    m.titleLabel.text = node.title

    if node.HDPosterUrl <> invalid and node.HDPosterUrl <> ""
        m.iconPoster.uri = node.HDPosterUrl
    end if

    badge = ""
    if node.doesExist("badgeText") and node.badgeText <> invalid
        badge = node.badgeText
    end if

    if badge <> ""
        m.countGroup.visible = true
        m.countLabel.text = badge
        m.titleLabel.width = 154
    else
        m.countGroup.visible = false
        m.titleLabel.width = 212
    end if

    onFocusChanged()
end sub

sub onFocusChanged()
    node = m.boundNode
    isActive = false
    if node <> invalid and node.doesExist("isActive") and node.isActive = true
        isActive = true
    end if

    hasFocus = m.top.listHasFocus
    fp = m.top.focusPercent
    isFocusedNow = (hasFocus and fp > 0.5)

    if hasFocus
        m.focusBg.opacity = fp
    else
        m.focusBg.opacity = 0.0
    end if

    m.activeBg.visible = (isActive and not isFocusedNow)
    m.countFocusBg.visible = isFocusedNow
    m.countBg.visible = not isFocusedNow

    if isFocusedNow
        m.titleLabel.font = "font:SmallBoldSystemFont"
        m.titleLabel.color = "0xFFFFFFFF"
        m.countLabel.color = "0xEDE9FEFF"
        m.iconPoster.opacity = 1.0
    else if isActive
        m.titleLabel.font = "font:SmallBoldSystemFont"
        m.titleLabel.color = "0xEDE9FEFF"
        m.countLabel.color = "0xC4B5FDFF"
        m.iconPoster.opacity = 1.0
    else
        m.titleLabel.font = "font:SmallSystemFont"
        m.titleLabel.color = "0xA1A1AAFF"
        m.countLabel.color = "0x9CA3AFFF"
        m.iconPoster.opacity = 0.78
    end if
end sub

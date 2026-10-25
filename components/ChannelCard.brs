sub init()
    m.cardRoot = m.top.findNode("cardRoot")
    m.bgSelected = m.top.findNode("bgSelected")
    m.bgFocus = m.top.findNode("bgFocus")
    m.stageFocus = m.top.findNode("stageFocus")
    m.avatarGroup = m.top.findNode("avatarGroup")
    m.initialsLabel = m.top.findNode("initialsLabel")
    m.logoPoster = m.top.findNode("logoPoster")
    m.countryLabel = m.top.findNode("countryLabel")
    m.favIcon = m.top.findNode("favIcon")
    m.titleLabel = m.top.findNode("titleLabel")
    m.metaLabel = m.top.findNode("metaLabel")

    m.logoPoster.observeField("loadStatus", "onLogoLoadStatusChanged")
    m.boundNode = invalid
    m.currentLogoUri = ""
end sub

sub onContentChanged()
    if m.boundNode <> invalid
        m.boundNode.unobserveField("isFavorite")
    end if

    m.boundNode = m.top.itemContent
    if m.boundNode <> invalid
        m.boundNode.observeField("isFavorite", "refreshFavoriteOnly")
    end if

    refreshCard()
end sub

sub refreshFavoriteOnly()
    node = m.boundNode
    if node = invalid then return
    isFav = false
    if node.doesExist("isFavorite") and node.isFavorite = true
        isFav = true
    end if
    m.favIcon.visible = isFav
end sub

sub refreshCard()
    node = m.boundNode
    if node = invalid then return

    m.titleLabel.text = node.title

    meta = ""
    if node.doesExist("cardSubtitle") and node.cardSubtitle <> invalid
        meta = node.cardSubtitle
    end if
    m.metaLabel.text = meta

    cCode = "TV"
    if node.doesExist("countryCode") and node.countryCode <> invalid and node.countryCode <> ""
        cCode = node.countryCode
    end if
    m.countryLabel.text = cCode

    initials = "TV"
    if node.doesExist("initials") and node.initials <> invalid and node.initials <> ""
        initials = node.initials
    end if
    m.initialsLabel.text = initials

    refreshFavoriteOnly()

    logoUrl = ""
    if node.HDPosterUrl <> invalid
        logoUrl = node.HDPosterUrl
    end if

    if logoUrl = ""
        m.currentLogoUri = ""
        m.logoPoster.uri = ""
        m.logoPoster.visible = false
        m.avatarGroup.visible = true
    else if logoUrl <> m.currentLogoUri
        m.currentLogoUri = logoUrl
        m.logoPoster.visible = false
        m.avatarGroup.visible = true
        m.logoPoster.uri = logoUrl
        onLogoLoadStatusChanged()
    else
        onLogoLoadStatusChanged()
    end if

    onFocusChanged()
end sub

sub onLogoLoadStatusChanged()
    if m.currentLogoUri = ""
        m.logoPoster.visible = false
        m.avatarGroup.visible = true
        return
    end if

    status = m.logoPoster.loadStatus
    if status = "ready"
        m.logoPoster.visible = true
        m.avatarGroup.visible = false
    else
        m.logoPoster.visible = false
        m.avatarGroup.visible = true
    end if
end sub

sub onFocusChanged()
    gridFocus = m.top.gridHasFocus
    fp = m.top.focusPercent

    if gridFocus
        scale = 1.0 + (fp * 0.03)
        m.cardRoot.scale = [scale, scale]
        m.bgFocus.opacity = fp
        m.stageFocus.opacity = fp
        m.bgSelected.visible = false

        if fp > 0.5
            m.titleLabel.color = "0xFFFFFFFF"
            m.metaLabel.color = "0xD4D4D8FF"
        else
            m.titleLabel.color = "0xE4E4E7FF"
            m.metaLabel.color = "0x9CA3AFFF"
        end if
    else
        m.cardRoot.scale = [1.0, 1.0]
        m.bgFocus.opacity = 0.0
        m.stageFocus.opacity = 0.0
        m.bgSelected.visible = (m.top.itemHasFocus or fp > 0.5)
        m.titleLabel.color = "0xE4E4E7FF"
        m.metaLabel.color = "0x9CA3AFFF"
    end if
end sub

sub init()
    m.browseGroup = m.top.findNode("browseGroup")
    m.sidebarList = m.top.findNode("sidebarList")
    m.hintGroup = m.top.findNode("hintGroup")
    m.heroGroup = m.top.findNode("heroGroup")
    m.selectedChannelLabel = m.top.findNode("selectedChannelLabel")
    m.counterLabel = m.top.findNode("counterLabel")
    m.heroLiveDot = m.top.findNode("heroLiveDot")
    m.selectedMetaLabel = m.top.findNode("selectedMetaLabel")
    m.activeFilterLabel = m.top.findNode("activeFilterLabel")
    m.channelGrid = m.top.findNode("channelGrid")

    m.stateGroup = m.top.findNode("stateGroup")
    m.stateTitleLabel = m.top.findNode("stateTitleLabel")
    m.stateSubLabel = m.top.findNode("stateSubLabel")

    m.searchModalGroup = m.top.findNode("searchModalGroup")
    m.modalCountLabel = m.top.findNode("modalCountLabel")
    m.searchKeyboard = m.top.findNode("searchKeyboard")

    m.videoPlayer = m.top.findNode("videoPlayer")
    m.playerOsd = m.top.findNode("playerOsd")
    m.osdSignalTag = m.top.findNode("osdSignalTag")
    m.osdChannelTitle = m.top.findNode("osdChannelTitle")
    m.osdMetaLabel = m.top.findNode("osdMetaLabel")
    m.osdControlsHint = m.top.findNode("osdControlsHint")

    m.toastGroup = m.top.findNode("toastGroup")
    m.toastLabel = m.top.findNode("toastLabel")

    m.osdTimer = m.top.findNode("osdTimer")
    m.toastTimer = m.top.findNode("toastTimer")

    ' State variables
    m.playableChannels = []
    m.favorites = {}
    m.activeCategory = "all"
    m.searchQuery = ""
    m.isLoading = true
    m.hasLoadError = false
    m.suppressSidebarFocus = false

    m.currentPlayIndex = -1
    m.currentSignalIndex = 0
    m.currentSignals = []

    ' Set up observers
    m.sidebarList.observeField("itemFocused", "onSidebarFocused")
    m.sidebarList.observeField("itemSelected", "onSidebarSelected")
    m.channelGrid.observeField("itemFocused", "onChannelFocused")
    m.channelGrid.observeField("itemSelected", "onChannelSelected")
    m.searchKeyboard.observeField("text", "onSearchTextChanged")
    m.videoPlayer.observeField("state", "onVideoPlayerStateChanged")
    m.osdTimer.observeField("fire", "onOsdTimerFired")
    m.toastTimer.observeField("fire", "onToastTimerFired")

    initCountryAndCategoryMaps()
    loadFavorites()
    loadChannelsData()
end sub

sub initCountryAndCategoryMaps()
    m.countryNames = {
        "cl": "Chile",
        "ar": "Argentina",
        "pe": "Perú",
        "bo": "Bolivia",
        "py": "Paraguay",
        "uy": "Uruguay",
        "br": "Brasil",
        "co": "Colombia",
        "ve": "Venezuela",
        "ec": "Ecuador",
        "mx": "México",
        "hn": "Honduras",
        "us": "EE. UU.",
        "es": "España",
        "de": "Alemania",
        "fr": "Francia",
        "gb": "Reino Unido",
        "it": "Italia",
        "qa": "Catar",
        "ae": "Emiratos Árabes",
        "sa": "Arabia Saudita",
        "lb": "Líbano",
        "iq": "Irak",
        "in": "India",
        "pk": "Pakistán",
        "ru": "Rusia",
        "cn": "China",
        "jp": "Japón",
        "kr": "Corea del Sur",
        "tr": "Turquía"
    }

    m.categoryLabels = {
        news: "Noticias",
        general: "General",
        music: "Música",
        culture: "Cultura",
        entertainment: "Entretención",
        animation: "Animación",
        outdoor: "Exterior",
        legislative: "Legislativo",
        religious: "Religión",
        sports: "Deportes"
    }
end sub

' =====================================================================
' DATA FETCHING & NORMALIZATION
' =====================================================================

sub loadChannelsData()
    m.isLoading = true
    m.hasLoadError = false

    m.stateTitleLabel.text = "Cargando canales en vivo..."
    m.stateSubLabel.text = "Conectando con el directorio de señales..."
    m.stateGroup.visible = true

    m.channelGrid.visible = false
    m.sidebarList.visible = false
    m.heroGroup.visible = false
    m.hintGroup.visible = false

    m.jsonTask = CreateObject("roSGNode", "JsonTask")
    m.jsonTask.url = "https://cdn.jsdelivr.net/gh/Alplox/json-teles@refs/heads/main/channels.json"
    m.jsonTask.observeField("response", "onChannelsResponse")
    m.jsonTask.control = "RUN"
end sub

sub onChannelsResponse()
    m.isLoading = false
    resp = m.jsonTask.response

    if resp <> invalid and resp.ok = true and resp.channels <> invalid
        normalizeChannels(resp.channels)

        m.sidebarList.visible = true
        m.heroGroup.visible = true
        m.hintGroup.visible = true

        buildSidebar()
        applyFilter(0)

        if m.channelGrid.content <> invalid and m.channelGrid.content.getChildCount() > 0
            m.channelGrid.setFocus(true)
        else
            m.sidebarList.setFocus(true)
        end if
    else
        m.hasLoadError = true
        errDetail = "Verifica tu conexión a internet"
        if resp <> invalid and resp.error <> invalid and resp.error <> ""
            errDetail = "Detalle: " + resp.error
        end if
        m.stateTitleLabel.text = "No se pudo cargar la lista de canales"
        m.stateSubLabel.text = errDetail + " · Presiona [OK] para reintentar"
        m.stateGroup.visible = true
        m.top.setFocus(true)
    end if
end sub

sub normalizeChannels(rawChannels as Object)
    m.playableChannels = []
    m.counts = {
        all: 0,
        cl: 0,
        intl: 0,
        news: 0,
        general: 0,
        music: 0,
        other: 0
    }

    for each ch in rawChannels
        if ch <> invalid and ch.id <> invalid and ch.id <> ""
            signals = extractPlayableSignals(ch)
            if signals.Count() > 0
                rawCountry = ""
                if ch.country <> invalid then rawCountry = LCase(ch.country.Trim())
                shortCountry = rawCountry
                if Len(shortCountry) > 2
                    shortCountry = Left(shortCountry, 2)
                end if

                isCl = (shortCountry = "cl")
                countryCode = "INT"
                if shortCountry <> "" then countryCode = UCase(shortCountry)

                countryName = "Internacional"
                if shortCountry <> "" and m.countryNames[shortCountry] <> invalid
                    countryName = m.countryNames[shortCountry]
                else if countryCode <> "INT"
                    countryName = countryCode
                end if

                rawCat = "general"
                if ch.category <> invalid and ch.category <> ""
                    rawCat = LCase(ch.category.Trim())
                end if

                catLabel = "TV en vivo"
                if m.categoryLabels[rawCat] <> invalid
                    catLabel = m.categoryLabels[rawCat]
                end if

                catBucket = "other"
                if rawCat = "news" or rawCat = "general" or rawCat = "music"
                    catBucket = rawCat
                end if

                name = ch.id
                if ch.name <> invalid and ch.name.Trim() <> ""
                    name = ch.name.Trim()
                end if

                logoUrl = sanitizeLogoUrl(ch.logo)
                initials = buildInitials(name)

                searchBlob = normalizeSearchText(name + " " + countryName + " " + countryCode + " " + catLabel)

                entry = {
                    id: ch.id,
                    name: name,
                    logoUrl: logoUrl,
                    initials: initials,
                    isCl: isCl,
                    countryCode: countryCode,
                    countryName: countryName,
                    catBucket: catBucket,
                    catLabel: catLabel,
                    signals: signals,
                    signalCount: signals.Count(),
                    searchBlob: searchBlob
                }

                m.playableChannels.Push(entry)

                m.counts.all = m.counts.all + 1
                if isCl
                    m.counts.cl = m.counts.cl + 1
                else
                    m.counts.intl = m.counts.intl + 1
                end if
                m.counts[catBucket] = m.counts[catBucket] + 1
            end if
        end if
    end for
end sub

function extractPlayableSignals(channel as Object) as Object
    urls = []
    seen = {}
    if channel.signals <> invalid
        for each sig in channel.signals
            if sig <> invalid and sig.type = "m3u8" and sig.url <> invalid
                u = sig.url.Trim()
                if u <> "" and seen[u] = invalid
                    seen[u] = true
                    urls.Push(u)
                end if
            end if
        end for
    end if
    return urls
end function

function sanitizeLogoUrl(rawLogo as Dynamic) as String
    if rawLogo = invalid then return ""
    url = rawLogo.Trim()
    if url = "" then return ""

    lower = LCase(url)
    ' Roku SceneGraph Poster does not support SVG vector files
    if Right(lower, 4) = ".svg" or Instr(1, lower, ".svg?") > 0
        return ""
    end if

    return url
end function

function buildInitials(name as String) as String
    cleaned = UCase(normalizeSearchText(name))
    skipWords = {
        "CANAL": true,
        "TV": true,
        "TELEVISION": true,
        "RADIO": true,
        "SENAL": true,
        "DE": true,
        "LA": true,
        "EL": true,
        "LOS": true,
        "EN": true,
        "VIVO": true,
        "LIVE": true,
        "ONLINE": true
    }

    ' Extract ASCII alphanumeric words
    tokens = []
    current = ""
    for i = 1 to Len(cleaned)
        ch = Mid(cleaned, i, 1)
        code = Asc(ch)
        isAlphaNum = (code >= 48 and code <= 57) or (code >= 65 and code <= 90)
        if isAlphaNum
            current = current + ch
        else
            if current <> ""
                tokens.Push(current)
                current = ""
            end if
        end if
    end for
    if current <> "" then tokens.Push(current)

    filtered = []
    for each tok in tokens
        if skipWords[tok] = invalid
            filtered.Push(tok)
        end if
    end for
    if filtered.Count() = 0 then filtered = tokens

    if filtered.Count() = 0 then return "TV"
    if filtered.Count() = 1
        return Left(filtered[0], 3)
    end if

    firstTok = filtered[0]
    secondTok = filtered[1]
    if Len(firstTok) <= 2
        return Left(firstTok + Left(secondTok, 1), 3)
    end if
    return Left(firstTok, 1) + Left(secondTok, 1)
end function

function normalizeSearchText(text as String) as String
    if text = "" then return ""
    s = LCase(text)
    s = s.Replace("á", "a").Replace("à", "a").Replace("ä", "a").Replace("â", "a")
    s = s.Replace("é", "e").Replace("è", "e").Replace("ë", "e").Replace("ê", "e")
    s = s.Replace("í", "i").Replace("ì", "i").Replace("ï", "i").Replace("î", "i")
    s = s.Replace("ó", "o").Replace("ò", "o").Replace("ö", "o").Replace("ô", "o")
    s = s.Replace("ú", "u").Replace("ù", "u").Replace("ü", "u").Replace("û", "u")
    s = s.Replace("ñ", "n")
    return s
end function

' =====================================================================
' SIDEBAR NAVIGATION & FILTERING
' =====================================================================

sub buildSidebar()
    m.suppressSidebarFocus = true

    root = CreateObject("roSGNode", "ContentNode")
    m.sidebarNodes = {}

    defs = [
        { key: "search",    title: "Buscar",        icon: "pkg:/images/ui/ic_search.png",  badge: "" },
        { key: "all",       title: "Todo",          icon: "pkg:/images/ui/ic_grid.png",    badge: StrI(m.counts.all).Trim() },
        { key: "favorites", title: "Favoritos",     icon: "pkg:/images/ui/ic_star_gold.png", badge: StrI(countPlayableFavorites()).Trim() },
        { key: "cl",        title: "Chile",         icon: "pkg:/images/ui/ic_chile.png",   badge: StrI(m.counts.cl).Trim() },
        { key: "intl",      title: "Internacional", icon: "pkg:/images/ui/ic_globe.png",   badge: StrI(m.counts.intl).Trim() },
        { key: "news",      title: "Noticias",      icon: "pkg:/images/ui/ic_news.png",    badge: StrI(m.counts.news).Trim() },
        { key: "general",   title: "General",       icon: "pkg:/images/ui/ic_tv.png",      badge: StrI(m.counts.general).Trim() },
        { key: "music",     title: "Música",        icon: "pkg:/images/ui/ic_music.png",   badge: StrI(m.counts.music).Trim() },
        { key: "other",     title: "Cultura y Más", icon: "pkg:/images/ui/ic_sparkle.png", badge: StrI(m.counts.other).Trim() }
    ]

    for each d in defs
        item = root.createChild("ContentNode")
        item.id = d.key
        item.title = d.title
        item.HDPosterUrl = d.icon
        item.addFields({
            catKey: d.key,
            badgeText: d.badge,
            isActive: (d.key = m.activeCategory and m.searchQuery = "")
        })
        m.sidebarNodes[d.key] = item
    end for

    m.sidebarList.content = root
    m.sidebarList.jumpToItem = 1
    m.suppressSidebarFocus = false
end sub

sub refreshSidebarState()
    if m.sidebarNodes = invalid then return

    favNode = m.sidebarNodes["favorites"]
    if favNode <> invalid
        favNode.badgeText = StrI(countPlayableFavorites()).Trim()
    end if

    searchNode = m.sidebarNodes["search"]
    if searchNode <> invalid
        if m.searchQuery <> ""
            searchNode.title = "Buscar: " + m.searchQuery
            searchNode.isActive = true
        else
            searchNode.title = "Buscar"
            searchNode.isActive = false
        end if
    end if

    for each key in m.sidebarNodes
        if key <> "search"
            node = m.sidebarNodes[key]
            if node <> invalid
                node.isActive = (m.searchQuery = "" and key = m.activeCategory)
            end if
        end if
    end for
end sub

function countPlayableFavorites() as Integer
    total = 0
    for each ch in m.playableChannels
        if m.favorites[ch.id] <> invalid
            total = total + 1
        end if
    end for
    return total
end function

sub onSidebarFocused()
    if m.suppressSidebarFocus then return
    if not m.sidebarList.isInFocusChain() then return

    idx = m.sidebarList.itemFocused
    content = m.sidebarList.content
    if content = invalid or idx < 0 or idx >= content.getChildCount() then return

    item = content.getChild(idx)
    if item = invalid then return

    key = item.id
    if key = "search"
        ' Keep current grid displayed until user presses OK on Buscar
        return
    end if

    if m.searchQuery <> "" or m.activeCategory <> key
        if m.searchQuery <> ""
            m.suppressKeyboardObserver = true
            m.searchKeyboard.text = ""
            m.suppressKeyboardObserver = false
            m.searchQuery = ""
        end if
        m.activeCategory = key
        refreshSidebarState()
        applyFilter(0)
    end if
end sub

sub onSidebarSelected()
    idx = m.sidebarList.itemSelected
    content = m.sidebarList.content
    if content = invalid or idx < 0 or idx >= content.getChildCount() then return

    item = content.getChild(idx)
    if item = invalid then return

    if item.id = "search"
        openSearchModal()
    else if m.channelGrid.content <> invalid and m.channelGrid.content.getChildCount() > 0
        m.channelGrid.setFocus(true)
    end if
end sub

sub applyFilter(targetFocusIndex = 0 as Integer)
    gridContent = CreateObject("roSGNode", "ContentNode")
    normQuery = normalizeSearchText(m.searchQuery)
    addedIds = {}

    if normQuery <> ""
        ' Search mode: Favorites matching -> Chile matching -> International matching (deduplicated)
        for pass = 1 to 3
            for each ch in m.playableChannels
                if addedIds[ch.id] = invalid and Instr(1, ch.searchBlob, normQuery) > 0
                    includeNow = false
                    if pass = 1 and m.favorites[ch.id] <> invalid
                        includeNow = true
                    else if pass = 2 and ch.isCl
                        includeNow = true
                    else if pass = 3 and not ch.isCl
                        includeNow = true
                    end if

                    if includeNow
                        addedIds[ch.id] = true
                        appendChannelNode(gridContent, ch)
                    end if
                end if
            end for
        end for
    else if m.activeCategory = "all"
        ' Default Todo: Favorites first -> Chile -> International (zero duplicates!)
        for each ch in m.playableChannels
            if m.favorites[ch.id] <> invalid and addedIds[ch.id] = invalid
                addedIds[ch.id] = true
                appendChannelNode(gridContent, ch)
            end if
        end for
        for each ch in m.playableChannels
            if ch.isCl and addedIds[ch.id] = invalid
                addedIds[ch.id] = true
                appendChannelNode(gridContent, ch)
            end if
        end for
        for each ch in m.playableChannels
            if not ch.isCl and addedIds[ch.id] = invalid
                addedIds[ch.id] = true
                appendChannelNode(gridContent, ch)
            end if
        end for
    else if m.activeCategory = "favorites"
        for each ch in m.playableChannels
            if m.favorites[ch.id] <> invalid
                appendChannelNode(gridContent, ch)
            end if
        end for
    else if m.activeCategory = "cl"
        for each ch in m.playableChannels
            if ch.isCl
                appendChannelNode(gridContent, ch)
            end if
        end for
    else if m.activeCategory = "intl"
        for each ch in m.playableChannels
            if not ch.isCl
                appendChannelNode(gridContent, ch)
            end if
        end for
    else
        ' Category filter (news, general, music, other): Chile first, then International
        for pass = 1 to 2
            for each ch in m.playableChannels
                if ch.catBucket = m.activeCategory
                    if (pass = 1 and ch.isCl) or (pass = 2 and not ch.isCl)
                        appendChannelNode(gridContent, ch)
                    end if
                end if
            end for
        end for
    end if

    totalCount = gridContent.getChildCount()
    m.channelGrid.content = gridContent

    if m.searchModalGroup.visible
        if m.searchQuery = ""
            m.modalCountLabel.text = StrI(totalCount).Trim() + " canales disponibles"
        else if totalCount = 1
            m.modalCountLabel.text = "1 resultado"
        else
            m.modalCountLabel.text = StrI(totalCount).Trim() + " resultados"
        end if
    end if

    updateActiveFilterChip()

    if totalCount > 0
        m.stateGroup.visible = false
        m.channelGrid.visible = true

        safeIdx = targetFocusIndex
        if safeIdx < 0 then safeIdx = 0
        if safeIdx >= totalCount then safeIdx = totalCount - 1

        m.channelGrid.jumpToItem = safeIdx
        updateHeroHeaderForIndex(safeIdx)
    else
        m.channelGrid.visible = false
        showEmptyState()
    end if
end sub

sub appendChannelNode(parent as Object, ch as Object)
    itemNode = parent.createChild("ContentNode")
    itemNode.id = ch.id
    itemNode.title = ch.name
    itemNode.HDPosterUrl = ch.logoUrl
    itemNode.url = ch.signals[0]
    itemNode.streamFormat = "hls"
    itemNode.live = true

    isFav = (m.favorites[ch.id] <> invalid)
    subtitle = ch.catLabel + " · " + ch.countryName

    itemNode.addFields({
        isFavorite: isFav,
        countryCode: ch.countryCode,
        countryName: ch.countryName,
        catLabel: ch.catLabel,
        cardSubtitle: subtitle,
        initials: ch.initials,
        signalCount: ch.signalCount,
        signalsJson: FormatJson(ch.signals)
    })
end sub

sub showEmptyState()
    m.selectedChannelLabel.text = getActiveSectionTitle()
    m.counterLabel.text = "0 canales"
    m.heroLiveDot.visible = false
    m.selectedMetaLabel.text = "Sin canales para mostrar en esta vista"

    if m.searchQuery <> ""
        m.stateTitleLabel.text = "Sin resultados para """ + m.searchQuery + """"
        m.stateSubLabel.text = "Prueba con otro nombre o país · En Buscar presiona [*] para limpiar el filtro"
    else if m.activeCategory = "favorites"
        m.stateTitleLabel.text = "Aún no tienes canales favoritos"
        m.stateSubLabel.text = "Ubícate sobre cualquier canal y presiona [*] en tu control remoto para guardarlo aquí"
    else
        m.stateTitleLabel.text = "No hay canales disponibles en esta categoría"
        m.stateSubLabel.text = "Selecciona otra categoría en el menú izquierdo"
    end if

    m.stateGroup.visible = true
end sub

function getActiveSectionTitle() as String
    if m.searchQuery <> ""
        return "Búsqueda: " + m.searchQuery
    end if
    titles = {
        all: "Todos los canales",
        favorites: "Mis Favoritos",
        cl: "Canales de Chile",
        intl: "Canales Internacionales",
        news: "Noticias en Vivo",
        general: "Televisión General",
        music: "Canales de Música",
        other: "Cultura y Más"
    }
    if titles[m.activeCategory] <> invalid
        return titles[m.activeCategory]
    end if
    return "Canales"
end function

sub updateActiveFilterChip()
    if m.searchQuery <> ""
        m.activeFilterLabel.text = "Filtro: """ + m.searchQuery + """  ([*] limpiar)"
    else
        m.activeFilterLabel.text = getActiveSectionTitle()
    end if
end sub

sub onChannelFocused()
    idx = m.channelGrid.itemFocused
    updateHeroHeaderForIndex(idx)
end sub

sub updateHeroHeaderForIndex(idx as Integer)
    gridContent = m.channelGrid.content
    if gridContent = invalid then return
    total = gridContent.getChildCount()
    if idx < 0 or idx >= total then return

    item = gridContent.getChild(idx)
    if item = invalid then return

    m.selectedChannelLabel.text = item.title
    m.counterLabel.text = "Canal " + StrI(idx + 1).Trim() + " de " + StrI(total).Trim()
    m.heroLiveDot.visible = true

    metaParts = "EN VIVO  ·  " + item.countryName + "  ·  " + item.catLabel
    if item.signalCount > 1
        metaParts = metaParts + "  ·  " + StrI(item.signalCount).Trim() + " señales"
    end if
    if item.isFavorite = true
        metaParts = metaParts + "  ·  En Favoritos"
    end if
    m.selectedMetaLabel.text = metaParts
end sub

' =====================================================================
' SEARCH MODAL
' =====================================================================

sub openSearchModal()
    m.searchModalGroup.visible = true
    fitKeyboardInModal()

    total = 0
    if m.channelGrid.content <> invalid
        total = m.channelGrid.content.getChildCount()
    end if
    if m.searchQuery = ""
        m.modalCountLabel.text = StrI(total).Trim() + " canales disponibles"
    else
        m.modalCountLabel.text = StrI(total).Trim() + " resultados"
    end if
    m.searchKeyboard.setFocus(true)
end sub

sub fitKeyboardInModal()
    m.searchKeyboard.scale = [1.0, 1.0]
    rect = m.searchKeyboard.localBoundingRect()
    if rect <> invalid and rect.width > 0 and rect.height > 0
        availW = 632.0
        availH = 516.0
        sx = availW / rect.width
        sy = availH / rect.height
        s = sx
        if sy < s then s = sy
        if s > 0.76 then s = 0.76

        m.searchKeyboard.scale = [s, s]
        scaledW = rect.width * s
        scaledH = rect.height * s
        tx = ((760.0 - scaledW) / 2.0) - (rect.x * s)
        ty = 104.0 + ((availH - scaledH) / 2.0) - (rect.y * s)
        m.searchKeyboard.translation = [tx, ty]
    else
        m.searchKeyboard.scale = [0.74, 0.74]
        m.searchKeyboard.translation = [168, 108]
    end if
end sub

sub closeSearchModal()
    m.searchModalGroup.visible = false
    refreshSidebarState()

    if m.searchQuery <> ""
        m.suppressSidebarFocus = true
        m.sidebarList.jumpToItem = 0
        m.suppressSidebarFocus = false
    end if

    if m.channelGrid.content <> invalid and m.channelGrid.content.getChildCount() > 0
        m.channelGrid.setFocus(true)
    else
        m.sidebarList.setFocus(true)
    end if
end sub

sub onSearchTextChanged()
    if m.suppressKeyboardObserver = true then return
    m.searchQuery = m.searchKeyboard.text.Trim()
    refreshSidebarState()
    applyFilter(0)
end sub

sub clearSearchFilter()
    m.suppressKeyboardObserver = true
    m.searchKeyboard.text = ""
    m.suppressKeyboardObserver = false
    m.searchQuery = ""
    refreshSidebarState()
    applyFilter(0)
    showToast("Filtro de búsqueda limpiado")
end sub

' =====================================================================
' FAVORITES PERSISTENCE
' =====================================================================

sub loadFavorites()
    m.favorites = {}
    sec = CreateObject("roRegistrySection", "TelesFavorites")
    if sec.Exists("channelIds")
        idsStr = sec.Read("channelIds")
        ids = idsStr.Split(",")
        for each id in ids
            cleanId = id.Trim()
            if cleanId <> "" then m.favorites[cleanId] = cleanId
        end for
    end if
end sub

sub saveFavorites()
    sec = CreateObject("roRegistrySection", "TelesFavorites")
    ids = []
    for each k in m.favorites
        val = m.favorites[k]
        if val <> invalid and val <> ""
            ids.Push(val)
        end if
    end for
    sec.Write("channelIds", ids.Join(","))
    sec.Flush()
end sub

function toggleFavorite(channelId as String) as Boolean
    nowFav = false
    if m.favorites[channelId] <> invalid
        m.favorites.Delete(channelId)
        nowFav = false
    else
        m.favorites[channelId] = channelId
        nowFav = true
    end if
    saveFavorites()
    return nowFav
end function

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

sub handleToggleFavoriteOnGrid()
    gridContent = m.channelGrid.content
    if gridContent = invalid then return

    selectedIndex = m.channelGrid.itemFocused
    if selectedIndex < 0 or selectedIndex >= gridContent.getChildCount() then return

    selectedItem = gridContent.getChild(selectedIndex)
    if selectedItem = invalid or selectedItem.id = "" then return

    channelId = selectedItem.id
    channelTitle = selectedItem.title
    isNowFav = toggleFavorite(channelId)

    refreshSidebarState()

    if isNowFav
        showToast("Agregado a Favoritos: " + channelTitle)
    else
        showToast("Quitado de Favoritos: " + channelTitle)
    end if

    if m.searchQuery = "" and (m.activeCategory = "favorites" or m.activeCategory = "all")
        applyFilter(selectedIndex)
        if m.activeCategory = "all"
            newIndex = findChannelIndexInGrid(channelId)
            if newIndex >= 0
                m.channelGrid.jumpToItem = newIndex
                updateHeroHeaderForIndex(newIndex)
            end if
        else if m.activeCategory = "favorites"
            if m.channelGrid.content = invalid or m.channelGrid.content.getChildCount() = 0
                m.sidebarList.setFocus(true)
            end if
        end if
    else
        ' Update card star badge in place without scrolling/jumping the grid
        selectedItem.isFavorite = isNowFav
        updateHeroHeaderForIndex(selectedIndex)
    end if
end sub

' =====================================================================
' LIVE VIDEO PLAYER, MULTI-SIGNAL FAILOVER & ZAPPING OSD
' =====================================================================

sub onChannelSelected()
    selectedIndex = m.channelGrid.itemSelected
    playChannelAtIndex(selectedIndex, 0)
end sub

sub playChannelAtIndex(gridIndex as Integer, signalIndex as Integer)
    gridContent = m.channelGrid.content
    if gridContent = invalid then return
    total = gridContent.getChildCount()
    if gridIndex < 0 or gridIndex >= total then return

    selectedItem = gridContent.getChild(gridIndex)
    if selectedItem = invalid then return

    signals = []
    if selectedItem.doesExist("signalsJson") and selectedItem.signalsJson <> ""
        parsed = ParseJson(selectedItem.signalsJson)
        if parsed <> invalid and type(parsed) = "roArray"
            signals = parsed
        end if
    end if
    if signals.Count() = 0 and selectedItem.url <> ""
        signals.Push(selectedItem.url)
    end if
    if signals.Count() = 0 then return

    if signalIndex < 0 or signalIndex >= signals.Count()
        signalIndex = 0
    end if

    streamUrl = signals[signalIndex]
    m.currentPlayIndex = gridIndex
    m.currentSignalIndex = signalIndex
    m.currentSignals = signals

    m.videoPlayer.control = "stop"

    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.url = streamUrl
    videoContent.streamFormat = "hls"
    videoContent.title = selectedItem.title
    videoContent.live = true

    m.browseGroup.visible = false
    m.searchModalGroup.visible = false

    m.videoPlayer.content = videoContent
    m.videoPlayer.visible = true
    m.videoPlayer.control = "play"
    m.videoPlayer.setFocus(true)

    showPlayerOsd(selectedItem)
end sub

sub showPlayerOsd(channelNode = invalid as Dynamic)
    if channelNode = invalid
        gridContent = m.channelGrid.content
        if gridContent <> invalid and m.currentPlayIndex >= 0 and m.currentPlayIndex < gridContent.getChildCount()
            channelNode = gridContent.getChild(m.currentPlayIndex)
        end if
    end if

    if channelNode <> invalid
        m.osdChannelTitle.text = channelNode.title
        m.osdMetaLabel.text = channelNode.countryName + "  ·  " + channelNode.catLabel

        sigTotal = m.currentSignals.Count()
        if sigTotal > 1
            m.osdSignalTag.text = "Señal " + StrI(m.currentSignalIndex + 1).Trim() + " de " + StrI(sigTotal).Trim()
            m.osdControlsHint.text = "[Arriba/Abajo] Cambiar canal   [Replay] Cambiar señal   [Atrás] Guía"
        else
            m.osdSignalTag.text = "Señal directa HLS"
            m.osdControlsHint.text = "[Arriba/Abajo] Cambiar canal   [Atrás] Volver a la guía"
        end if
    end if

    m.playerOsd.visible = true
    m.osdTimer.control = "stop"
    m.osdTimer.control = "start"
end sub

sub onOsdTimerFired()
    m.playerOsd.visible = false
end sub

sub zapChannel(delta as Integer)
    gridContent = m.channelGrid.content
    if gridContent = invalid then return
    total = gridContent.getChildCount()
    if total <= 1 then return

    nextIdx = m.currentPlayIndex + delta
    if nextIdx < 0
        nextIdx = total - 1
    else if nextIdx >= total
        nextIdx = 0
    end if

    playChannelAtIndex(nextIdx, 0)
end sub

sub cycleChannelSignal()
    sigTotal = m.currentSignals.Count()
    if sigTotal <= 1
        showPlayerOsd()
        return
    end if

    nextSig = m.currentSignalIndex + 1
    if nextSig >= sigTotal then nextSig = 0

    showToast("Cambiando a Señal " + StrI(nextSig + 1).Trim() + " de " + StrI(sigTotal).Trim())
    playChannelAtIndex(m.currentPlayIndex, nextSig)
end sub

sub onVideoPlayerStateChanged()
    if not m.videoPlayer.visible then return

    state = m.videoPlayer.state
    if state = "error"
        sigTotal = m.currentSignals.Count()
        if (m.currentSignalIndex + 1) < sigTotal
            nextSig = m.currentSignalIndex + 1
            showToast("Señal " + StrI(m.currentSignalIndex + 1).Trim() + " caída · Probando señal " + StrI(nextSig + 1).Trim() + "...")
            playChannelAtIndex(m.currentPlayIndex, nextSig)
        else
            closeVideoPlayer()
            showToast("Señal no disponible en este momento")
        end if
    else if state = "finished"
        closeVideoPlayer()
    end if
end sub

sub closeVideoPlayer()
    m.osdTimer.control = "stop"
    m.playerOsd.visible = false

    m.videoPlayer.visible = false
    m.videoPlayer.control = "stop"
    m.videoPlayer.content = invalid

    m.browseGroup.visible = true

    if m.channelGrid.content <> invalid and m.channelGrid.content.getChildCount() > 0
        if m.currentPlayIndex >= 0 and m.currentPlayIndex < m.channelGrid.content.getChildCount()
            m.channelGrid.jumpToItem = m.currentPlayIndex
            updateHeroHeaderForIndex(m.currentPlayIndex)
        end if
        m.channelGrid.setFocus(true)
    else
        m.sidebarList.setFocus(true)
    end if
end sub

' =====================================================================
' TOAST NOTIFICATIONS
' =====================================================================

sub showToast(message as String)
    m.toastLabel.text = message
    m.toastGroup.visible = true
    m.toastTimer.control = "stop"
    m.toastTimer.control = "start"
end sub

sub onToastTimerFired()
    m.toastGroup.visible = false
end sub

' =====================================================================
' REMOTE KEY HANDLING (STRICTLY SCOPED BY ACTIVE SCREEN STATE)
' =====================================================================

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    ' 1. Loading / Network error state
    if m.isLoading
        return true
    end if
    if m.hasLoadError
        if key = "OK"
            loadChannelsData()
            return true
        end if
        return false
    end if

    ' 2. Fullscreen Video Player state (never leaks focus to background nodes!)
    if m.videoPlayer.visible
        if key = "back"
            closeVideoPlayer()
            return true
        else if key = "up"
            zapChannel(-1)
            return true
        else if key = "down"
            zapChannel(1)
            return true
        else if key = "replay"
            cycleChannelSignal()
            return true
        end if
        return false
    end if

    ' 3. Search Modal state (traps directional navigation cleanly inside modal)
    if m.searchModalGroup.visible
        if key = "back"
            closeSearchModal()
            return true
        else if key = "options"
            m.searchKeyboard.text = ""
            return true
        end if
        return true
    end if

    ' 4. Normal Browse state (Sidebar <-> Channel Grid)
    if m.channelGrid.isInFocusChain()
        if key = "left"
            m.sidebarList.setFocus(true)
            return true
        else if key = "back"
            m.sidebarList.setFocus(true)
            return true
        else if key = "options"
            handleToggleFavoriteOnGrid()
            return true
        end if
    else if m.sidebarList.isInFocusChain()
        if key = "right"
            if m.channelGrid.visible and m.channelGrid.content <> invalid and m.channelGrid.content.getChildCount() > 0
                m.channelGrid.setFocus(true)
                return true
            end if
        else if key = "options"
            if m.searchQuery <> ""
                clearSearchFilter()
                return true
            end if
        else if key = "back"
            if m.searchQuery <> ""
                clearSearchFilter()
                return true
            end if
            ' Let Roku OS exit channel naturally when pressing Back on main sidebar
            return false
        end if
    end if

    return false
end function

sub init()
    m.top.functionName = "fetchJson"
end sub

sub fetchJson()
    url = m.top.url
    if url = "" then return
    
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.InitClientCertificates()
    request.SetUrl(url)
    
    response = request.GetToString()
    
    if response <> ""
        jsonData = ParseJson(response)
        if jsonData <> invalid
            m.top.data = jsonData
            return
        end if
    end if
    
    m.top.data = invalid
end sub

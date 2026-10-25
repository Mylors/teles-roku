sub init()
    m.top.functionName = "fetchJson"
end sub

sub fetchJson()
    url = m.top.url
    if url = ""
        m.top.response = { ok: false, error: "URL vacía" }
        return
    end if

    port = CreateObject("roMessagePort")
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.InitClientCertificates()
    request.EnableEncodings(true)
    request.RetainBodyOnError(true)
    request.SetMessagePort(port)
    request.SetUrl(url)

    if request.AsyncGetToString()
        msg = wait(12000, port)
        if type(msg) = "roUrlEvent"
            code = msg.GetResponseCode()
            body = msg.GetString()
            if code >= 200 and code < 300 and body <> ""
                jsonData = ParseJson(body)
                if jsonData <> invalid and jsonData.channels <> invalid
                    m.top.response = {
                        ok: true,
                        channels: jsonData.channels
                    }
                    return
                end if
                m.top.response = { ok: false, error: "Formato JSON inválido" }
                return
            end if
            m.top.response = { ok: false, error: "HTTP " + StrI(code).Trim() }
            return
        else
            request.AsyncCancel()
            m.top.response = { ok: false, error: "Tiempo de espera agotado" }
            return
        end if
    end if

    m.top.response = { ok: false, error: "No se pudo iniciar la conexión" }
end sub

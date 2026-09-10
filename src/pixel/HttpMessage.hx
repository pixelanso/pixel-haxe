package pixel;

/**
 * Platform bağımsız HTTP protokol yardımcıları.
 * Platform-independent HTTP protocol helpers.
 * Ham istediği ayrıştırma, hedef ayrımı ve durum metinleri burada tutulur;
 * böylece hem sys socket sunucusu hem de Node.js sürücüsü aynı mantığı kullanır.
 * Request parsing, target splitting and status texts live here so both the
 * sys socket server and the Node.js driver share the same logic.
 */
class HttpMessage {
    /**
     * `METHOD /hedef?query HTTP/1.1` biçimindeki target'ı path + query olarak
     * ayrıştırıp bir Request nesnesi kurar.
     * Splits a `METHOD /target?query HTTP/1.1` target into path + query and
     * returns a Request object.
     */
    public static function makeRequest(method:String, target:String, ?headers:Map<String, String>, ?body:String):Request {
        var qIdx = target.indexOf("?");
        var path = qIdx < 0 ? target : target.substr(0, qIdx);
        if (path == "") path = "/";
        var qs = qIdx < 0 ? "" : target.substr(qIdx + 1);

        var req = new Request(method, path, headers, body == null ? "" : body);

        if (qs != "") {
            for (pair in qs.split("&")) {
                if (pair == "") continue;
                var ei = pair.indexOf("=");
                var k = ei >= 0 ? pair.substr(0, ei) : pair;
                var v = ei >= 0 ? pair.substr(ei + 1) : "";
                try {
                    req.query.set(StringTools.urlDecode(k), StringTools.urlDecode(v));
                } catch (e:Dynamic) {
                    req.query.set(k, v);
                }
            }
        }
        return req;
    }

    /**
     * Ham HTTP isteğini (header bloğu + body) Request'e çevirir.
     * Parses a raw HTTP request (headers + body) into a Request.
     * Ayrıştırılamazsa null döndürür. Returns null if it cannot be parsed.
     */
    public static function fromRaw(raw:String):Null<Request> {
        var lines = raw.split("\r\n");
        if (lines.length == 0 || lines[0] == "") return null;

        var first = lines[0];
        var sp1 = first.indexOf(" ");
        if (sp1 <= 0) return null;
        var sp2 = first.indexOf(" ", sp1 + 1);
        var method = first.substr(0, sp1);
        var target = sp2 < 0 ? first.substr(sp1 + 1) : first.substr(sp1 + 1, sp2 - sp1 - 1);
        var version = sp2 < 0 ? "HTTP/1.1" : first.substr(sp2 + 1);

        var headers = new Map<String, String>();
        for (i in 1...lines.length) {
            var line = lines[i];
            if (line == "" || line.indexOf(":") <= 0) continue;
            var ci = line.indexOf(":");
            headers.set(line.substr(0, ci), StringTools.trim(line.substr(ci + 1)));
        }

        var blank = raw.indexOf("\r\n\r\n");
        var body = blank < 0 ? "" : raw.substr(blank + 4);

        var req = makeRequest(method, target, headers, body);
        req.httpVersion = version;
        return req;
    }

    /** Ham HTTP bloğundaki Content-Length başlığını okur. */
    public static function contentLength(raw:String):Int {
        for (line in raw.split("\r\n")) {
            var ci = line.indexOf(":");
            if (ci <= 0) continue;
            if (line.substr(0, ci).toLowerCase() == "content-length") {
                var v = Std.parseInt(StringTools.trim(line.substr(ci + 1)));
                if (v == null) return 0;
                return v < 0 ? 0 : v;
            }
        }
        return 0;
    }

    public static function statusText(code:Int):String {
        return switch (code) {
            case 200: "OK";
            case 201: "Created";
            case 202: "Accepted";
            case 204: "No Content";
            case 301: "Moved Permanently";
            case 302: "Found";
            case 304: "Not Modified";
            case 400: "Bad Request";
            case 401: "Unauthorized";
            case 403: "Forbidden";
            case 404: "Not Found";
            case 405: "Method Not Allowed";
            case 409: "Conflict";
            case 415: "Unsupported Media Type";
            case 422: "Unprocessable Entity";
            case 429: "Too Many Requests";
            case 500: "Internal Server Error";
            case 501: "Not Implemented";
            case 502: "Bad Gateway";
            case 503: "Service Unavailable";
            default: "Status " + code;
        }
    }
}
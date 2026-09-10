package pixel;

/**
 * Gelen isteği temsil eder.
 * Represents an incoming request.
 *
 * Metot, path, query string, header'lar, path parametreleri ve
 * ham (raw) body bilgisini taşır. JSON body `jsonBody()` ile ayrıştırılır.
 * Carries method, path, query string, headers, path params and raw body.
 * The JSON body is parsed with `jsonBody()`.
 */
class Request {
    public var method:String;
    public var path:String;
    public var httpVersion:String;
    public var headers:Map<String, String>;
    public var query:Map<String, String>;
    public var params:Map<String, String>;
    public var rawBody:String;
    /** Istemci IP'si; sunucu doldurur / Client IP; populated by the server. */
    public var ip:String;
    /** Cookie basligindan ayristirilan degerler / Values parsed from the Cookie header. */
    public var cookies:Map<String, String>;

    private var _json:Dynamic;
    private var _jsonParsed:Bool;
    private var _form:Map<String, String>;
    private var _formParsed:Bool;

    public function new(?method:String = "GET", ?path:String = "/", ?headers:Map<String, String> = null, ?rawBody:String = "") {
        this.method = method == null ? "GET" : method;
        this.path = path == null ? "/" : path;
        this.headers = headers == null ? new Map() : headers;
        this.rawBody = rawBody == null ? "" : rawBody;
        this.httpVersion = "HTTP/1.1";
        this.query = new Map();
        this.params = new Map();
        this.cookies = new Map();
        this.ip = "";
        parseCookies();
    }

    public function param(name:String):String {
        return params.get(name) != null ? params.get(name) : "";
    }

    public function queryParam(name:String):String {
        return query.get(name) != null ? query.get(name) : "";
    }

    public function cookie(name:String):Null<String> {
        return cookies.get(name);
    }

    /**
     * Buyuk/kucuk harf farkina duyarsiz header okuma.
     * Case-insensitive header lookup.
     */
    public function getHeader(name:String):Null<String> {
        for (k in headers.keys()) {
            if (k.toLowerCase() == name.toLowerCase()) return headers.get(k);
        }
        return null;
    }

    /**
     * `Authorization: Bearer <token>` basligindan token'i dondurur; yoksa null.
     * Extracts the token from the `Authorization: Bearer <token>` header; null if absent.
     */
    public function bearerToken():Null<String> {
        var h = getHeader("Authorization");
        if (h == null) return null;
        if (StringTools.startsWith(h.toLowerCase(), "bearer ")) {
            return StringTools.trim(h.substr(7));
        }
        return null;
    }

    /** Content-Type JSON mu? / Is the Content-Type JSON? */
    public function isJson():Bool {
        var ct = getHeader("Content-Type");
        return ct != null && ct.toLowerCase().indexOf("application/json") >= 0;
    }

    /**
     * Raw body'yi JSON olarak ayrıştırır. Ayrıştırılamazsa null döner.
     * Parses the raw body as JSON. Returns null if parsing fails.
     */
    public function jsonBody():Dynamic {
        if (!_jsonParsed) {
            _jsonParsed = true;
            try {
                if (rawBody == null || StringTools.trim(rawBody) == "") {
                    _json = null;
                } else {
                    _json = haxe.Json.parse(rawBody);
                }
            } catch (e:Dynamic) {
                _json = null;
            }
        }
        return _json;
    }

    /**
     * `application/x-www-form-urlencoded` govdesini ayrıştırır.
     * Parses an `application/x-www-form-urlencoded` body.
     */
    public function formBody():Map<String, String> {
        if (!_formParsed) {
            _formParsed = true;
            _form = new Map();
            if (rawBody != null && rawBody != "") {
                for (pair in rawBody.split("&")) {
                    if (pair == "") continue;
                    var ei = pair.indexOf("=");
                    var k = ei >= 0 ? pair.substr(0, ei) : pair;
                    var v = ei >= 0 ? pair.substr(ei + 1) : "";
                    try {
                        _form.set(StringTools.urlDecode(k), StringTools.urlDecode(v));
                    } catch (e:Dynamic) {
                        _form.set(k, v);
                    }
                }
            }
        }
        return _form;
    }

    function parseCookies():Void {
        var raw = getHeader("Cookie");
        if (raw == null) return;
        for (pair in raw.split(";")) {
            var t = StringTools.trim(pair);
            if (t == "") continue;
            var ei = t.indexOf("=");
            if (ei <= 0) continue;
            cookies.set(t.substr(0, ei), t.substr(ei + 1));
        }
    }

    public function toString():String {
        return method + " " + path;
    }
}

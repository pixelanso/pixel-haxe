package pixel;

/**
 * Gelen isteği temsil eder.
 *
 * Metot, path, query string, header'lar, path parametreleri ve
 * ham (raw) body bilgisini taşır. JSON body `jsonBody()` ile ayrıştırılır.
 */
class Request {
    public var method:String;
    public var path:String;
    public var httpVersion:String;
    public var headers:Map<String, String>;
    public var query:Map<String, String>;
    public var params:Map<String, String>;
    public var rawBody:String;

    private var _json:Dynamic;
    private var _jsonParsed:Bool;

    public function new(?method:String = "GET", ?path:String = "/", ?headers:Map<String, String> = null, ?rawBody:String = "") {
        this.method = method == null ? "GET" : method;
        this.path = path == null ? "/" : path;
        this.headers = headers == null ? new Map() : headers;
        this.rawBody = rawBody == null ? "" : rawBody;
        this.httpVersion = "HTTP/1.1";
        this.query = new Map();
        this.params = new Map();
    }

    public function param(name:String):String {
        return params.get(name) != null ? params.get(name) : "";
    }

    public function queryParam(name:String):String {
        return query.get(name) != null ? query.get(name) : "";
    }

    /**
     * Büyük/küçük harf farkına duyarsız header okuma.
     */
    public function getHeader(name:String):Null<String> {
        for (k in headers.keys()) {
            if (k.toLowerCase() == name.toLowerCase()) return headers.get(k);
        }
        return null;
    }

    /**
     * Raw body'yi JSON olarak ayrıştırır. Ayrıştırılamazsa null döner.
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

    public function toString():String {
        return method + " " + path;
    }
}
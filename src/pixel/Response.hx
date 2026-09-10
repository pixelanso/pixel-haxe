package pixel;

import haxe.io.Bytes;

/**
 * Yanıtı temsil eder. Zincirleme kullanım destekler.
 * Represents a response. Supports chaining:
 *
 * ```haxe
 * res.status(201).json({ ok:true });
 * ```
 */
class Response {
    public var statusCode:Int;
    public var headers:Map<String, String>;
    public var body:Bytes;
    public var sent:Bool;
    /** Gonderilecek `Set-Cookie` degerleri / `Set-Cookie` values to send. */
    public var cookiesToSet:Array<String>;

    public function new() {
        statusCode = 200;
        headers = new Map();
        body = Bytes.alloc(0);
        sent = false;
        cookiesToSet = [];
    }

    public function status(code:Int):Response {
        statusCode = code;
        return this;
    }

    public function header(name:String, value:String):Response {
        headers.set(name, value);
        return this;
    }

    /**
     * Cookie ekler / Appends a cookie.
     * ```haxe
     * res.setCookie("sid", "abc123", 3600);
     * ```
     */
    public function setCookie(name:String, value:String, ?maxAge:Int = null, ?path:String = "/"):Response {
        var c = name + "=" + value + "; Path=" + (path == null ? "/" : path);
        if (maxAge != null) c += "; Max-Age=" + maxAge;
        cookiesToSet.push(c);
        return this;
    }

    /**
     * Cookie'yi kaldirir (Max-Age=0) / Clears a cookie (Max-Age=0).
     */
    public function clearCookie(name:String, ?path:String = "/"):Response {
        cookiesToSet.push(name + "=; Path=" + (path == null ? "/" : path) + "; Max-Age=0");
        return this;
    }


    public function text(value:String):Response {
        body = Bytes.ofString(value);
        if (!headers.exists("Content-Type")) {
            headers.set("Content-Type", "text/plain; charset=utf-8");
        }
        sent = true;
        return this;
    }

    public function html(value:String):Response {
        body = Bytes.ofString(value);
        headers.set("Content-Type", "text/html; charset=utf-8");
        sent = true;
        return this;
    }

    public function json(value:Dynamic):Response {
        body = Bytes.ofString(haxe.Json.stringify(value, null, "  "));
        headers.set("Content-Type", "application/json; charset=utf-8");
        sent = true;
        return this;
    }

    public function sendBytes(bytes:Bytes, ?contentType:String = null):Response {
        body = bytes;
        if (contentType != null) headers.set("Content-Type", contentType);
        sent = true;
        return this;
    }

    public function redirect(location:String):Response {
        status(302).header("Location", location);
        sent = true;
        return this;
    }

    public function notFound():Response {
        return status(404).json({error: "Not Found"});
    }

    public function serverError(?message:String = "Internal Server Error"):Response {
        return status(500).json({error: message});
    }
}
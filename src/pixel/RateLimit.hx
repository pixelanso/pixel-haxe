package pixel;

/**
 * Bellek ici kayan pencere hiz sinirlayici.
 * In-memory sliding window rate limiter.
 *
 * Anahtar olarak `X-Forwarded-For` basligi, yoksa istemci IP'si kullanilir.
 * Uses the `X-Forwarded-For` header as the key, or the client IP.
 *
 * ```haxe
 * app.use(new RateLimit(60, 60).middleware()); // 60 istek / dakika
 * ```
 */
class RateLimit {
    public var maxRequests:Int;
    public var windowSec:Float;

    var hits:Map<String, Array<Float>>;

    public function new(?maxRequests:Int = 60, ?windowSec:Float = 60.0) {
        this.maxRequests = maxRequests < 1 ? 1 : maxRequests;
        this.windowSec = windowSec <= 0 ? 60.0 : windowSec;
        hits = new Map();
    }

    /** Limitleyiciyi middleware olarak dondurur / Wraps the limiter as middleware. */
    public function middleware():Middleware {
        return new Middleware(function(req:Request, res:Response, next:Void -> Void) {
            var left = remaining(req);
            res.header("X-RateLimit-Limit", Std.string(maxRequests));
            if (!allow(req)) {
                res.header("X-RateLimit-Remaining", "0");
                res.status(429)
                    .header("Retry-After", Std.string(Math.ceil(windowSec)))
                    .json({error: "Too Many Requests / Cok fazla istek"});
                return;
            }
            res.header("X-RateLimit-Remaining", Std.string(left));
            next();
        });
    }

    /** Kalan istek hakki / Remaining request quota for the client. */
    public function remaining(req:Request):Int {
        var arr = hits.get(clientKey(req));
        if (arr == null) return maxRequests;
        prune(arr, Platform.time());
        var left = maxRequests - arr.length;
        return left < 0 ? 0 : left;
    }

    /** Isteg izinli mi? / Is this request allowed? */
    public function allow(req:Request):Bool {
        var now = Platform.time();
        var key = clientKey(req);
        var arr = hits.get(key);
        if (arr == null) {
            arr = [];
            hits.set(key, arr);
        }
        prune(arr, now);
        if (arr.length >= maxRequests) return false;
        arr.push(now);
        return true;
    }

    function prune(arr:Array<Float>, now:Float):Void {
        var i = 0;
        while (i < arr.length) {
            if (now - arr[i] > windowSec) {
                arr.splice(i, 1);
            } else {
                i++;
            }
        }
    }

    /** Sinir anahtari / Rate limit key. */
    public static function clientKey(req:Request):String {
        var fwd = req.getHeader("X-Forwarded-For");
        if (fwd != null && StringTools.trim(fwd) != "") {
            return StringTools.trim(fwd.split(",")[0]);
        }
        if (req.ip != null && req.ip != "") return req.ip;
        return "unknown";
    }
}

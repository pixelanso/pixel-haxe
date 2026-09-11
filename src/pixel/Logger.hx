package pixel;

/**
 * Istek loglama middleware'i.
 * Request logging middleware.
 *
 * Her istek icin `DURUM METOT YOL sure` biciminde satir yazdirir:
 * Prints a `STATUS METHOD PATH duration` line per request:
 *
 * ```haxe
 * app.use(new pixel.Logger().middleware());
 * // 200 GET /api/users 3ms
 * ```
 */
class Logger {
    /** Istege ozel prefix, ornek: "[api] " / Per-request prefix, e.g. "[api] ". */
    public var prefix:String;

    public function new(?prefix:String = "") {
        this.prefix = prefix == null ? "" : prefix;
    }

    /**
     * Middleware ornegini dondurur.
     * Returns the middleware instance.
     */
    public function middleware():Middleware {
        var self = this;
        return new Middleware(function(req:Request, res:Response, next:Void -> Void) {
            var start = Platform.time();
            next();
            var ms = Math.round((Platform.time() - start) * 1000);
            var line = self.prefix + res.statusCode + " " + req.method + " " + req.path + " " + ms + "ms";
            Platform.println(line);
        });
    }
}

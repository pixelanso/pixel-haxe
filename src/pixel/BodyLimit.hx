package pixel;

/**
 * Istek govdesi boyutunu sinirlayan middleware.
 * Middleware that caps the request body size.
 *
 * Sinir asilirsa `next()` cagrilmaz ve 413 dondurur:
 * When the limit is exceeded, `next()` is skipped and 413 is returned:
 *
 * ```haxe
 * app.use(new pixel.BodyLimit(1024 * 1024).middleware()); // 1 MB
 * ```
 */
class BodyLimit {
    public var maxBytes:Int;

    public function new(?maxBytes:Int = 1048576) {
        this.maxBytes = maxBytes;
    }

    public function middleware():Middleware {
        var self = this;
        return new Middleware(function(req:Request, res:Response, next:Void -> Void) {
            var size = req.rawBody == null ? 0 : req.rawBody.length;
            if (size > self.maxBytes) {
                res.status(413).json({
                    error: "Payload Too Large / Cok buyuk istek govdesi",
                    maxBytes: self.maxBytes
                });
                return;
            }
            next();
        });
    }
}

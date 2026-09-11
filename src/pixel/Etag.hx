package pixel;

import haxe.io.Bytes;

/**
 * ETag tabanli kollayici onbellek: yanit govdesinden MD5 uretip `ETag`
 * basligini ekler; istek `If-None-Match` ile ayni etagi tasiyorsa
 * bos govdeyle 304 dondurur.
 * ETag-based conditional caching: computes an MD5 from the response body,
 * sets the `ETag` header and answers 304 with an empty body when the request
 * carries a matching `If-None-Match`.
 *
 * Yalnizca GET/HEAD ve 2xx yanitlar icin calisir.
 * Applies only to GET/HEAD requests with 2xx responses.
 *
 * ```haxe
 * app.use(new Etag().middleware());
 * ```
 */
class Etag {
    public function new() {}

    public function middleware():Middleware {
        return new Middleware(function(req:Request, res:Response, next:Void -> Void) {
            next();
            apply(req, res);
        });
    }

    /** Yanita ETag uygular, uygulanabilirse 304 dondurur / Applies ETag, may rewrite to 304. */
    public function apply(req:Request, res:Response):Void {
        if (res.statusCode < 200 || res.statusCode >= 300) return;
        if (res.body == null || res.body.length == 0) return;
        var m = req.method.toUpperCase();
        if (m != "GET" && m != "HEAD") return;

        var etag = 'W/"' + haxe.crypto.Md5.make(res.body).toHex() + '"';
        res.header("ETag", etag);

        var inm = req.getHeader("If-None-Match");
        if (inm == null) return;
        for (candidate in inm.split(",")) {
            var c = StringTools.trim(candidate);
            if (c == "*" || c == etag || c == etag.substr(2)) {
                res.status(304);
                res.body = Bytes.alloc(0);
                res.headers.remove("Content-Type");
                return;
            }
        }
    }
}

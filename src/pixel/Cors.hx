package pixel;

import pixel.Request;
import pixel.Response;

/**
 * CORS (Cross-Origin Resource Sharing) yardımcısı.
 * CORS (Cross-Origin Resource Sharing) helper.
 *
 * `Pixel.create().cors()` ile etkinleştirilir; preflight (OPTIONS)
 * isteklerini de otomatik yanıtlar.
 * Enabled with `Pixel.create().cors()`; also answers preflight (OPTIONS) requests.
 */
class Cors {
    public var allowedOrigin:String;
    public var allowedMethods:String;
    public var allowedHeaders:String;

    public function new() {
        allowedOrigin = "*";
        allowedMethods = "GET, POST, PUT, DELETE, PATCH, OPTIONS";
        allowedHeaders = "Content-Type, Authorization, X-Requested-With, Accept";
    }

    public function apply(req:Request, res:Response):Void {
        res.header("Access-Control-Allow-Origin", allowedOrigin);
        res.header("Access-Control-Allow-Methods", allowedMethods);
        res.header("Access-Control-Allow-Headers", allowedHeaders);
        res.header("Access-Control-Max-Age", "86400");

        if (req.method.toUpperCase() == "OPTIONS") {
            var requested = req.getHeader("Access-Control-Request-Headers");
            if (requested != null) {
                res.header("Access-Control-Allow-Headers", requested);
            }
            if (req.getHeader("Access-Control-Request-Method") != null) {
                res.status(204).text("");
            }
        }
    }
}
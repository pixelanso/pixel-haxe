package pixel;

import pixel.Route;

/**
 * Rotaları tutar ve gelen isteği en uygun rotayla eşler.
 * Holds routes and resolves an incoming request to the best match.
 */
class Router {
    public var routes:Array<Route>;

    public function new() {
        routes = [];
    }

    public function add(method:String, path:String, handler:(Request, Response) -> Void):Void {
        routes.push(new Route(method, path, handler));
    }

    public function resolve(method:String, path:String):Null<{route:Route, params:Map<String, String>}> {
        for (r in routes) {
            if (!r.matchesMethod(method)) continue;
            var params = r.matchParams(path);
            if (params != null) {
                return { route: r, params: params };
            }
        }
        return null;
    }

    /**
     * Verilen path ile eslesen (catch-all haric) HTTP metotlarini dondurur;
     * 405 `Allow` basligi icin kullanilir.
     * Returns the HTTP methods (excluding catch-alls) matching the path;
     * used for 405 `Allow` headers.
     */
    public function allowedMethods(path:String):Array<String> {
        var out = new Array<String>();
        for (r in routes) {
            if (r.method == "*") continue;
            if (r.matchParams(path) == null) continue;
            var m = r.method.toUpperCase();
            var exists = false;
            for (e in out) {
                if (e == m) {
                    exists = true;
                    break;
                }
            }
            if (!exists) out.push(m);
        }
        return out;
    }


    public static function normPath(path:String):String {
        if (path == null || path == "") return "/";
        var p = path;
        if (p.length > 1 && p.charAt(p.length - 1) == "/") p = p.substr(0, p.length - 1);
        return p;
    }

    public static function splitPath(path:String):Array<String> {
        var out = [];
        for (part in path.split("/")) {
            if (part.length > 0) out.push(part);
        }
        return out;
    }
}
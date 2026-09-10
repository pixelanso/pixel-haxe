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
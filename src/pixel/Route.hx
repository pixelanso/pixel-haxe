package pixel;

import pixel.Router;

/**
 * Yönlendirme tablosundaki tek rota kaydı.
 * A single route entry in the routing table.
 *
 * `pattern` içinde `:param` segmentleri dinamik yakalanır,
 * `*` ise geri kalan her şeyi yakalar (catch-all).
 * `:param` segments are captured dynamically; `*` matches the rest (catch-all).
 */
class Route {
    public var method:String;
    public var pattern:String;
    public var segments:Array<String>;
    public var handler:(Request, Response) -> Void;
    /** Rotaya ozel middleware zinciri / Route-scoped middleware chain. */
    public var middleware:Array<Middleware>;

    public function new(method:String, pattern:String, handler:(Request, Response) -> Void) {
        this.method = method;
        this.pattern = pattern;
        this.segments = Router.splitPath(Router.normPath(pattern));
        this.handler = handler;
        this.middleware = [];
    }

    public function matchesMethod(m:String):Bool {
        if (method == "*") return true;
        var lm = m.toLowerCase();
        if (method.toLowerCase() == lm) return true;
        // HEAD, GET rotasina dusmeli / HEAD falls back to GET routes
        if (lm == "head" && method.toLowerCase() == "get") return true;
        return false;
    }


    /**
     * Verilen path ile eşleşirse yakalanan parametreleri (Map) döndürür,
     * eşleşmezse null döndürür.
     * Returns the captured params (Map) if the given path matches,
     * or null if it does not match.
     */
    public function matchParams(path:String):Null<Map<String, String>> {
        var segs = Router.splitPath(Router.normPath(path));
        var params = new Map<String, String>();
        var pi = 0;
        for (si in 0...segs.length) {
            if (pi >= segments.length) return null;
            var pat = segments[pi];
            if (pat == "*") return params; // catch-all: gerisini kabul et / accept the rest
            if (pat.length > 1 && pat.charAt(0) == ":") {
                params.set(pat.substr(1), segs[si]);
            } else if (pat != segs[si]) {
                return null;
            }
            pi++;
        }
        if (pi < segments.length) return null;
        return params;
    }

    public function toString():String {
        return method + " " + pattern;
    }
}
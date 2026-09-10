package pixel;

/**
 * Ortak prefix altinda rota tanimlama grubu.
 * Route group that registers routes under a shared prefix.
 *
 * Gruba eklenen middleware'ler o gruptaki her rotaya baglanir.
 * Middleware added to the group is attached to every route in the group.
 *
 * ```haxe
 * app.group("/api/v1", function(v1) {
 *     v1.get("/ping", handler);      // GET /api/v1/ping
 *     v1.use(Auth.bearer(tokens));   // gruba ozel koruma / group-scoped protection
 * });
 * ```
 */
class RouteGroup {
    public var app:Pixel;
    public var prefix:String;

    var pending:Array<Middleware>;

    public function new(app:Pixel, prefix:String) {
        this.app = app;
        this.prefix = Router.normPath(prefix == null ? "" : prefix);
        this.pending = [];
    }

    /**
     * Gruba ozel middleware ekler; sonrasinda eklenen rotalara uygulanir.
     * Ham fonksiyon veya Middleware nesnesi kabul eder.
     * Adds group-scoped middleware; applies to routes added afterwards.
     * Accepts a raw function or a Middleware instance.
     */
    public function use(handler:Dynamic):RouteGroup {
        var mw:Middleware = Std.isOfType(handler, Middleware)
            ? cast(handler, Middleware)
            : new Middleware(cast handler);
        pending.push(mw);
        return this;
    }


    public function get(path:String, handler:(Request, Response) -> Void):RouteGroup {
        return add("GET", path, handler);
    }

    public function post(path:String, handler:(Request, Response) -> Void):RouteGroup {
        return add("POST", path, handler);
    }

    public function put(path:String, handler:(Request, Response) -> Void):RouteGroup {
        return add("PUT", path, handler);
    }

    public function delete(path:String, handler:(Request, Response) -> Void):RouteGroup {
        return add("DELETE", path, handler);
    }

    public function patch(path:String, handler:(Request, Response) -> Void):RouteGroup {
        return add("PATCH", path, handler);
    }

    public function all(path:String, handler:(Request, Response) -> Void):RouteGroup {
        return add("*", path, handler);
    }

    function add(method:String, path:String, handler:(Request, Response) -> Void):RouteGroup {
        var route = new Route(method, join(path), handler);
        for (m in pending) {
            route.middleware.push(m);
        }
        app.router.routes.push(route);
        return this;
    }

    function join(path:String):String {
        var p = Router.normPath(path == null ? "" : path);
        if (prefix == "" || prefix == "/") return p;
        if (p == "/" || p == "") return prefix;
        return prefix + p;
    }
}

package pixel;

import pixel.Router;
import pixel.Route;
import pixel.Middleware;
import pixel.Request;
import pixel.Response;
import pixel.Cors;
import pixel.Static;
import pixel.Server;

/**
 * Pixel Api — hafif ve çok hedefli Haxe API mikro-framework'ü.
 * Pixel Api — a lightweight, multi-target Haxe API micro-framework.
 *
 * Basit kullanım / Quick usage:
 *
 * ```haxe
 * var app = Pixel.create();
 *
 * app.cors();
 * app.use(function(req, res, next) { Platform.println(req.toString()); next(); });
 *
 * app.get("/", function(req, res) {
 *     res.json({ message: "Merhaba Pixel! / Hello Pixel!" });
 * });
 *
 * app.get("/api/users/:id", function(req, res) {
 *     res.json({ id: req.param("id") });
 * });
 *
 * app.listen(8080);
 * ```
 *
 * Tek bir kod tabanıyla Node.js, PHP, Neko ve HashLink üzerinde çalışır.
 * Runs on Node.js, PHP, Neko and HashLink with a single codebase.
 */
class Pixel {
    public var router:Router;
    public var middleware:Array<Middleware>;

    /** Ozel 404 isleyici / Custom 404 handler. */
    public var onNotFoundHandler:(Request, Response) -> Void;
    /** Ozel hata isleyici / Custom error handler. */
    public var onErrorHandler:(Request, Response, Dynamic) -> Void;
    /** Ozel 405 isleyici / Custom 405 handler. */
    public var onMethodNotAllowedHandler:(Request, Response, Array<String>) -> Void;

    private var corsInstance:Cors;
    private var staticEnabled:Bool;
    private var staticDir:String;
    private var staticPrefix:String;


    public function new() {
        router = new Router();
        middleware = [];
        corsInstance = null;
        staticEnabled = false;
        staticDir = "public";
        staticPrefix = "/";
    }

    public static function create():Pixel {
        return new Pixel();
    }

    // -------------------------------------------------------------- routes

    public function get(path:String, handler:(Request, Response) -> Void):Pixel {
        return _add("GET", path, handler);
    }

    public function post(path:String, handler:(Request, Response) -> Void):Pixel {
        return _add("POST", path, handler);
    }

    public function put(path:String, handler:(Request, Response) -> Void):Pixel {
        return _add("PUT", path, handler);
    }

    public function delete(path:String, handler:(Request, Response) -> Void):Pixel {
        return _add("DELETE", path, handler);
    }

    public function patch(path:String, handler:(Request, Response) -> Void):Pixel {
        return _add("PATCH", path, handler);
    }

    public function all(path:String, handler:(Request, Response) -> Void):Pixel {
        return _add("*", path, handler);
    }

    private inline function _add(method:String, path:String, handler:(Request, Response) -> Void):Pixel {
        router.add(method, path, handler);
        return this;
    }

    // ------------------------------------------------------------ middleware

    /**
     * Global middleware ekler; ham fonksiyon veya Middleware nesnesi kabul eder.
     * Adds a global middleware; accepts a raw function or a Middleware instance.
     * ```haxe
     * app.use(function(req, res, next) { ...; next(); });
     * app.use(new RateLimit(60, 60).middleware());
     * ```
     */
    public function use(handler:Dynamic):Pixel {
        var mw:Middleware = Std.isOfType(handler, Middleware)
            ? cast(handler, Middleware)
            : new Middleware(cast handler);
        middleware.push(mw);
        return this;
    }


    /**
     * Ortak prefix altinda rota grubu olusturur.
     * Creates a route group under a common prefix.
     * ```haxe
     * app.group("/api/v1", function(v1) {
     *     v1.get("/ping", function(req, res) { res.json({pong:true}); });
     * });
     * ```
     */
    public function group(prefix:String, fn:(RouteGroup) -> Void):Pixel {
        fn(new RouteGroup(this, prefix));
        return this;
    }

    /**
     * Ozel 404 (rota bulunamadi) isleyicisi atar.
     * Sets a custom 404 (route not found) handler.
     */
    public function onNotFound(handler:(Request, Response) -> Void):Pixel {
        onNotFoundHandler = handler;
        return this;
    }

    /**
     * Ozel 405 (metot izinli degil) isleyicisi atar.
     * Sets a custom 405 (method not allowed) handler.
     */
    public function onMethodNotAllowed(handler:(Request, Response, Array<String>) -> Void):Pixel {
        onMethodNotAllowedHandler = handler;
        return this;
    }

    /**
     * Ozel hata isleyicisi atar; atanmazsa varsayilan 500 doner.
     * Sets a custom error handler; defaults to a 500 response when absent.
     */
    public function onError(handler:(Request, Response, Dynamic) -> Void):Pixel {
        onErrorHandler = handler;
        return this;
    }


    // ------------------------------------------------------------ özellikler / features

    /** CORS'u varsayılan ayarlarla etkinleştirir. Enables CORS with default settings. */
    public function cors():Pixel {
        corsInstance = new Cors();
        return this;
    }

    /** Statik dosya servisi: `public/` klasörünü sunar. Serves static files from `public/`. */
    public function serveStatic(dir:String, ?prefix:String = "/"):Pixel {
        staticEnabled = true;
        staticDir = dir;
        staticPrefix = prefix == null ? "/" : prefix;
        return this;
    }

    // -------------------------------------------------------------- server

    public function listen(port:Int = 8080, ?host:String = null):Void {
        if (host == null) host = "0.0.0.0";
        Server.run(this, port, host);
    }

    // ------------------------------------------------------ request pipeline

    /**
     * İsteği işler: CORS -> statik -> middleware zinciri -> rota.
     * Processes a request: CORS -> static -> middleware chain -> route.
     * Testlerde Request'i elle kurup çağırmak da mümkündür.
     * In tests you can build a Request manually and call this.
     */
    public function handle(req:Request, res:Response):Void {
        if (corsInstance != null) corsInstance.apply(req, res);
        if (req.method.toUpperCase() == "OPTIONS" && req.getHeader("Access-Control-Request-Method") != null) {
            return; // preflight — middleware'ler atlanır / middleware is skipped
        }
        if (staticEnabled) {
            if (Static.serve(req, res, staticDir, staticPrefix)) return;
        }
        runChain(0, req, res);
    }

    private function runChain(i:Int, req:Request, res:Response):Void {
        if (i < middleware.length) {
            middleware[i].handler(req, res, function() {
                runChain(i + 1, req, res);
            });
        } else {
            route(req, res);
        }
    }

    private function route(req:Request, res:Response):Void {
        var resolved = router.resolve(req.method, req.path);

        // catch-all'a dusmeden once 405 kontrolu / check 405 before falling into the catch-all
        if (resolved == null || resolved.route.method == "*") {
            var allowed = router.allowedMethods(req.path);
            if (allowed.length > 0) {
                methodNotAllowed(req, res, allowed);
                return;
            }
        }

        if (resolved == null) {
            if (onNotFoundHandler != null) {
                onNotFoundHandler(req, res);
            } else {
                res.notFound();
            }
            return;
        }

        req.params = resolved.params;
        runRoute(0, req, res, resolved.route);
    }

    function methodNotAllowed(req:Request, res:Response, allowed:Array<String>):Void {
        if (onMethodNotAllowedHandler != null) {
            onMethodNotAllowedHandler(req, res, allowed);
            return;
        }
        res.status(405)
            .header("Allow", allowed.join(", "))
            .json({error: "Method Not Allowed / Izin verilmeyen metot", allow: allowed});
    }

    /**
     * Once rotaya ozel middleware, sonra handler calisir.
     * Route-scoped middleware runs first, then the handler.
     */
    private function runRoute(i:Int, req:Request, res:Response, r:Route):Void {
        if (i < r.middleware.length) {
            r.middleware[i].handler(req, res, function() {
                runRoute(i + 1, req, res, r);
            });
        } else {
            try {
                r.handler(req, res);
            } catch (e:Dynamic) {
                if (onErrorHandler != null) {
                    onErrorHandler(req, res, e);
                } else {
                    res.serverError(Std.string(e));
                }
            }
        }
    }
}

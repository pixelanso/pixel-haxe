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
 * Pixel Api — hafif ve çok hedefli Haxe API mikro-framework'ü. 🎨
 *
 * Basit kullanım:
 *
 * ```haxe
 * var app = Pixel.create();
 *
 * app.cors();
 * app.use(function(req, res, next) { Sys.println(req.toString()); next(); });
 *
 * app.get("/", function(req, res) {
 *     res.json({ message: "Merhaba Pixel!" });
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
 */
class Pixel {
    public var router:Router;
    public var middleware:Array<Middleware>;

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
     * Global middleware ekler.
     * ```haxe
     * app.use(function(req, res, next) { ...; next(); });
     * ```
     */
    public function use(handler:(Request, Response, Void -> Void) -> Void):Pixel {
        middleware.push(new Middleware(handler));
        return this;
    }

    // ------------------------------------------------------------ özellikler

    /** CORS'u varsayılan ayarlarla etkinleştirir. */
    public function cors():Pixel {
        corsInstance = new Cors();
        return this;
    }

    /** Statik dosya servisi: `public/` klasörünü sunar. */
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
     * Testlerde Request'i elle kurup çağırmak da mümkündür.
     */
    public function handle(req:Request, res:Response):Void {
        if (corsInstance != null) corsInstance.apply(req, res);
        if (req.method.toUpperCase() == "OPTIONS" && req.getHeader("Access-Control-Request-Method") != null) {
            return; // preflight — middleware'ler atlanır
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
        if (resolved == null) {
            res.notFound();
            return;
        }
        req.params = resolved.params;
        try {
            resolved.route.handler(req, res);
        } catch (e:Dynamic) {
            res.serverError(Std.string(e));
        }
    }
}
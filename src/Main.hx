import pixel.Pixel;
import pixel.Request;
import pixel.Response;
import pixel.Platform;

/**
 * Örnek uygulama — Pixel Api'ın kullanımını gösterir.
 * Example app — demonstrates Pixel Api usage.
 *
 * Derle / Compile:    haxe build-node.hxml
 * Çalıştır / Run:     node bin/Node/server.js
 */
class Main {
    static var users:Array<Dynamic> = [
        {id: "1", name: "Ayşe", role: "admin"},
        {id: "2", name: "Mehmet", role: "user"},
        {id: "3", name: "Zeynep", role: "moderator"}
    ];

    static function main() {
        var app = Pixel.create();

        // 1) Global middleware — istek logu / request logging
        app.use(function(req:Request, res:Response, next:Void->Void) {
            Platform.println("--> [" + req.method + "] " + req.path);
            next();
        });

        // 2) Global hiz siniri / global rate limit: dakikada 240 istek
        app.use(new pixel.RateLimit(240, 60).middleware());

        // 3) CORS (herkese acik ve preflight dahil / open and including preflight)
        app.cors();

        // 4) Rotalar / Routes
        app.get("/", function(req, res) {
            res.json({
                name: "Pixel Api",
                version: "0.2.0",
                description: "Hafif ve cok hedefli Haxe API mikro-framework'unun ornek uygulamasi / Sample app for the lightweight, multi-target Haxe API micro-framework",
                endpoints: {
                    root: "GET /",
                    health: "GET /health",
                    listUsers: "GET /api/users",
                    getUser: "GET /api/users/:id",
                    createUser: "POST /api/users",
                    updateUser: "PUT /api/users/:id",
                    deleteUser: "DELETE /api/users/:id",
                    v1Ping: "GET /api/v1/ping",
                    v1Time: "GET /api/v1/time",
                    adminStats: "GET /admin/stats (Bearer token gerekli / Bearer token required)"
                }
            });
        });


        app.get("/health", function(req, res) {
            res.json({status: "ok", uptime: Platform.time()});
        });

        app.get("/api/users", function(req, res) {
            res.json(users);
        });

        app.get("/api/users/:id", function(req, res) {
            var id = req.param("id");
            for (u in users) {
                if (u.id == id) {
                    res.json(u);
                    return;
                }
            }
            res.status(404).json({error: "User not found / Kullanici bulunamadi", id: id});
        });

        app.post("/api/users", function(req, res) {
            var body = req.jsonBody();
            if (body == null) {
                res.status(400).json({error: "Gecerli bir JSON body gonderilmeli / A valid JSON body is required"});
                return;
            }
            var name = Reflect.field(body, "name");
            if (name == null || name == "") {
                res.status(422).json({error: "'name' alani zorunludur / 'name' field is required"});
                return;
            }
            var u = {id: Std.string(users.length + 1), name: name, role: "user"};
            users.push(u);
            res.status(201).json(u);
        });

        app.put("/api/users/:id", function(req, res) {
            var id = req.param("id");
            var body = req.jsonBody();
            for (u in users) {
                if (u.id == id) {
                    if (body != null && Reflect.field(body, "name") != null) u.name = Reflect.field(body, "name");
                    if (body != null && Reflect.field(body, "role") != null) u.role = Reflect.field(body, "role");
                    res.json(u);
                    return;
                }
            }
            res.status(404).json({error: "User not found / Kullanici bulunamadi", id: id});
        });

        app.delete("/api/users/:id", function(req, res) {
            var id = req.param("id");
            for (i in 0...users.length) {
                if (users[i].id == id) {
                    users.splice(i, 1);
                    res.status(204).text("");
                    return;
                }
            }
            res.status(404).json({error: "User not found / Kullanici bulunamadi", id: id});
        });

        // 5) Rota grubu: ortak prefix / route group with a shared prefix
        app.group("/api/v1", function(v1:pixel.RouteGroup) {
            v1.get("/ping", function(req, res) {
                res.json({pong: true, version: "v1"});
            });
            v1.get("/time", function(req, res) {
                res.json({now: Platform.time()});
            });
        });

        // 6) Korunan grup: Bearer token ile / protected group with Bearer token
        //    Test / Try it:
        //    curl -H "Authorization: Bearer super-secret-token" http://localhost:8080/admin/stats
        app.group("/admin", function(admin:pixel.RouteGroup) {
            admin.use(pixel.Auth.bearer(["super-secret-token"]));
            admin.get("/stats", function(req, res) {
                res.json({users: users.length, uptime: Platform.time()});
            });
        });

        // 7) Cookie ornegi / cookie example
        app.get("/api/visit", function(req, res) {
            var seen = req.cookie("visits");
            var count = seen == null ? 1 : Std.parseInt(seen) + 1;
            res.setCookie("visits", Std.string(count), 3600);
            res.json({visits: count});
        });

        // 8) Ozel 404 isleyicisi / custom 404 handler
        app.onNotFound(function(req, res) {
            res.status(404).json({
                error: "Not Found / Bulunamadi",
                path: req.path,
                hint: "GET / tum uc noktalari listeler / lists all endpoints"
            });
        });

        // 9) Statik dosyalar / Static files (public/)
        app.serveStatic("public");

        // 10) Dinle / Listen
        var port = Std.parseInt(Platform.getEnv("PORT"));
        if (port == null) port = 8080;
        Platform.println("Pixel Api configured / konfigurasyonu hazir. PORT=" + port);
        app.listen(port);
    }
}
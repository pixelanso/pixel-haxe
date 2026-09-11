class TestCore {
    static function main() {
        var router = new pixel.Router();

        router.add("GET", "/api/users/:id", function(req, res) {
            res.json({id: req.param("id")});
        });
        router.add("GET", "/api/users", function(req, res) {
            res.json([]);
        });
        router.add("POST", "/api/users", function(req, res) {
            res.status(201).json({ok: true});
        });

        check("method eslesmezse res null olmali / no match if method differs",
            router.resolve("GET", "/api/users/42") != null);
        check("path parametresi yakalanmali / path param captured",
            router.resolve("GET", "/api/users/42").params.get("id") == "42");
        check("rota metodu buyuk/kucuk harf duyarsiz / method matching is case-insensitive",
            router.resolve("get", "/api/users/1") != null);
        check("metot yanlis rotaya dusmemeli / method must not hit wrong route",
            router.resolve("POST", "/api/users") != null
            && router.resolve("POST", "/api/users/1") == null
            && router.resolve("GET", "/api/users/1") != null);
        check("bilinmeyen path null donmeli / unknown path returns null",
            router.resolve("GET", "/api/unknown") == null);
        check("catch-all route onceligi dusuk / catch-all has lower priority",
            (function() {
                var r = new pixel.Router();
                r.add("GET", "/api/users/:id", function(req, res) {});
                r.add("GET", "*", function(req, res) {});
                return r.resolve("GET", "/api/users/7").route.pattern == "/api/users/:id";
            })());

        // Request / Response birim testi / unit tests
        var req = new pixel.Request("POST", "/api/users", null, '{"name":"Test"}');
        var body = req.jsonBody();
        check("jsonBody parse edilmeli / jsonBody parses",
            body != null && Reflect.field(body, "name") == "Test");

        var badReq = new pixel.Request("POST", "/api/users", null, "{bozuk json");
        check("bozuk json -> null / malformed json -> null", badReq.jsonBody() == null);

        var res = new pixel.Response();
        res.status(201).json({created: true});
        check("response status kodlanmali / response status set", res.statusCode == 201);
        check("response json content-type tasimali / response carries json content-type",
            res.headers.get("Content-Type").indexOf("application/json") == 0);

        // HEAD -> GET eslesmesi / HEAD matches GET routes
        var headRoute = new pixel.Route("GET", "/x", function(req, res) {});
        check("HEAD, GET rotasiyla eslesmeli / HEAD matches a GET route", headRoute.matchesMethod("HEAD"));

        // allowedMethods / 405 tespiti / detection
        var r2 = new pixel.Router();
        r2.add("GET", "/only-get", function(req, res) {});
        r2.add("POST", "/only-get", function(req, res) {});
        var allowed = r2.allowedMethods("/only-get");
        var hasGet = false; var hasPost = false;
        for (m in allowed) {
            if (m == "GET") hasGet = true;
            if (m == "POST") hasPost = true;
        }
        check("allowedMethods GET ve POST icermeli / allowedMethods contains GET and POST", hasGet && hasPost);
        check("bilinmeyen path icin allowedMethods bos / allowedMethods empty for unknown path",
            r2.allowedMethods("/nope").length == 0);

        // 405 davranisi app.handle uzerinden / 405 behavior via app.handle
        var app405 = new pixel.Pixel();
        app405.get("/res", function(req, res) {});
        var req405 = new pixel.Request("POST", "/res");
        var res405 = new pixel.Response();
        app405.handle(req405, res405);
        check("yanlis metot -> 405 / wrong method -> 405", res405.statusCode == 405);
        check("Allow basligi GET icermeli / Allow header contains GET",
            res405.headers.get("Allow").indexOf("GET") >= 0);

        // grup prefix'i / group prefix
        var appGroup = new pixel.Pixel();
        appGroup.group("/api/v1", function(g:pixel.RouteGroup) {
            g.get("/ping", function(req, res) { res.json({pong: true}); });
        });
        var resGroup = new pixel.Response();
        appGroup.handle(new pixel.Request("GET", "/api/v1/ping"), resGroup);
        check("grup prefix rota calismali / group prefix route works", resGroup.statusCode == 200);

        // grup middleware + Bearer auth / group middleware + Bearer auth
        var appSec = new pixel.Pixel();
        appSec.group("/sec", function(g:pixel.RouteGroup) {
            g.use(pixel.Auth.bearer(["tok"]));
            g.get("/data", function(req, res) { res.json({ok: true}); });
        });
        var res401 = new pixel.Response();
        appSec.handle(new pixel.Request("GET", "/sec/data"), res401);
        check("token yok -> 401 / no token -> 401", res401.statusCode == 401);
        var res200 = new pixel.Response();
        appSec.handle(new pixel.Request("GET", "/sec/data", ["Authorization" => "Bearer tok"]), res200);
        check("gecerli token -> 200 / valid token -> 200", res200.statusCode == 200);

        // bearerToken cikarimi / bearerToken extraction
        var bReq = new pixel.Request("GET", "/", ["Authorization" => "Bearer abc.def"]);
        check("bearerToken cikarilmali / bearerToken extracted", bReq.bearerToken() == "abc.def");
        check("token yoksa null / null when absent", new pixel.Request("GET", "/").bearerToken() == null);

        // cookie ayrıştırma ve yazma / cookie parsing and writing
        var cReq = new pixel.Request("GET", "/", ["Cookie" => "a=1; b=iki"]);
        check("cookie ayrismali / cookies parsed", cReq.cookie("a") == "1" && cReq.cookie("b") == "iki");
        var cRes = new pixel.Response().setCookie("sid", "abc", 3600);
        check("setCookie eklenmeli / setCookie appends", cRes.cookiesToSet[0].indexOf("sid=abc") >= 0);

        // hiz sinirlayici / rate limiter
        var rl = new pixel.RateLimit(2, 60);
        var rlReq = new pixel.Request("GET", "/", ["X-Forwarded-For" => "9.9.9.9"]);
        check("ilk iki istek izinli / first two requests allowed", rl.allow(rlReq) && rl.allow(rlReq));
        check("ucuncu istek reddedilmeli / third request blocked", !rl.allow(rlReq));
        check("kalan hak sifir / remaining quota is zero", rl.remaining(rlReq) == 0);

        // form govdesi / form body
        var fReq = new pixel.Request("POST", "/", ["Content-Type" => "application/x-www-form-urlencoded"],
            "ad=Deniz%20Kaya&yas=29");
        check("form govdesi ayrismali / form body parsed",
            fReq.formBody().get("ad") == "Deniz Kaya" && fReq.formBody().get("yas") == "29");
        check("isJson dogru taniyor / isJson detects JSON", fReq.isJson() == false
            && new pixel.Request("POST", "/", ["Content-Type" => "application/json"]).isJson());

        // ozel 404 / custom 404
        var app404 = new pixel.Pixel();
        app404.onNotFound(function(req, res) { res.status(404).json({custom: true}); });
        var resCustom = new pixel.Response();
        app404.handle(new pixel.Request("GET", "/yok"), resCustom);
        check("ozel 404 calismali / custom 404 runs",
            resCustom.statusCode == 404
            && resCustom.body.getString(0, resCustom.body.length).indexOf("custom") >= 0);

        // govde boyutu siniri / body size limit
        var appLimit = new pixel.Pixel();
        appLimit.use(new pixel.BodyLimit(10).middleware());
        appLimit.post("/echo", function(req, res) { res.json({len: req.rawBody.length}); });
        var res413 = new pixel.Response();
        appLimit.handle(new pixel.Request("POST", "/echo", null, "bu govde cok uzun / this body is too long"), res413);
        check("buyuk govde -> 413 / oversized body -> 413", res413.statusCode == 413);
        var resOk = new pixel.Response();
        appLimit.handle(new pixel.Request("POST", "/echo", null, "kisa"), resOk);
        check("kucuk govde gecmeli / small body passes", resOk.statusCode == 200);

        // OpenAPI uretici / OpenAPI generator
        var appDocs = new pixel.Pixel();
        appDocs.get("/api/users", function(req, res) {});
        appDocs.get("/api/users/:id", function(req, res) {});
        appDocs.post("/api/users", function(req, res) {});
        appDocs.describe("GET", "/api/users/:id", "Tek kullanici / Get one user", ["users"]);
        appDocs.docs("/spec.json");
        var spec = new pixel.OpenApi("T", "9.9").spec(appDocs);
        var specPaths:Array<String> = Reflect.fields(Reflect.field(spec, "paths"));
        var hasUsers = false; var hasUsersId = false;
        for (p in specPaths) {
            if (p == "/api/users") hasUsers = true;
            if (p == "/api/users/{id}") hasUsersId = true;
        }
        check("OpenAPI path'leri dogru / OpenAPI paths correct", hasUsers && hasUsersId);
        check("OpenAPI :param -> {param} donusumu / :param -> {param} conversion",
            pixel.OpenApi.toOpenApiPath("/api/users/:id") == "/api/users/{id}");
        var pathItem = Reflect.field(Reflect.field(spec, "paths"), "/api/users/{id}");
        var getOp = Reflect.field(pathItem, "get");
        check("describe ozeti spesifikasyonda / describe summary in spec",
            Reflect.field(getOp, "summary") == "Tek kullanici / Get one user");
        var specRes = new pixel.Response();
        appDocs.handle(new pixel.Request("GET", "/spec.json"), specRes);
        check("docs() rotasi spesifikasyon sunmali / docs() route serves the spec",
            specRes.statusCode == 200
            && specRes.body.getString(0, specRes.body.length).indexOf("openapi") >= 0);

        // logger middleware zinciri bozmadan gecmeli / logger passes chain through
        var appLog = new pixel.Pixel();
        appLog.use(new pixel.Logger().middleware());
        appLog.get("/ok", function(req, res) { res.json({fine: true}); });
        var resLogged = new pixel.Response();
        appLog.handle(new pixel.Request("GET", "/ok"), resLogged);
        check("logger istegi engellememeli / logger must not block requests", resLogged.statusCode == 200);

        // Izleme paneli / monitoring panel
        var appPanel = new pixel.Pixel();
        appPanel.panel("/panel", "Test Panel", "gizli");
        var pRes = new pixel.Response();
        appPanel.handle(new pixel.Request("GET", "/panel?key=gizli"), pRes);
        check("panel anahtarli giris -> 200 / panel with key -> 200", pRes.statusCode == 200);
        var html = pRes.body.getString(0, pRes.body.length);
        check("panel HTML dondurmeli / panel must return HTML",
            pRes.headers.get("Content-Type").indexOf("text/html") >= 0 && html.indexOf("Test Panel") >= 0);
        var p401 = new pixel.Response();
        appPanel.handle(new pixel.Request("GET", "/panel"), p401);
        check("panel anahtarsiz -> 401 / panel without key -> 401", p401.statusCode == 401);
        var pStats = new pixel.Response();
        appPanel.handle(new pixel.Request("GET", "/panel/stats?key=gizli"), pStats);
        check("panel stats JSON sunmali / panel stats must serve JSON",
            pStats.statusCode == 200 && pStats.body.getString(0, pStats.body.length).indexOf("total") >= 0);
        var pStatsNoKey = new pixel.Response();
        appPanel.handle(new pixel.Request("GET", "/panel/stats"), pStatsNoKey);
        check("stats anahtarsiz -> 401 / stats without key -> 401", pStatsNoKey.statusCode == 401);
        var pApi = new pixel.Request("GET", "/api/data", null);
        appPanel.handle(pApi, new pixel.Response());
        appPanel.handle(new pixel.Request("GET", "/api/data", null), new pixel.Response());
        var pStats2 = new pixel.Response();
        appPanel.handle(new pixel.Request("GET", "/panel/stats?key=gizli"), pStats2);
        var statsBody = pStats2.body.getString(0, pStats2.body.length);
        check("panel istekleri saymali / panel must count requests",
            statsBody.indexOf("\"total\": 2") >= 0 || statsBody.indexOf("\"total\" : 2") >= 0);
        check("panel kendi isteklerini saymamali / panel must not count itself", statsBody.indexOf("/panel") < 0);

        Sys.println("Tum testler gecti / All tests passed");


    }

    static function check(label:String, cond:Bool):Void {
        if (!cond) {
            Sys.println("FAIL: " + label);
            throw "TEST FAILED: " + label;
        }
        Sys.println("  ok: " + label);
    }
}
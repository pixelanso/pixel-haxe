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

        check("method eşleşmezse res null olmalı",
            router.resolve("GET", "/api/users/42") != null);
        check("path parametresi yakalanmalı",
            router.resolve("GET", "/api/users/42").params.get("id") == "42");
        check("rota metodu büyük/küçük harf duyarsız olmalı",
            router.resolve("get", "/api/users/1") != null);
        check("metot yanlis rotaya düsmemeli",
            router.resolve("POST", "/api/users") != null
            && router.resolve("POST", "/api/users/1") == null
            && router.resolve("GET", "/api/users/1") != null);
        check("bilinmeyen path null dönmeli",
            router.resolve("GET", "/api/unknown") == null);
        check("catch-all rota önceliği düşük tutulmalı",
            (function() {
                var r = new pixel.Router();
                r.add("GET", "/api/users/:id", function(req, res) {});
                r.add("GET", "*", function(req, res) {});
                return r.resolve("GET", "/api/users/7").route.pattern == "/api/users/:id";
            })());

        // Request / Response birim testi
        var req = new pixel.Request("POST", "/api/users", null, '{"name":"Test"}');
        var body = req.jsonBody();
        check("jsonBody parse edilmeli", body != null && Reflect.field(body, "name") == "Test");

        var badReq = new pixel.Request("POST", "/api/users", null, "{bozuk json");
        check("bozuk json -> null", badReq.jsonBody() == null);

        var res = new pixel.Response();
        res.status(201).json({created: true});
        check("response status kodlanmalı", res.statusCode == 201);
        check("response json content-type taşımalı", res.headers.get("Content-Type").indexOf("application/json") == 0);

        Sys.println("Tüm testler geçti ✔");
    }

    static function check(label:String, cond:Bool):Void {
        if (!cond) {
            Sys.println("FAIL: " + label);
            throw "TEST FAILED: " + label;
        }
        Sys.println("  ok: " + label);
    }
}
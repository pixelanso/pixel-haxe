package pixel;

#if js

import haxe.io.Bytes;

@:jsRequire("node:http")
extern class NHttp {
    public static function createServer(handler:Dynamic):Dynamic;
}

/**
 * js (Node.js) hedefi için HTTP sürücüsü.
 * HTTP driver for the js (Node.js) target.
 * Node'un `node:http` modülünü doğrudan kullanır; ayrı haxelib gerektirmez.
 * Uses Node's `node:http` module directly; no extra haxelib required.
 */
class NodeServer {
    public static function run(app:Pixel, port:Int = 8080, host:String = "0.0.0.0"):Void {
        var server = NHttp.createServer(function(req:Dynamic, res:Dynamic) {
            handle(app, req, res);
        });
        server.listen(port, host);
        Platform.println("Pixel Api -> http://" + host + ":" + port);
    }

    static function handle(app:Pixel, req:Dynamic, res:Dynamic):Void {
        var body = new StringBuf();
        untyped req.on("data", function(chunk:Dynamic) {
            body.add(untyped chunk.toString());
        });
        untyped req.on("end", function() {
            dispatch(app, req, res, body.toString());
        });
        untyped req.on("error", function(e:Dynamic) {
            send(req, res, new Response().status(400).text("Bad Request"));
        });
    }

    static function dispatch(app:Pixel, req:Dynamic, res:Dynamic, bodyStr:String):Void {
        var method = Std.string(untyped req.method);
        var url = Std.string(untyped req.url);

        var headersMap = new Map<String, String>();
        var hobj = untyped req.headers;
        if (hobj != null) {
            var hkeys = untyped __js__('Object.keys(hobj)');
            var keysArr:Array<String> = cast hkeys;
            for (k in keysArr) {
                headersMap.set(k, untyped(__js__('String(hobj[k])')));
            }
        }

        var request = HttpMessage.makeRequest(method, url, headersMap, bodyStr);
        var response = new Response();
        try {
            app.handle(request, response);
        } catch (e:Dynamic) {
            response.status(500).json({error: "Internal Server Error", detail: Std.string(e)});
        }
        send(req, res, response);
    }

    static function send(req:Dynamic, res:Dynamic, response:Response):Void {
        Reflect.setField(res, "statusCode", response.statusCode);
        for (k in response.headers.keys()) {
            untyped res.setHeader(k, response.headers.get(k));
        }
        untyped res.setHeader("Content-Length", Std.string(response.body.length));
        untyped res.setHeader("Server", "pixel-haxe/0.1.0");
        untyped res.end(toBuffer(response.body));
    }

    static function toBuffer(b:Bytes):Dynamic {
        var arr = [];
        for (i in 0...b.length) arr.push(b.get(i));
        return untyped __js__('Buffer.from(arr)');
    }
}

#end
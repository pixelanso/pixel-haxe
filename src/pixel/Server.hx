package pixel;

#if js
import pixel.NodeServer;
#end

#if !js
import sys.net.Socket;
import sys.net.Host;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;
#end

/**
 * HTTP sunucusu.
 * HTTP server.
 *
 * - **js**: Node.js'in `node:http` modülü kullanılır (`NodeServer`).
 *   The Node.js `node:http` module is used (`NodeServer`).
 * - **diğer hedefler** (php, neko, hl, cpp, lua, python...): `sys.net.Socket`
 *   üzerinde minimal blocking HTTP/1.1 sunucusu çalışır.
 *   Other targets run a minimal blocking HTTP/1.1 server over `sys.net.Socket`.
 */
class Server {
    #if !js
    public static function run(app:Pixel, port:Int = 8080, host:String = "0.0.0.0"):Void {
        var server = new Socket();
        server.bind(new Host(host), port);
        server.listen(128);
        server.setFastSend(true);

        Platform.println("Pixel Api -> http://" + host + ":" + port);
        Platform.println("Durdurmak icin Ctrl+C / Press Ctrl+C to stop");

        while (true) {
            var client:Socket;
            try {
                client = server.accept();
            } catch (e:Dynamic) {
                Platform.sleep(0.1);
                continue;
            }
            if (client == null) {
                Platform.sleep(0.05);
                continue;
            }
            try {
                handle(app, client);
            } catch (e:Dynamic) {
                Platform.println("Request hatasi / Request error: " + Std.string(e));
            }
        }
    }

    static function handle(app:Pixel, sock:Socket):Void {
        sock.setBlocking(true);
        sock.setTimeout(15);

        var raw = readRequest(sock);
        var req = HttpMessage.fromRaw(raw);
        var res = new Response();

        if (req == null) {
            res.status(400).text("Bad Request");
        } else {
            try {
                req.ip = sock.host().host.toString();
            } catch (e:Dynamic) {}

            try {
                app.handle(req, res);
            } catch (e:Dynamic) {
                res.status(500).json({error: "Internal Server Error", detail: Std.string(e)});
            }
        }


        writeResponse(sock, res);

        try sock.close() catch (e:Dynamic) {}
    }
/**
     * HTTP istek başlıklarını (header bloğunu) ve varsa body'yi birlikte okur.
     * Reads the HTTP request headers (header block) and, if present, the body.
     */
    static function readRequest(sock:Socket):String {
        var buf = new BytesBuffer();
        var head = new StringBuf();
        while (true) {
            var b = try sock.input.readByte() catch (e:Dynamic) -1;
            if (b < 0) break;
            buf.addByte(b);
            head.addChar(b);
            var len = head.length;
            if (len >= 4) {
                var s = head.toString();
                if (s.substr(len - 4, 4) == "\r\n\r\n") {
                    var cl = HttpMessage.contentLength(s);
                    if (cl > 0) {
                        var body = Bytes.alloc(cl);
                        var pos = 0;
                        while (pos < cl) {
                            var n = sock.input.readBytes(body, pos, cl - pos);
                            if (n <= 0) break;
                            pos += n;
                        }
                        if (pos > 0) buf.addBytes(body, 0, pos);
                    }
                    break;
                }
            }
        }
        var bytes = buf.getBytes();
        return bytes.getString(0, bytes.length);
    }

    static function writeResponse(sock:Socket, res:Response):Void {
        var sb = new StringBuf();
        sb.add("HTTP/1.1 "); sb.add(Std.string(res.statusCode)); sb.add(" ");
        sb.add(HttpMessage.statusText(res.statusCode)); sb.add("\r\n");
        sb.add("Content-Length: "); sb.add(Std.string(res.body.length)); sb.add("\r\n");
        sb.add("Server: pixel-haxe/0.2.0\r\n");
        sb.add("Connection: close\r\n");
        for (k in res.headers.keys()) {
            sb.add(k); sb.add(": "); sb.add(res.headers.get(k)); sb.add("\r\n");
        }
        for (c in res.cookiesToSet) {
            sb.add("Set-Cookie: "); sb.add(c); sb.add("\r\n");
        }
        sb.add("\r\n");


        var out = sock.output;
        out.writeString(sb.toString());
        if (res.body.length > 0) out.write(res.body);
        out.flush();
    }
    #else
    public static function run(app:Pixel, port:Int = 8080, host:String = "0.0.0.0"):Void {
        NodeServer.run(app, port, host);
    }
    #end
}
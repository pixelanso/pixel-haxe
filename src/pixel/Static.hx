package pixel;

import haxe.io.Bytes;

/**
 * Statik dosya sunucusu.
 * Static file server.
 *
 * `app.serveStatic("public")` ile kökte, `app.serveStatic("public", "/assets")` ile bir
 * prefix altında hizmet verir. `..` ile dizin dışına çıkış denemelerini engeller.
 * Serves from the root with `app.serveStatic("public")` or under a prefix with
 * `app.serveStatic("public", "/assets")`. Blocks directory traversal via `..`.
 * Dosya okuma `Platform` üzerinden yapıldığı için tüm hedeflerde çalışır.
 * File reads go through `Platform`, so it works on all targets.
 */
class Static {
    public static function serve(req:Request, res:Response, root:String, prefix:String):Bool {
        if (req.method != "GET" && req.method != "HEAD") return false;

        var p = req.path;
        var pre = prefix == null || prefix == "" ? "/" : prefix;
        if (pre.length > 1 && pre.charAt(pre.length - 1) == "/") pre = pre.substr(0, pre.length - 1);

        var rel:String;
        if (pre == "/") {
            rel = p;
        } else {
            if (!StringTools.startsWith(p, pre)) return false;
            rel = p.substr(pre.length);
        }
        if (rel.length > 0 && rel.charAt(0) == "/") rel = rel.substr(1);
        if (rel == "") rel = "index.html";

        // dizin yükselişini engelle / block directory traversal
        for (part in rel.split("/")) {
            if (part == "..") return false;
        }

        var filePath = root.length == 0 ? "." : root;
        filePath += "/" + rel;

        if (!Platform.fileExists(filePath) || Platform.isDirectory(filePath)) return false;

        var bytes = Platform.readFileBytes(filePath);
        res.sendBytes(bytes, mime(filePath));
        return true;
    }

    static function mime(path:String):String {
        var dots = path.split(".");
        var ext = dots.length > 1 ? dots[dots.length - 1].toLowerCase() : "";
        return switch (ext) {
            case "html" | "htm": "text/html; charset=utf-8";
            case "css": "text/css; charset=utf-8";
            case "js": "application/javascript; charset=utf-8";
            case "mjs": "application/javascript; charset=utf-8";
            case "json": "application/json; charset=utf-8";
            case "png": "image/png";
            case "jpg" | "jpeg": "image/jpeg";
            case "gif": "image/gif";
            case "svg": "image/svg+xml";
            case "webp": "image/webp";
            case "ico": "image/x-icon";
            case "txt": "text/plain; charset=utf-8";
            case "md": "text/markdown; charset=utf-8";
            case "pdf": "application/pdf";
            case "woff": "font/woff";
            case "woff2": "font/woff2";
            case "ttf": "font/ttf";
            case "mp3": "audio/mpeg";
            case "mp4": "video/mp4";
            case "zip": "application/zip";
            default: "application/octet-stream";
        }
    }
}
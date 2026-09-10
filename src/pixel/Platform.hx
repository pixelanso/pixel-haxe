package pixel;

/**
 * Hedefe özel sistem erişimi — konsol çıktısı, ortam değişkeni,
 * dosya okuma ve saat gibi işlemleri tek arayüzde toplar.
 * Target-specific system access — console output, environment variables,
 * file reads and time unified behind a single interface.
 *
 * - js (Node.js): process/console/fs üzerinden / via process/console/fs
 * - Diğerleri (php, neko, hl, cpp...): sys üzerinden / via sys
 */
class Platform {
    public static function println(v:Dynamic):Void {
        #if js
            untyped __js__('console.log(v)', v);
        #else
            Sys.println(v);
        #end
    }

    public static function getEnv(key:String):Null<String> {
        #if js
            return untyped __js__('typeof process !== "undefined" && process.env ? (process.env[key] !== undefined ? process.env[key] : null) : null', key);
        #else
            return Sys.getEnv(key);
        #end
    }

    public static function time():Float {
        #if js
            return untyped __js__('Date.now() / 1000');
        #else
            return Sys.time();
        #end
    }

    public static function sleep(sec:Float):Void {
        #if js
            untyped __js__('void 0');
        #else
            Sys.sleep(sec);
        #end
    }

    public static function fileExists(p:String):Bool {
        #if js
            return untyped __js__('typeof require === "function" ? require("node:fs").existsSync(p) : false', p);
        #else
            return sys.FileSystem.exists(p);
        #end
    }

    public static function isDirectory(p:String):Bool {
        #if js
            return untyped __js__('typeof require === "function" && require("node:fs").existsSync(p) ? require("node:fs").statSync(p).isDirectory() : false', p);
        #else
            return sys.FileSystem.isDirectory(p);
        #end
    }

    public static function readFileBytes(p:String):haxe.io.Bytes {
        #if js
            var buf = untyped __js__('require("node:fs").readFileSync(p)', p);
            var n = untyped __js__('buf.length');
            var out = haxe.io.Bytes.alloc(n);
            for (i in 0...n) {
                out.set(i, untyped __js__('buf[i]'));
            }
            return out;
        #else
            return sys.io.File.getBytes(p);
        #end
    }
}
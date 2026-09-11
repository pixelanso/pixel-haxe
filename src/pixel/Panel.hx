package pixel;

import pixel.Request;
import pixel.Response;
import pixel.Middleware;
import pixel.Platform;

/**
 * Gomulu izleme paneli — istek metriklerini toplar ve tarayicidan
 * izlenebilen bir HTML dashboard ile JSON ozeti sunar.
 * Built-in monitoring panel — collects request metrics and serves
 * an HTML dashboard plus a JSON summary viewable from a browser.
 *
 * ```haxe
 * var panel = app.panel("/panel", "pixel-secret");
 * // Tarayici / Browser:  http://localhost:8080/panel?key=pixel-secret
 * // JSON ozeti / summary: http://localhost:8080/panel/stats
 * ```
 *
 * Koruma / Protection:
 * - token verilirse Bearer header veya ?key= sorgusu ile giris yapilir
 *   when a token is given, access requires a Bearer header or a ?key= query
 *
 * Not / Notes:
 * - Metrikler bellek icindedir, surec yeniden baslayinca sifirlanir
 *   Metrics are in-memory and reset when the process restarts
 * - Panel yollari kendi isteklerini metriklere eklemez
 *   Panel endpoints do not count their own requests
 */
class Panel {
    /** Panel taban yolu / Panel base path. */
    public var path:String;
    /** Panel basligi / Panel title. */
    public var title:String;
    /** Giris anahtari; null ise aciktir / Access token; null means open access. */
    public var token:Null<String>;

    var startTime:Float;
    var total:Int;
    var status2xx:Int;
    var status3xx:Int;
    var status4xx:Int;
    var status5xx:Int;
    var totalMs:Float;
    var maxMs:Float;
    var perMethod:Map<String, Int>;
    var perPath:Map<String, Int>;
    var perStatus:Map<String, Int>;

    /** Tutulacak benzersiz yol anahtari ust siniri / Max distinct path keys kept. */
    static inline var MAX_PATHS:Int = 200;

    public function new(?path:String = "/panel", ?title:String = null, ?token:String = null) {
        this.path = path == null ? "/panel" : path;
        this.title = title == null ? "Pixel Api Panel" : title;
        this.token = token;
        startTime = Platform.time();
        total = 0;
        status2xx = 0;
        status3xx = 0;
        status4xx = 0;
        status5xx = 0;
        totalMs = 0;
        maxMs = 0;
        perMethod = new Map();
        perPath = new Map();
        perStatus = new Map();
    }

    /**
     * Panel middleware'ini dondurur; global zincire `app.use()` ile eklenir.
     * Returns the panel middleware; add it to the global chain with `app.use()`.
     */
    public function middleware():Middleware {
        var self = this;
        return new Middleware(function(req:Request, res:Response, next:Void -> Void) {
            if (StringTools.startsWith(req.path, self.path)) {
                self.serve(req, res);
                return;
            }
            var t0 = Platform.time();
            next();
            self.record(req, res.statusCode, (Platform.time() - t0) * 1000);
        });
    }

    /**
     * Metrikleri sifirlar (suresi korunur) / Resets metrics (uptime is kept).
     */
    public function reset():Void {
        total = 0;
        status2xx = 0;
        status3xx = 0;
        status4xx = 0;
        status5xx = 0;
        totalMs = 0;
        maxMs = 0;
        perMethod = new Map();
        perPath = new Map();
        perStatus = new Map();
    }

    // ------------------------------------------------------------ recording

    function record(req:Request, status:Int, ms:Float):Void {
        total++;
        totalMs += ms;
        if (ms > maxMs) maxMs = ms;

        if (status >= 200 && status < 300) status2xx++;
        else if (status < 400) status3xx++;
        else if (status < 500) status4xx++;
        else status5xx++;

        var m = req.method.toUpperCase();
        perMethod.set(m, (perMethod.exists(m) ? perMethod.get(m) : 0) + 1);

        var s = Std.string(status);
        perStatus.set(s, (perStatus.exists(s) ? perStatus.get(s) : 0) + 1);

        var key = m + " " + req.path;
        if (perPath.exists(key) || Lambda.count(perPath) < MAX_PATHS) {
            perPath.set(key, (perPath.exists(key) ? perPath.get(key) : 0) + 1);
        }
    }

    // -------------------------------------------------------------- serving

    function authorized(req:Request):Bool {
        if (token == null) return true;
        var bearer = req.bearerToken();
        if (bearer != null && bearer == token) return true;
        var key = req.query.get("key");
        return key != null && key == token;
    }

    function serve(req:Request, res:Response):Void {
        if (!authorized(req)) {
            res.status(401).json({
                error: "Panel erisimi icin anahtar gerekli / Panel access requires a token",
                hint: "Bearer header veya ?key= sorgusu kullanin / use a Bearer header or a ?key= query"
            });
            return;
        }

        var base = StringTools.endsWith(path, "/") ? path.substr(0, path.length - 1) : path;

        if (req.path == base + "/stats") {
            res.json(statsObject());
            return;
        }
        if (req.path == base + "/reset" && req.method.toUpperCase() == "POST") {
            reset();
            res.json({ok: true, message: "Metrikler sifirlandi / Metrics reset"});
            return;
        }
        if (req.path == base || req.path == base + "/") {
            res.header("Content-Type", "text/html; charset=utf-8").text(buildHtml());
            return;
        }
        res.status(404).json({error: "Not Found / Bulunamadi"});
    }

    // --------------------------------------------------------------- stats

    public function statsObject():Dynamic {
        var methods:Dynamic = {};
        for (k in perMethod.keys()) Reflect.setField(methods, k, perMethod.get(k));
        var statuses:Dynamic = {};
        for (k in perStatus.keys()) Reflect.setField(statuses, k, perStatus.get(k));
        var paths:Dynamic = {};
        for (k in perPath.keys()) Reflect.setField(paths, k, perPath.get(k));
        return {
            title: title,
            total: total,
            uptimeSec: Math.ffloor(Platform.time() - startTime),
            avgMs: total > 0 ? Math.round(totalMs / total * 10) / 10 : 0,
            maxMs: Math.round(maxMs * 10) / 10,
            status2xx: status2xx,
            status3xx: status3xx,
            status4xx: status4xx,
            status5xx: status5xx,
            memoryMb: Platform.memoryMb(),
            perMethod: methods,
            perStatus: statuses,
            perPath: paths
        };
    }

    // ---------------------------------------------------------------- html

    function buildHtml():String {
        var apiPath = path + "/stats";
        var resetPath = path + "/reset";
        return '
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>' + title + '</title>
<style>
  body { font-family: Consolas, Menlo, monospace; background: #10141c; color: #d7dde6;
         margin: 0; padding: 24px; }
  h1 { font-size: 18px; letter-spacing: 1px; margin: 0 0 4px; }
  .sub { color: #6c7a8c; font-size: 12px; margin-bottom: 20px; }
  .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
           gap: 12px; margin-bottom: 20px; }
  .card { background: #1a2029; border: 1px solid #262e3a; border-radius: 8px;
          padding: 12px 14px; }
  .card .label { color: #6c7a8c; font-size: 11px; text-transform: uppercase; }
  .card .value { font-size: 22px; margin-top: 4px; }
  .ok { color: #57c785; } .warn { color: #e0b458; } .err { color: #e06c75; }
  h2 { font-size: 14px; border-bottom: 1px solid #262e3a; padding-bottom: 6px; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; margin-bottom: 18px; }
  th, td { text-align: left; padding: 6px 8px; border-bottom: 1px solid #1e2530; }
  th { color: #6c7a8c; font-weight: normal; text-transform: uppercase; font-size: 11px; }
  .bar { background: #26304a; height: 8px; border-radius: 4px; }
  .bar span { display: block; height: 8px; border-radius: 4px; background: #4a9eff; }
  button { background: #262e3a; color: #d7dde6; border: 1px solid #334052;
           border-radius: 6px; padding: 6px 12px; cursor: pointer; font-family: inherit; }
  button:hover { background: #303a48; }
</style>
</head>
<body>
  <h1>' + title + '</h1>
  <div class="sub">pixel-haxe gomulu paneli / built-in panel</div>
  <div class="cards">
    <div class="card"><div class="label">Toplam / Total</div><div class="value" id="total">0</div></div>
    <div class="card"><div class="label">Uptime</div><div class="value" id="uptime">0s</div></div>
    <div class="card"><div class="label">Ort. sure / Avg time</div><div class="value" id="avg">0 ms</div></div>
    <div class="card"><div class="label">En yavas / Slowest</div><div class="value" id="max">0 ms</div></div>
    <div class="card"><div class="label">Bellek / Memory</div><div class="value" id="mem">-</div></div>
  </div>
  <h2>Durum siniflari / Status classes</h2>
  <table>
    <tr><th>2xx</th><th>3xx</th><th>4xx</th><th>5xx</th></tr>
    <tr>
      <td class="ok" id="s2">0</td>
      <td id="s3">0</td>
      <td class="warn" id="s4">0</td>
      <td class="err" id="s5">0</td>
    </tr>
  </table>
  <h2>Metotlar / Methods</h2>
  <table id="methods"><tr><th>Metot / Method</th><th>Sayi / Count</th></tr></table>
  <h2>Durum kodlari / Status codes</h2>
  <table id="statuses"><tr><th>Kod / Code</th><th>Sayi / Count</th></tr></table>
  <h2>Yollar / Paths</h2>
  <table id="paths"><tr><th>Yol / Path</th><th>Sayi / Count</th><th></th></tr></table>
  <button id="reset">Metrikleri sifirla / Reset metrics</button>
<script>
function fmtUptime(s) {
  if (s < 60) return s + "s";
  if (s < 3600) return Math.floor(s / 60) + "m " + (s % 60) + "s";
  return Math.floor(s / 3600) + "h " + Math.floor((s % 3600) / 60) + "m";
}
function fillTable(id, obj, withBar) {
  var t = document.getElementById(id);
  while (t.rows.length > 1) t.deleteRow(1);
  var keys = Object.keys(obj || {});
  keys.sort(function(a, b) { return obj[b] - obj[a]; });
  var maxVal = keys.length ? obj[keys[0]] : 0;
  for (var i = 0; i < keys.length; i++) {
    var r = t.insertRow(-1);
    r.insertCell(-1).textContent = keys[i];
    r.insertCell(-1).textContent = obj[keys[i]];
    if (withBar) {
      var c = r.insertCell(-1);
      var d = document.createElement("div");
      d.className = "bar";
      var s = document.createElement("span");
      s.style.width = (maxVal ? Math.round(100 * obj[keys[i]] / maxVal) : 0) + "%";
      d.appendChild(s);
      c.appendChild(d);
    }
  }
}
function refresh() {
  fetch("' + apiPath + '").then(function(r) { return r.json(); }).then(function(d) {
    document.getElementById("total").textContent = d.total;
    document.getElementById("uptime").textContent = fmtUptime(d.uptimeSec);
    document.getElementById("avg").textContent = d.avgMs + " ms";
    document.getElementById("max").textContent = d.maxMs + " ms";
    document.getElementById("mem").textContent = d.memoryMb >= 0 ? d.memoryMb + " MB" : "-";
    document.getElementById("s2").textContent = d.status2xx;
    document.getElementById("s3").textContent = d.status3xx;
    document.getElementById("s4").textContent = d.status4xx;
    document.getElementById("s5").textContent = d.status5xx;
    fillTable("methods", d.perMethod, false);
    fillTable("statuses", d.perStatus, false);
    fillTable("paths", d.perPath, true);
  });
}
document.getElementById("reset").onclick = function() {
  fetch("' + resetPath + '", { method: "POST" }).then(function() { refresh(); });
};
refresh();
setInterval(refresh, 2000);
</script>
</body>
</html>';
    }
}



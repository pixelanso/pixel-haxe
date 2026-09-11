package pixel;

/**
 * Yaygin guvenlik basliklarini tek middleware ile ekler (Helmet benzeri).
 * Adds common security headers with a single middleware (Helmet-like).
 *
 * ```haxe
 * app.use(new Security().middleware());
 * // veya / or:
 * app.use(new Security({hsts: 31536000, csp: "default-src 'self'"}).middleware());
 * ```
 */
class Security {
    /** X-Content-Type-Options: nosniff (varsayilan acik / on by default). */
    public var noSniff:Bool;
    /** X-Frame-Options degeri; null veya "" ile kapatilir / frame guard value. */
    public var frame:Null<String>;
    /** Referrer-Policy degeri; null veya "" ile kapatilir / referrer policy value. */
    public var referrer:Null<String>;
    /** HSTS max-age saniyesi; 0 = kapali / HSTS max-age seconds; 0 disables. */
    public var hsts:Int;
    /** Content-Security-Policy; null = kapali / CSP value; null disables. */
    public var csp:Null<String>;
    /** X-Powered-By basligini kaldirir / removes the X-Powered-By header. */
    public var hidePoweredBy:Bool;

    public function new(?options:Dynamic = null) {
        noSniff = true;
        frame = "DENY";
        referrer = "no-referrer";
        hsts = 0;
        csp = null;
        hidePoweredBy = true;
        if (options != null) {
            var o:Dynamic = options;
            // Alan varsa degeri (null dahil) uygula; boylece null ile ozellik kapatilir.
            // Apply the value (including null) when the field exists; null disables a feature.
            if (Reflect.hasField(o, "noSniff") && Reflect.field(o, "noSniff") != null) {
                noSniff = Reflect.field(o, "noSniff") == true;
            }
            if (Reflect.hasField(o, "frame")) {
                frame = Reflect.field(o, "frame");
            }
            if (Reflect.hasField(o, "referrer")) {
                referrer = Reflect.field(o, "referrer");
            }
            if (Reflect.hasField(o, "hsts") && Reflect.field(o, "hsts") != null) {
                hsts = Reflect.field(o, "hsts");
            }
            if (Reflect.hasField(o, "csp")) {
                csp = Reflect.field(o, "csp");
            }
            if (Reflect.hasField(o, "hidePoweredBy") && Reflect.field(o, "hidePoweredBy") != null) {
                hidePoweredBy = Reflect.field(o, "hidePoweredBy") == true;
            }
        }

    }

    /** Guvenlik basliklarini middleware olarak dondurur / Wraps the headers as middleware. */
    public function middleware():Middleware {
        return new Middleware(function(req:Request, res:Response, next:Void -> Void) {
            apply(res);
            next();
        });
    }

    /** Basliklari yanita uygular / Applies the headers to a response. */
    public function apply(res:Response):Void {
        if (noSniff) res.header("X-Content-Type-Options", "nosniff");
        if (frame != null && frame != "") res.header("X-Frame-Options", frame);
        if (referrer != null && referrer != "") res.header("Referrer-Policy", referrer);
        if (hsts > 0) {
            res.header("Strict-Transport-Security", "max-age=" + hsts + "; includeSubDomains");
        }
        if (csp != null && csp != "") res.header("Content-Security-Policy", csp);
        if (hidePoweredBy) res.headers.remove("X-Powered-By");
    }
}

package pixel;

/**
 * Basit kimlik dogrulama middleware'leri.
 * Simple authentication middlewares.
 *
 * Bearer token korumasi ornegi / Bearer token protection example:
 *
 * ```haxe
 * app.use(Auth.bearer(["benim-gizli-tokenum"]));
 * ```
 */
class Auth {
    /**
     * `Authorization: Bearer <token>` basligini kontrol eder.
     * Geçersiz veya eksik token icin 401 + `WWW-Authenticate` doner.
     *
     * Validates the `Authorization: Bearer <token>` header.
     * Returns 401 + `WWW-Authenticate` on missing or invalid tokens.
     */
    public static function bearer(validTokens:Array<String>, ?realm:String = "pixel-api"):Middleware {
        return new Middleware(function(req:Request, res:Response, next:Void -> Void) {
            var token = req.bearerToken();
            if (token == null) {
                deny(res, realm, "Bearer token eksik / Missing bearer token");
                return;
            }
            for (t in validTokens) {
                if (t == token) {
                    next();
                    return;
                }
            }
            deny(res, realm, "Gecersiz token / Invalid token");
        });
    }

    /** 401 yaniti uretir / Produces a 401 response. */
    public static function deny(res:Response, realm:String, message:String):Void {
        res.status(401)
            .header("WWW-Authenticate", "Bearer realm=\"" + realm + "\"")
            .json({error: message});
    }
}

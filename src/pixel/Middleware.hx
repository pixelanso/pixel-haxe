package pixel;

/**
 * Middleware zincirindeki tek adım.
 * A single step in the middleware chain.
 *
 * Handler imzası / handler signature:
 * `(req, res, next) -> Void`
 */
class Middleware {
    public var handler:(Request, Response, Void -> Void) -> Void;

    public function new(handler:(Request, Response, Void -> Void) -> Void) {
        this.handler = handler;
    }
}
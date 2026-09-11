package pixel;

/**
 * JSON govdesi icin basit kural tabanli dogrulama.
 * Simple rule-based validation for JSON bodies.
 *
 * Kurallar anonim nesne olarak verilir / Rules are plain anonymous objects:
 *
 * ```haxe
 * // app.use icinde / inside a handler:
 * var body = req.jsonBody();
 * if (body == null) { res.status(400).json({error: "JSON gerekli / JSON required"}); return; }
 * if (Validator.rejectIfInvalid(res, body, {
 *     name: {required: true, type: "string", min: 2, max: 60},
 *     age:  {type: "int", min: 0, max: 150},
 *     role: {type: "string", oneOf: ["user", "admin"]}
 * })) return;
 * ```
 *
 * Notlar / Notes:
 * - `min`/`max`: metin icin uzunluk, sayi icin deger / length for strings, value for numbers
 * - tipler / types: `string`, `int`, `number`, `bool`
 * - hatali durumda 422 doner / responds 422 on failure
 */
class Validator {
    /**
     * Kurallari degerlendirir; hata listesi dondurur (bos liste = gecerli).
     * Evaluates the rules; returns error messages (empty list = valid).
     */
    public static function check(data:Dynamic, rules:Dynamic):Array<String> {
        var errors:Array<String> = [];
        if (data == null) data = {};
        if (rules == null) return errors;

        for (field in Reflect.fields(rules)) {
            var rule:Dynamic = Reflect.field(rules, field);
            var value:Dynamic = Reflect.field(data, field);
            var required:Bool = rule != null && Reflect.field(rule, "required") == true;
            var isString:Bool = Std.isOfType(value, String);
            var provided:Bool = value != null && !(isString && value == "");

            if (!provided) {
                if (required) {
                    errors.push(field + ": zorunlu alan / required field");
                }
                continue;
            }

            var type:Null<String> = rule == null ? null : Reflect.field(rule, "type");
            if (type != null) {
                switch (type) {
                    case "string":
                        if (!isString) errors.push(field + ": metin olmali / must be a string");
                    case "int":
                        if (!isInt(value)) errors.push(field + ": tam sayi olmali / must be an integer");
                    case "number":
                        if (!isNum(value)) errors.push(field + ": sayi olmali / must be a number");
                    case "bool":
                        if (!Std.isOfType(value, Bool)) errors.push(field + ": mantiksal olmali / must be a boolean");
                    case _:
                        errors.push(field + ": bilinmeyen tip / unknown type '" + type + "'");
                }
            }

            var min:Null<Float> = rule == null ? null : Reflect.field(rule, "min");
            var max:Null<Float> = rule == null ? null : Reflect.field(rule, "max");
            if (min != null || max != null) {
                if (isString) {
                    var len:Float = (value : String).length;
                    if (min != null && len < min) {
                        errors.push(field + ": en az " + Std.int(min) + " karakter / at least " + Std.int(min) + " chars");
                    }
                    if (max != null && len > max) {
                        errors.push(field + ": en fazla " + Std.int(max) + " karakter / at most " + Std.int(max) + " chars");
                    }
                } else if (isNum(value)) {
                    var n:Float = value;
                    if (min != null && n < min) {
                        errors.push(field + ": en az " + min + " olmali / must be at least " + min);
                    }
                    if (max != null && n > max) {
                        errors.push(field + ": en fazla " + max + " olmali / must be at most " + max);
                    }
                }
            }

            var oneOf:Array<String> = rule == null ? null : Reflect.field(rule, "oneOf");
            if (oneOf != null) {
                var s = Std.string(value);
                var ok = false;
                for (o in oneOf) {
                    if (o == s) {
                        ok = true;
                        break;
                    }
                }
                if (!ok) {
                    errors.push(field + ": su degerlerden biri olmali / must be one of [" + oneOf.join(", ") + "]");
                }
            }
        }
        return errors;
    }

    /**
     * Gecerli degilse 422 yanitini yazar ve true dondurur.
     * Writes a 422 response when invalid and returns true.
     */
    public static function rejectIfInvalid(res:Response, data:Dynamic, rules:Dynamic):Bool {
        var errors = check(data, rules);
        if (errors.length > 0) {
            res.status(422).json({
                error: "Gecerli degil / Validation failed",
                errors: errors
            });
            return true;
        }
        return false;
    }

    static function isNum(v:Dynamic):Bool {
        return Std.isOfType(v, Int) || Std.isOfType(v, Float);
    }

    static function isInt(v:Dynamic):Bool {
        if (Std.isOfType(v, Int)) return true;
        // JS'te tam sayilar Float olarak gelir; tam degerse kabul et
        // On JS integers arrive as Floats; accept integral values
        if (Std.isOfType(v, Float)) {
            var f:Float = v;
            return f == Math.floor(f) && !Math.isNaN(f) && Math.isFinite(f);
        }
        return false;
    }
}

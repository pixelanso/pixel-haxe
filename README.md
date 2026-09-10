# Pixel Api — `pixel-haxe`

Hafif ve çok hedefli Haxe API mikro-framework'ü
A lightweight, multi-target Haxe API micro-framework

Router · Middleware · CORS · JSON · Statik dosya — tek kod tabanı, çoklu çalışma ortamı
Router · Middleware · CORS · JSON · Static files — single codebase, multiple targets

---

## Nedir? / What is it?

Pixel Api, Haxe ile yazılmış sıfır bağımlılıklı bir HTTP API mikro-framework'üdür.
Yerleşik HTTP sunucusu sayesinde aynı Haxe kodunu farklı hedeflere derleyip aynen
çalıştırabilirsin.

Pixel Api is a zero-dependency HTTP API micro-framework written in Haxe.
With its built-in HTTP server you can compile the same Haxe code to different
targets and run it unchanged.

| Hedef / Target       | Derleme / Compile       | Çalıştırma / Run          |
|----------------------|-------------------------|----------------------------|
| **Node.js**          | `haxe build-node.hxml`  | `node bin/Node/server.js`  |
| **PHP**              | `haxe build-php.hxml`   | `php bin/php/index.php`    |
| **Neko**             | `haxe build-neko.hxml`  | `neko bin/server.n`        |
| **HashLink**         | `haxe build-hl.hxml`    | `hl bin/server.hl`         |

> JS/Node.js hedefi `node:http`, diğer hedefler `sys.net.Socket` kullanır;
> ikisi de aynı `Request`/`Response` hattını besler.
> The JS/Node.js target uses `node:http`; other targets use `sys.net.Socket`.
> Both feed the same `Request`/`Response` pipeline.

## Özellikler / Features

- **Router** — `:param` path parametreleri ve `*` catch-all desteği
  `:param` path parameters and `*` catch-all support
- **Middleware zinciri** — `next()` ile sıralı işleme
  Middleware chain — sequential processing with `next()`
- **CORS** — preflight (OPTIONS) dahil otomatik yanıt
  automatic response including preflight (OPTIONS)
- **JSON** — `haxe.Json` tabanlı request body parse + response serialize
  `haxe.Json` based request body parsing and response serialization
- **Statik dosya servisi** — `..` koruması ve MIME haritası ile
  static file serving with `..` protection and MIME map
- **Query string** — `?sayfa=2&limit=10` otomatik `req.query` kullanımı
  automatic `req.query` population from query strings
- **Sıfır bağımlılık** — yalnızca Haxe standart kütüphanesi
  zero dependencies — only the Haxe standard library
- **MIT Lisansı** + GitHub Actions CI (Neko + Node + PHP)
  MIT License + GitHub Actions CI (Neko + Node + PHP)

## Hızlı Başlangıç / Quick Start

```bash
# 1) Repoyu al
git clone https://github.com/pixelanso/pixel-haxe
cd pixel-haxe

# 2) Node.js hedefine derle
haxe build-node.hxml

# 3) Çalıştır
node bin/Node/server.js
# -> http://localhost:8080
```

Portu değiştirmek için / To change the port:

```bash
PORT=3000 node bin/Node/server.js
```
## Örnek Uç Noktalar / Example Endpoints

| Metot / Method | Path              | Açıklama              | Description          |
|----------------|-------------------|-----------------------|----------------------|
| `GET`          | `/`               | Hizmet bilgisi        | Service info         |
| `GET`          | `/health`         | Sağlık kontrolü       | Health check         |
| `GET`          | `/api/users`      | Kullanıcı listesi     | User list            |
| `GET`          | `/api/users/:id`  | Tek kullanıcı         | Single user          |
| `POST`         | `/api/users`      | Yeni kullanıcı (JSON) | Create user (JSON)   |
| `PUT`          | `/api/users/:id`  | Kullanıcıyı güncelle  | Update user          |
| `DELETE`       | `/api/users/:id`  | Kullanıcıyı sil       | Delete user          |

```bash
curl http://localhost:8080/api/users/2
# {"id": "2", "name": "Mehmet", "role": "user"}

curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Deniz"}'
```

## Framework Kullanımı / Framework Usage

Kendi uygulamanı 30 saniyede kur.
Build your own app in 30 seconds.

```haxe
import pixel.Pixel;
import pixel.Request;
import pixel.Response;
import pixel.Platform;

class Main {
    static function main() {
        var app = Pixel.create();

        // istek logu middleware'i / request logging middleware
        app.use(function(req:Request, res:Response, next:Void->Void) {
            Platform.println("--> " + req.method + " " + req.path);
            next();
        });

        app.cors();                          // CORS aç / enable CORS
        app.serveStatic("public");           // statik dosyalar / static files

        app.get("/api/users/:id", function(req, res) {
            res.json({ id: req.param("id") });
        });

        app.post("/api/echo", function(req, res) {
            var body = req.jsonBody();
            if (body == null) {
                res.status(400).json({ error: "Gecersiz JSON / Invalid JSON" });
                return;
            }
            res.status(201).json({ received: body });
        });

        app.listen(8080);
    }
}
```

## Geliştirici Komutları / Developer Commands

```bash
haxe build-node.hxml    # -> bin/Node/server.js   (node bin/Node/server.js)
haxe build-neko.hxml    # -> bin/server.n         (neko bin/server.n)
haxe build-php.hxml     # -> bin/php/index.php    (php bin/php/index.php)
haxe build-test.hxml    # -> birim testler / unit tests (neko bin/test.n)
haxe run.hxml           # kısayol / shortcut (Node target)
```

## Yol Haritası / Roadmap

- [x] Router (`:param`, `*`), middleware, CORS, JSON, statik
  Router, middleware, CORS, JSON, static files
- [ ] Rota grubu / prefix ile rota tanımlama
  Route groups / prefix routing
- [ ] Query + JSON body'nin resmi request nesnesinde birleştirilmesi
  Unified query + JSON body request object
- [ ] Temel auth: Bearer token middleware'i
  Basic auth: Bearer token middleware
- [ ] Rate limiting (basit in-memory)
  Basic in-memory rate limiting
- [ ] OpenAPI/Swagger dokümantasyon üretici
  OpenAPI/Swagger documentation generator
- [ ] WebSocket desteği
  WebSocket support
- [ ] `haxelib publish` ile resmî paket sürümü
  Official package release via `haxelib publish`

## Lisans / License

[MIT](LICENSE) — © 2026 [pixelanso](https://github.com/pixelanso)
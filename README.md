<div align="center">

# 🎨 Pixel Api — `pixel-haxe`

**Hafif ve çok hedefli Haxe API mikro-framework'ü**

Router · Middleware · CORS · JSON · Statik dosya — **tek kod tabanı, çoklu çalışma ortamı**

</div>

---

## ✨ Nedir?

Pixel Api, Haxe ile yazılmış sıfır bağımlılıklı bir **HTTP API mikro-framework'üdür**.
Yerleşik HTTP sunucusu sayesinde aynı Haxe kodunu farklı hedeflere derleyip aynen
çalıştırabilirsin:

| Hedef        | Derleme                  | Çalıştırma               |
|--------------|--------------------------|--------------------------|
| **Node.js**  | `haxe build-node.hxml`   | `node bin/Node/server.js` |
| **PHP**      | `haxe build-php.hxml`    | `php bin/php/index.php`  |
| **Neko**     | `haxe build-neko.hxml`   | `neko bin/server.n`      |
| **HashLink** | `haxe build-hl.hxml`     | `hl bin/server.hl`       |

> JS/Node.js hedefi `node:http`, diğer hedefler `sys.net.Socket` kullanır;
> ikisi de aynı `Request`/`Response` hattını besler.

## ✨ Özellikler

- ✅ **Router** — `:param` path parametreleri ve `*` catch-all desteği
- ✅ **Middleware zinciri** — `next()` ile sıralı işleme
- ✅ **CORS** — preflight (OPTIONS) dahil otomatik yanıt
- ✅ **JSON** — `haxe.Json` tabanlı request body parse + response serialize
- ✅ **Statik dosya servisi** — `..` koruması ve MIME haritası ile
- ✅ **Query string** — `?sayfa=2&limit=10` otomatik `req.query` kullanımı
- ✅ **Sıfır bağımlılık** — yalnızca Haxe standart kütüphanesi (haxe.Json, sys.*, node:http)
- ✅ **MIT Lisansı** + GitHub Actions CI (Neko + Node + PHP)

## 🚀 Hızlı Başlangıç

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

Portu değiştirmek için:

```bash
PORT=3000 node bin/Node/server.js
```

## 🌐 Örnek Uç Noktalar

| Metot   | Path              | Açıklama                    |
|---------|-------------------|-----------------------------|
| `GET`   | `/`               | Hizmet bilgisi              |
| `GET`   | `/health`         | Sağlık kontrolü             |
| `GET`   | `/api/users`      | Kullanıcı listesi           |
| `GET`   | `/api/users/:id`  | Tek kullanıcı               |
| `POST`  | `/api/users`      | Yeni kullanıcı (JSON body)  |
| `PUT`   | `/api/users/:id`  | Kullanıcıyı güncelle        |
| `DELETE`| `/api/users/:id`  | Kullanıcıyı sil             |

```bash
curl http://localhost:8080/api/users/2
# {"id": "2", "name": "Mehmet", "role": "user"}

curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Deniz"}'
```

## 🧩 Framework Kullanımı

Kendi uygulamanı 30 saniyede kur:

```haxe
import pixel.Pixel;
import pixel.Request;
import pixel.Response;

class Main {
    static function main() {
        var app = Pixel.create();

        // istek logu middleware'i
        app.use(function(req:Request, res:Response, next:Void->Void) {
            Sys.println("--> " + req.method + " " + req.path);
            next();
        });

        app.cors();                          // CORS aç
        app.serveStatic("public");           // statik dosyalar

        app.get("/api/users/:id", function(req, res) {
            res.json({ id: req.param("id") });
        });

        app.post("/api/echo", function(req, res) {
            var body = req.jsonBody();
            if (body == null) {
                res.status(400).json({ error: "Gecersiz JSON" });
                return;
            }
            res.status(201).json({ received: body });
        });

        app.listen(8080);
    }
}
```

## 🧰 Geliştirici Komutları

```bash
haxe build-node.hxml    # -> bin/Node/server.js   (çalıştır: node bin/Node/server.js)
haxe build-neko.hxml    # -> bin/server.n         (çalıştır: neko bin/server.n)
haxe build-php.hxml     # -> bin/php/index.php    (çalıştır: php bin/php/index.php)
haxe build-test.hxml    # -> birim testler (Neko) (çalıştır: neko bin/test.n)
haxe run.hxml           # kısayol (Node hedefi)
```

## 🗺️ Yol Haritası

- [x] Router (`:param`, `*`), middleware, CORS, JSON, statik
- [ ] Rota grubu / prefix ile rota tanımlama
- [ ] Query + JSON body'nin resmi `request` nesnesinde birleştirilmesi
- [ ] Temel auth: Bearer token middleware'i
- [ ] Rate limiting (basit in-memory)
- [ ] OpenAPI/Swagger dokümantasyon üretici
- [ ] WebSocket desteği
- [ ] `haxelib publish` ile resmî paket sürümü

## 🤝 Lisans

[MIT](LICENSE) — © 2026 [pixelanso](https://github.com/pixelanso)

---

<sub>README'in İngilizce sürümü yakında.</sub>
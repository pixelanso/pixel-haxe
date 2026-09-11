package pixel;

/**
 * Arka plana tekrarlayan gorevler yerlestirir (cron benzeri).
 * Schedules recurring background tasks (cron-like).
 *
 * ```haxe
 * var scheduler = new pixel.Scheduler();
 * scheduler.every(60, function() {
 *     Platform.println("[heartbeat] users=" + users.length);
 * }, "heartbeat");
 * scheduler.start(); // app.listen() oncesi / before app.listen()
 * ```
 *
 * `tick(now)` elle cagrilabilir; boylece testler senkron yazilabilir.
 * `tick(now)` can be called manually, keeping tests synchronous.
 */
typedef SchedulerTask = {
    name:String,
    intervalSec:Float,
    fn:Void -> Void,
    nextRun:Float,
    runs:Int
};

class Scheduler {
    public var tasks:Array<SchedulerTask>;

    var timer:haxe.Timer;

    public function new() {
        tasks = [];
        timer = null;
    }


    /**
     * Tekrarlayan gorev ekler. Varsayilan olarak ilk tick'te hemen calisir.
     * Adds a recurring task; runs immediately on the first tick by default.
     */
    public function every(intervalSec:Float, fn:Void -> Void, ?name:String = null):Scheduler {
        if (intervalSec <= 0 || Math.isNaN(intervalSec)) intervalSec = 1;
        if (name == null) name = "task" + (tasks.length + 1);
        tasks.push({
            name: name,
            intervalSec: intervalSec,
            fn: fn,
            nextRun: 0,
            runs: 0
        });
        return this;
    }

    /**
     * Vadesi gelen gorevleri calistirir; calistirilan gorev sayisini dondurur.
     * Runs the due tasks; returns how many ran.
     */
    public function tick(?now:Float = -1):Int {
        if (now < 0) now = Platform.time();
        var ran = 0;
        for (t in tasks) {
            if (now >= t.nextRun) {
                t.nextRun = now + t.intervalSec;
                t.runs++;
                ran++;
                try {
                    t.fn();
                } catch (e:Dynamic) {
                    Platform.println("[scheduler] hata / error (" + t.name + "): " + Std.string(e));
                }
            }
        }
        return ran;
    }

    /**
     * Arka plan dongusunu baslatir (haxe.Timer tabanli).
     * Starts the background loop (haxe.Timer based).
     */
    public function start(?tickMs:Int = 500):Scheduler {
        if (timer != null) return this;
        timer = new haxe.Timer(tickMs < 50 ? 50 : tickMs);
        timer.run = function() {
            tick();
        };
        return this;
    }

    /** Arka plan dongusunu durdurur / Stops the background loop. */
    public function stop():Void {
        if (timer != null) {
            timer.stop();
            timer = null;
        }
    }
}

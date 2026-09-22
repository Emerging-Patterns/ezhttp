# ureq/hyper vs ezhttp compare script (embedded; not a checked-in .py file).
# Consumed by writeText / writeShellApplication in default.nix.
#
# Fairness / what the numbers mean:
# - Client: in-process ezhttp GET/POST vs in-process ureq, both against the
#   same hyper server. Disk reads are outside both timers. No per-op spawn.
# - Server: ezhttp serve vs an in-process hyper server, same fixed responses.
#   Request→response is timed by one ureq process, not a CLI wrapper.
# - Load: hey (outside the timed path) reports RPS and p50/p99. Same payload,
#   count, and concurrency on both servers.
# - JSON cases use ezhttp/json.bend on the Bend side and serde_json on the
#   Rust side. Text and octet bodies are the same fixture bytes.
# - Ratio = ezhttp/ref when both timers resolve. If MS stays 0, wall/n is
#   reported and there is no vs claim. Ratios never fail the check.
{ drvBin ? "ezhttp-bench", rustBin ? "ezhttp-rust-ref", heyBin ? "hey" }:
''
import json, os, socket, subprocess, time, traceback

DRV = os.environ.get("EZHTTP_BENCH_DRV", "${drvBin}")
RUST = os.environ.get("EZHTTP_BENCH_RUST", "${rustBin}")
HEY = os.environ.get("EZHTTP_BENCH_HEY", "${heyBin}")
WORK = os.environ.get("EZHTTP_BENCH_WORK", os.path.join(os.environ.get("TMPDIR", "/tmp"), "ezhttp-bench-work"))
MODE = os.environ.get("EZHTTP_BENCH_MODE", "correctness")
LOAD_N = int(os.environ.get("EZHTTP_BENCH_LOAD_N", "40"))
LOAD_C = int(os.environ.get("EZHTTP_BENCH_LOAD_C", "4"))
os.makedirs(WORK, exist_ok=True)

lines, cases, speed_rows = [], [], []
fails = 0

def log(msg=""):
    print(msg, flush=True)
    lines.append(msg)

def run_bin(bin_path, args, timeout):
    t0 = time.perf_counter()
    try:
        r = subprocess.run([bin_path, *args], capture_output=True, timeout=timeout)
        return {"rc": r.returncode, "out": r.stdout.decode("utf-8", "replace"),
                "err": r.stderr.decode("utf-8", "replace"), "wall": time.perf_counter() - t0,
                "timeout": False}
    except subprocess.TimeoutExpired as e:
        out = e.stdout or b""; err = e.stderr or b""
        if isinstance(out, str): out = out.encode()
        if isinstance(err, str): err = err.encode()
        return {"rc": None, "out": out.decode("utf-8", "replace"),
                "err": err.decode("utf-8", "replace"),
                "wall": time.perf_counter() - t0, "timeout": True}

def ez(args, timeout=60):
    return run_bin(DRV, args, timeout)

def rust(args, timeout=60):
    return run_bin(RUST, args, timeout)

def parse_bench(out):
    parts = out.split()
    if len(parts) < 8 or parts[0] != "MS":
        return None
    try:
        return {parts[i]: int(parts[i + 1]) for i in range(0, len(parts) - 1, 2)}
    except ValueError:
        return None

def add_case(group, name, status, detail, hard=True):
    global fails
    cases.append({"group": group, "name": name, "status": status, "detail": detail, "hard": hard})
    log(f"[{status}] {group} | {name}")
    log(f"    {detail}")
    if hard and status != "PASS":
        fails += 1

def write_fixture(name, text):
    path = os.path.join(WORK, name)
    open(path, "w", encoding="utf-8").write(text)
    return path

def load_text(path):
    return open(path, "r", encoding="utf-8").read()

def semantic_eq(a_text, b_text):
    try:
        return json.loads(a_text) == json.loads(b_text)
    except Exception:
        return False

def split_resp(path):
    text = load_text(path)
    status, _, body = text.partition("\n")
    return status, body

def dumps(data):
    return json.dumps(data, ensure_ascii=False, separators=(",", ":"))

def fixtures():
    sentence = "The quick brown fox carries a naive cafe note. "
    text = sentence
    while len(text.encode("utf-8")) < 1000:
        text += sentence
    parts = []
    i = 0
    while sum(len(p) for p in parts) < 256:
        parts.append(f"b{i:03d}:abcdef0123456789;")
        i += 1
    raw = "".join(parts)[:256]
    small = {
        "api": "v1",
        "user": {"id": 42, "name": "Ada Lukasiewicz", "roles": ["admin", "ops"]},
        "prefs": {"theme": "dark", "locale": "ja-JP", "flags": {"beta": True, "extra": None}},
        "nums": [0, -1, 3, 1000000],
        "tree": {"a": {"b": {"c": [1, 2, {"d": "depth"}]}}},
        "note": "naive cafe",
        "city": "東京",
        "pad": "",
    }
    def grow_small(obj):
        obj["pad"] = obj.get("pad", "") + ("x" * 40)
    text_small = dumps(small)
    guard = 0
    while len(text_small.encode("utf-8")) < 1000 and guard < 1000:
        grow_small(small)
        text_small = dumps(small)
        guard += 1

    def row(k):
        return {
            "id": k,
            "sku": f"SKU-{k:05d}",
            "name": f"item-{k}",
            "qty": k % 500,
            "tags": [f"t{j}" for j in range(1 + (k % 4))],
            "meta": {"active": k % 2 == 0, "note": "tokyo" if k % 3 == 0 else "plain"},
        }
    medium = {"catalog": [row(k) for k in range(30)], "summary": {"count": 30, "currency": "USD"}}
    text_medium = dumps(medium)
    guard = 0
    while len(text_medium.encode("utf-8")) < 8000 and guard < 5000:
        medium["catalog"].append(row(len(medium["catalog"])))
        medium["summary"]["count"] = len(medium["catalog"])
        text_medium = dumps(medium)
        guard += 1
    bad = '{"a"'
    paths = {
        "text": write_fixture("text.txt", text),
        "bytes": write_fixture("bytes.txt", raw),
        "small": write_fixture("small.json", text_small),
        "medium": write_fixture("medium.json", text_medium),
        "bad": write_fixture("bad.json", bad),
    }
    bodies = {
        "text": text,
        "bytes": raw,
        "small": text_small,
        "medium": text_medium,
        "bad": bad,
    }
    return paths, bodies

def free_port():
    sock = socket.socket()
    sock.bind(("127.0.0.1", 0))
    port = sock.getsockname()[1]
    sock.close()
    return port

def start_server(kind, port, limit, paths):
    err_path = os.path.join(WORK, f"srv-{kind}-{port}.err")
    logf = open(err_path, "w", encoding="utf-8")
    if kind == "ez":
        cmd = [DRV, "serve", str(port), str(limit)]
    else:
        cmd = [RUST, "serve", str(port), paths["text"], paths["bytes"], paths["small"], paths["medium"]]
    proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=logf)
    return {"proc": proc, "err": err_path, "logf": logf, "kind": kind, "port": port}

def stop_server(srv):
    proc = srv["proc"]
    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=3)
    srv["logf"].close()

def err_tail(path):
    try:
        data = open(path, "r", encoding="utf-8", errors="replace").read()
    except Exception:
        return ""
    return data[-300:].replace("\n", " ")

def port_listening(port):
    want = f"{port:04X}"
    for name in ("/proc/net/tcp", "/proc/net/tcp6"):
        try:
            lines = open(name, encoding="utf-8", errors="replace").read().splitlines()
        except OSError:
            continue
        for line in lines[1:]:
            parts = line.split()
            if len(parts) < 4 or parts[3] != "0A":
                continue
            _ip, _, port_hex = parts[1].rpartition(":")
            if port_hex.upper() == want:
                return True
    return False

def wait_port(port, proc, err_path, timeout=30):
    # A connect would be an accepted request. serve_once has only one, and
    # serve's limit is the measured N, so readiness is the LISTEN row.
    deadline = time.time() + timeout
    while time.time() < deadline:
        if proc.poll() is not None:
            return False
        if port_listening(port):
            return True
        time.sleep(0.05)
    return False

def url_for(port, path):
    return f"http://127.0.0.1:{port}{path}"

def check_exchange(group, name, result, dst, want_status, want_body, semantic=False):
    if result["timeout"] or result["rc"] != 0 or not os.path.exists(dst):
        add_case(group, name, "FAIL", f"rc={result['rc']} err={result['err'][:180]}")
        return
    status, body = split_resp(dst)
    if semantic:
        ok = status == want_status and semantic_eq(body, want_body)
    else:
        ok = status == want_status and body == want_body
    add_case(group, name, "PASS" if ok else "FAIL",
             f"status={status} want={want_status} bytes={len(body.encode('utf-8'))} semantic={semantic}")

def run_client(which, args, timeout=60):
    if which == "ez":
        return ez(args, timeout)
    return rust(args, timeout)

def correct_pair(which, port, paths, bodies):
    label = "ezhttp" if which == "ez" else "ureq"
    pairs = [
        ("get", "/text", "text", False, "text"),
        ("get", "/bytes", "bytes", False, "bytes"),
        ("get", "/json/small", "json-small", True, "small"),
        ("get", "/json/medium", "json-medium", True, "medium"),
        ("post", "/text", "text", False, "text"),
        ("post", "/bytes", "bytes", False, "bytes"),
        ("post-bytes", "/bytes", "octets", False, "bytes"),
        ("post-json", "/json/small", "json-small", True, "small"),
        ("post-json", "/json/medium", "json-medium", True, "medium"),
        ("post", "/json/small", "bad-json", False, "bad"),
    ]
    for cmd, path, name, semantic, key in pairs:
        dst = os.path.join(WORK, f"{which}-{cmd}-{name}.out")
        target = url_for(port, path)
        if cmd == "get":
            result = run_client(which, ["get", target, dst], 60)
            want_status = "200"
            want = bodies[key]
        elif cmd == "post-json":
            result = run_client(which, ["post-json", target, paths[key], dst], 90)
            want_status = "200"
            want = bodies[key]
        else:
            result = run_client(which, [cmd, target, paths[key], dst], 60)
            if key == "bad":
                want_status = "400"
                want = "bad json"
                semantic = False
            else:
                want_status = "200"
                want = bodies[key]
        check_exchange(f"{label} client", f"{cmd} {name}", result, dst, want_status, want, semantic)

def correct_json_helpers(paths, bodies):
    for name in ("small", "medium"):
        ez_dst = os.path.join(WORK, f"ez-json-ok-{name}.out")
        rs_dst = os.path.join(WORK, f"rs-json-ok-{name}.out")
        er = ez(["json-ok", paths[name], ez_dst], 60)
        rr = rust(["json-ok", paths[name], rs_dst], 30)
        if er["rc"] != 0 or rr["rc"] != 0 or not os.path.exists(ez_dst) or not os.path.exists(rs_dst):
            add_case("json helper", name, "FAIL", f"ez={er['rc']} rust={rr['rc']} ez_err={er['err'][:120]}")
            continue
        ez_out, rs_out = load_text(ez_dst), load_text(rs_dst)
        ok = semantic_eq(ez_out, bodies[name]) and semantic_eq(rs_out, bodies[name]) and semantic_eq(ez_out, rs_out)
        add_case("json helper", name, "PASS" if ok else "FAIL",
                 f"ez={len(ez_out)}B rust={len(rs_out)}B in={len(bodies[name].encode('utf-8'))}B")

def correct_serve_once(paths, bodies):
    port = free_port()
    err_path = os.path.join(WORK, f"once-{port}.err")
    logf = open(err_path, "w", encoding="utf-8")
    proc = subprocess.Popen(
        [DRV, "serve-once", str(port)],
        stdout=subprocess.DEVNULL, stderr=logf)
    ok_port = wait_port(port, proc, err_path, 30)
    dst = os.path.join(WORK, "once-get.out")
    if not ok_port:
        add_case("serve_once", "listen", "FAIL", err_tail(err_path))
        proc.kill()
        proc.wait(timeout=3)
        logf.close()
        return
    result = rust(["get", url_for(port, "/text"), dst], 30)
    try:
        proc.wait(timeout=10)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait(timeout=3)
    logf.close()
    if result["rc"] != 0 or not os.path.exists(dst):
        add_case("serve_once", "GET /text", "FAIL", f"rc={result['rc']} err={result['err'][:160]}")
        return
    status, body = split_resp(dst)
    exited = proc.poll() == 0
    ok = status == "200" and body == bodies["text"] and exited
    add_case("serve_once", "GET /text", "PASS" if ok else "FAIL",
             f"status={status} exit={proc.poll()} bytes={len(body.encode('utf-8'))}")

def correct(paths, bodies):
    log("\n== Correctness (hard; ratios are not) ==")
    correct_json_helpers(paths, bodies)
    port = free_port()
    srv = start_server("rust", port, 0, paths)
    if not wait_port(port, srv["proc"], srv["err"], 30):
        add_case("hyper", "listen", "FAIL", err_tail(srv["err"]))
        stop_server(srv)
    else:
        correct_pair("ez", port, paths, bodies)
        correct_pair("rust", port, paths, bodies)
        stop_server(srv)
    port = free_port()
    srv = start_server("ez", port, 24, paths)
    if not wait_port(port, srv["proc"], srv["err"], 30):
        add_case("ezhttp serve", "listen", "FAIL", err_tail(srv["err"]))
        stop_server(srv)
    else:
        correct_pair("rust", port, paths, bodies)
        correct_pair("ez", port, paths, bodies)
        stop_server(srv)
    correct_serve_once(paths, bodies)

def ms_per(parsed, wall, n):
    if parsed is None or n <= 0:
        return None, "no-parse"
    if parsed["MS"] > 0:
        return parsed["MS"] / float(n), "timer"
    return (wall * 1000.0 / float(n)), "MS=0; wall/n"

def run_bench_bump(bin_path, args_prefix, n0, timeout, max_n):
    n = n0
    last = None
    while True:
        r = run_bin(bin_path, [*args_prefix, str(n)], timeout)
        parsed = parse_bench(r["out"]) if not r["timeout"] else None
        last = (r, parsed, n)
        if r["timeout"] or parsed is None:
            return last
        if parsed["MS"] > 0 or n >= max_n:
            return last
        n = min(max_n, max(n * 4, n + 1))
    return last

def format_row(op, name, nbytes, r_ez, p_ez, n_ez, r_rs, p_rs, n_rs):
    if r_ez["timeout"] or r_rs["timeout"]:
        return f"TIMEOUT {op} {name} ez_n={n_ez} ref_n={n_rs}"
    if p_ez is None or p_rs is None:
        return (f"ERROR {op} {name} ez_rc={r_ez['rc']} ref_rc={r_rs['rc']} "
                f"ez_err={r_ez['err'][:120]!r} ref_err={r_rs['err'][:120]!r} "
                f"ez_out={r_ez['out']!r} ref_out={r_rs['out']!r}")
    ez_per, ez_note = ms_per(p_ez, r_ez["wall"], n_ez)
    rs_per, rs_note = ms_per(p_rs, r_rs["wall"], n_rs)
    if p_ez["MS"] > 0 and p_rs["MS"] > 0 and rs_per and rs_per > 0:
        ratio = ez_per / rs_per
        return (f"{op:18} {name:<12} {nbytes:7}B  "
                f"N_ez={n_ez:<5} N_ref={n_rs:<5}  "
                f"ezhttp {ez_per:10.4f} ms/op ({ez_note})  "
                f"ref {rs_per:10.4f} ms/op ({rs_note})  "
                f"ratio {ratio:8.1f}x")
    return (f"{op:18} {name:<12} {nbytes:7}B  "
            f"N_ez={n_ez:<5} N_ref={n_rs:<5}  "
            f"ezhttp {ez_per:10.4f} ms/op ({ez_note}; no vs claim)  "
            f"ref {rs_per:10.4f} ms/op ({rs_note})")

def speed_client(port, paths, bodies):
    log("\n== Client (in-process ezhttp vs ureq, same hyper server) ==")
    log("Disk open is outside the timers. Ratio = ezhttp/ref when both MS > 0.")
    specs = [
        ("client-get", "text", ["bench-get", url_for(port, "/text")], 8, 8192, 120, len(bodies["text"].encode("utf-8"))),
        ("client-get", "bytes", ["bench-get", url_for(port, "/bytes")], 8, 8192, 120, len(bodies["bytes"].encode("utf-8"))),
        ("client-get", "json-small", ["bench-get-json", url_for(port, "/json/small")], 4, 2048, 180, len(bodies["small"].encode("utf-8"))),
        ("client-get", "json-medium", ["bench-get-json", url_for(port, "/json/medium")], 2, 256, 180, len(bodies["medium"].encode("utf-8"))),
        ("client-post", "text", ["bench-post", url_for(port, "/text"), paths["text"]], 4, 2048, 120, len(bodies["text"].encode("utf-8"))),
        ("client-post", "bytes", ["bench-post-bytes", url_for(port, "/bytes"), paths["bytes"]], 4, 1024, 180, len(bodies["bytes"].encode("utf-8"))),
        ("client-post", "json-small", ["bench-post-json", url_for(port, "/json/small"), paths["small"]], 2, 512, 180, len(bodies["small"].encode("utf-8"))),
        ("client-post", "json-medium", ["bench-post-json", url_for(port, "/json/medium"), paths["medium"]], 2, 128, 180, len(bodies["medium"].encode("utf-8"))),
    ]
    for op, name, prefix, n0, max_n, timeout, nbytes in specs:
        r_ez, p_ez, n_ez = run_bench_bump(DRV, prefix, n0, timeout, max_n)
        r_rs, p_rs, n_rs = run_bench_bump(RUST, prefix, n0, timeout, max_n)
        row = format_row(op, name, nbytes, r_ez, p_ez, n_ez, r_rs, p_rs, n_rs)
        log(row)
        speed_rows.append(row)

def probe_server(kind, paths, probe_prefix, n, timeout):
    port = free_port()
    limit = n if kind == "ez" else 0
    srv = start_server(kind, port, limit, paths)
    if not wait_port(port, srv["proc"], srv["err"], 30):
        stop_server(srv)
        return {"rc": 1, "out": "", "err": "listen failed " + err_tail(srv["err"]), "wall": 0.0, "timeout": False}
    path = probe_prefix[1]
    args = [probe_prefix[0], url_for(port, path), *probe_prefix[2:], str(n)]
    result = run_bin(RUST, args, timeout)
    stop_server(srv)
    return result

def run_server_bump(kind, paths, probe_prefix, n0, timeout, max_n):
    n = n0
    last = None
    while True:
        r = probe_server(kind, paths, probe_prefix, n, timeout)
        parsed = parse_bench(r["out"]) if not r["timeout"] else None
        last = (r, parsed, n)
        if r["timeout"] or parsed is None:
            return last
        if parsed["MS"] > 0 or n >= max_n:
            return last
        n = min(max_n, max(n * 4, n + 1))
    return last

def speed_server(paths, bodies):
    log("\n== Server (request to response, in-process ureq vs ezhttp serve and hyper) ==")
    log("Same probe, same payloads. Startup is outside the probe timer.")
    specs = [
        ("server-get", "text", ["bench-get", "/text"], 8, 8192, 120, len(bodies["text"].encode("utf-8"))),
        ("server-get", "bytes", ["bench-get", "/bytes"], 8, 8192, 120, len(bodies["bytes"].encode("utf-8"))),
        ("server-get", "json-small", ["bench-get", "/json/small"], 8, 8192, 120, len(bodies["small"].encode("utf-8"))),
        ("server-get", "json-medium", ["bench-get", "/json/medium"], 4, 2048, 180, len(bodies["medium"].encode("utf-8"))),
        ("server-post", "text", ["bench-post", "/text", paths["text"]], 4, 2048, 120, len(bodies["text"].encode("utf-8"))),
        ("server-post", "bytes", ["bench-post-bytes", "/bytes", paths["bytes"]], 4, 1024, 180, len(bodies["bytes"].encode("utf-8"))),
        ("server-post", "json-small", ["bench-post", "/json/small", paths["small"]], 4, 1024, 180, len(bodies["small"].encode("utf-8"))),
        ("server-post", "json-medium", ["bench-post", "/json/medium", paths["medium"]], 2, 256, 180, len(bodies["medium"].encode("utf-8"))),
    ]
    for op, name, prefix, n0, max_n, timeout, nbytes in specs:
        r_ez, p_ez, n_ez = run_server_bump("ez", paths, prefix, n0, timeout, max_n)
        r_rs, p_rs, n_rs = run_server_bump("rust", paths, prefix, n0, timeout, max_n)
        row = format_row(op, name, nbytes, r_ez, p_ez, n_ez, r_rs, p_rs, n_rs)
        log(row)
        speed_rows.append(row)

def parse_hey(text):
    rps = p50 = p99 = None
    for line in text.splitlines():
        if "Requests/sec" in line:
            bits = line.replace(":", " ").split()
            for bit in reversed(bits):
                try:
                    rps = float(bit)
                    break
                except ValueError:
                    continue
        parts = line.strip().split()
        if len(parts) >= 4 and parts[1] == "in" and parts[0].endswith("%"):
            try:
                pct = int(parts[0][:-1])
                val = float(parts[2])
            except ValueError:
                continue
            unit = parts[3]
            ms = val * 1000.0 if unit.startswith("sec") else val
            if pct == 50:
                p50 = ms
            if pct == 99:
                p99 = ms
    return rps, p50, p99

def hey_once(port, path, post_file, ctype):
    cmd = [HEY, "-n", str(LOAD_N), "-c", str(LOAD_C)]
    if post_file:
        cmd += ["-m", "POST", "-D", post_file, "-T", ctype]
    cmd.append(url_for(port, path))
    return run_bin(HEY, cmd[1:], max(120, LOAD_N * 3))

def load_one(kind, paths, path, post_file, ctype):
    port = free_port()
    limit = max(LOAD_N + 8, LOAD_N * max(LOAD_C, 1))
    srv = start_server(kind, port, limit if kind == "ez" else 0, paths)
    if not wait_port(port, srv["proc"], srv["err"], 30):
        stop_server(srv)
        return None, "listen failed " + err_tail(srv["err"])
    result = hey_once(port, path, post_file, ctype)
    stop_server(srv)
    if result["timeout"] or result["rc"] not in (0, None):
        if result["rc"] != 0:
            blob = (result["out"] + "\n" + result["err"])[-400:]
            return None, f"hey rc={result['rc']} {blob}"
    stats = parse_hey(result["out"] + "\n" + result["err"])
    return stats, result["out"]

def fmt_metric(val, digits):
    if val is None:
        return "n/a"
    return f"{val:.{digits}f}"

def format_load(op, name, ez_stats, rs_stats):
    ez_rps, ez_p50, ez_p99 = ez_stats if ez_stats else (None, None, None)
    rs_rps, rs_p50, rs_p99 = rs_stats if rs_stats else (None, None, None)
    def one(label, ez, rs):
        if ez is None or rs is None or rs == 0:
            return f"{label} no vs claim"
        return f"{label} ratio {ez / rs:8.3f}x"
    return (f"{op:18} {name:<12} n={LOAD_N:<4} c={LOAD_C:<3}  "
            f"ezhttp rps={fmt_metric(ez_rps, 2):>10} p50={fmt_metric(ez_p50, 3):>10} ms p99={fmt_metric(ez_p99, 3):>10} ms  "
            f"ref rps={fmt_metric(rs_rps, 2):>10} p50={fmt_metric(rs_p50, 3):>10} ms p99={fmt_metric(rs_p99, 3):>10} ms  "
            f"{one('rps', ez_rps, rs_rps)}  {one('p50', ez_p50, rs_p50)}  {one('p99', ez_p99, rs_p99)}")

def speed_load(paths):
    log("\n== Load (hey outside the servers; same payload and concurrency) ==")
    log("p50/p99 are milliseconds. Ratio = ezhttp/ref when both sides parse.")
    specs = [
        ("load-get", "text", "/text", None, None),
        ("load-get", "bytes", "/bytes", None, None),
        ("load-get", "json-small", "/json/small", None, None),
        ("load-get", "json-medium", "/json/medium", None, None),
        ("load-post", "text", "/text", paths["text"], "text/plain"),
        ("load-post", "bytes", "/bytes", paths["bytes"], "application/octet-stream"),
        ("load-post", "json-small", "/json/small", paths["small"], "application/json"),
        ("load-post", "json-medium", "/json/medium", paths["medium"], "application/json"),
    ]
    for op, name, path, post_file, ctype in specs:
        ez_stats, ez_detail = load_one("ez", paths, path, post_file, ctype)
        rs_stats, rs_detail = load_one("rust", paths, path, post_file, ctype)
        if ez_stats is None or rs_stats is None:
            row = f"ERROR {op} {name} ez={ez_detail!r} ref={rs_detail!r}"
        else:
            row = format_load(op, name, ez_stats, rs_stats)
        log(row)
        speed_rows.append(row)

def speed(paths, bodies):
    log("\n== Speed (printable; does not fail the check) ==")
    port = free_port()
    srv = start_server("rust", port, 0, paths)
    if not wait_port(port, srv["proc"], srv["err"], 30):
        log("ERROR client track: hyper did not listen " + err_tail(srv["err"]))
        stop_server(srv)
    else:
        try:
            speed_client(port, paths, bodies)
        finally:
            stop_server(srv)
    speed_server(paths, bodies)
    speed_load(paths)

def main():
    log("ezhttp vs ureq/hyper bench (Nix-embedded)")
    log(f"driver={DRV}")
    log(f"rust={RUST}")
    log(f"hey={HEY}")
    log(f"mode={MODE}")
    ping = ez(["ping"], 15)
    if ping["out"].strip() != "pong":
        log("FAIL: ezhttp driver ping"); log(repr(ping)); raise SystemExit(2)
    log("ezhttp driver ping ok")
    rping = rust(["ping"], 10)
    if rping["out"].strip() != "pong":
        log("FAIL: rust ref ping"); log(repr(rping)); raise SystemExit(2)
    log("rust ref ping ok")
    paths, bodies = fixtures()
    log(f"fixtures text={len(bodies['text'].encode('utf-8'))}B bytes={len(bodies['bytes'].encode('utf-8'))}B "
        f"json-small={len(bodies['small'].encode('utf-8'))}B json-medium={len(bodies['medium'].encode('utf-8'))}B")
    try:
        if MODE in ("correctness", "all"):
            correct(paths, bodies)
        if MODE in ("speed", "all"):
            speed(paths, bodies)
    except Exception:
        log("HARNESS EXCEPTION"); log(traceback.format_exc()); raise SystemExit(2)
    log(f"\n== Summary: {fails} hard failure(s) of {len(cases)} cases ==")
    for c in cases:
        if c["status"] != "PASS" and c["hard"]:
            log(f"  FAIL {c['group']} | {c['name']}")
    if speed_rows:
        log("\n== Tables ==")
        for row in speed_rows:
            log(row)
    if fails:
        raise SystemExit(1)
    log("ALL HARD CHECKS PASSED")

if __name__ == "__main__":
    main()
''

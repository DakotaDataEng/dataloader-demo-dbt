"""Demo Python job: summarise invented well tests, write a CSV, print a summary line.

Modes (first argument): ok (default), fail (prints an error and exits 3), sleep (for the Stop check).
"""
import csv, json, os, sys, time

import six  # a real dependency, so the first run installs and the second reuses the environment

mode = sys.argv[1] if len(sys.argv) > 1 else "ok"
print(f"well test summary starting, mode={mode}, python={sys.version.split()[0]}", flush=True)
print(f"DEMO_REGION={os.environ.get('DEMO_REGION', '')}", flush=True)
token = os.environ.get("DEMO_SECRET")
print(f"DEMO_SECRET present: {token is not None}, length: {len(token) if token else 0}", flush=True)
print("progress note on stderr", file=sys.stderr, flush=True)

if mode == "fail":
    print("ERROR: well test source unreachable (demo failure)", file=sys.stderr, flush=True)
    sys.exit(3)
if mode == "sleep":
    for i in range(300):
        print(f"waiting {i}", flush=True)
        time.sleep(1)

rows = [("W-001", 412.5), ("W-002", 388.0), ("W-003", 450.25)]
with open(os.path.join(os.environ["DL_OUTPUT_DIR"], "well_test_summary.csv"), "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["well", "oil_bbl_d"])
    w.writerows(rows)
print("DL_SUMMARY " + json.dumps({"rows": len(rows), "message": "Demo well test summary"}))

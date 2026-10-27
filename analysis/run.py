"""Reproduce the analysis: python analysis/run.py   (needs: pip install duckdb)"""
import json, re, tempfile, urllib.request
from pathlib import Path
import duckdb

URL = "https://raw.githubusercontent.com/fivethirtyeight/data/master/college-majors/recent-grads.csv"
HERE = Path(__file__).parent

csv_path = Path(tempfile.gettempdir()) / "recent-grads.csv"
if not csv_path.exists():
    urllib.request.urlretrieve(URL, csv_path)

con = duckdb.connect()
con.execute(f"CREATE VIEW grads AS SELECT * FROM read_csv('{csv_path.as_posix()}', header = true)")

sql = (HERE / "majors.sql").read_text(encoding="utf-8")
blocks = re.split(r"^-- name: (\w+)\s*$", sql, flags=re.M)[1:]
results = {}
for name, body in zip(blocks[::2], blocks[1::2]):
    cur = con.execute(body)
    cols = [c[0] for c in cur.description]
    rows = [dict(zip(cols, r)) for r in cur.fetchall()]
    results[name] = rows
    print(f"\n== {name}")
    for r in rows:
        print("  ", r)

(HERE / "results.json").write_text(json.dumps(results, indent=2, default=str), encoding="utf-8")
print("\nwrote analysis/results.json")

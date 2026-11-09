#!/usr/bin/env python3
"""Call the Simular Box MCP client for the `screenshot` tool and save any
image content blocks to a file WITHOUT printing base64. Usage:
  box_shot.py <out.png> [extra tool args as JSON]
Also supports: box_shot.py --state  (prints computer_state JSON, no image)
"""
import json, subprocess, sys, base64, os

CLIENT = "/home/hatch/workspace/custom-connectors/custom.simular-box/bin/client.py"

def call(tool, args):
    with open("/tmp/box_shot_args.json", "w") as f:
        json.dump(args, f)
    r = subprocess.run(["python3", CLIENT, "call-tool", "--name", tool,
                        "--arguments-file", "/tmp/box_shot_args.json"],
                       capture_output=True, text=True, timeout=180)
    try:
        return json.loads(r.stdout)
    except Exception:
        print("CLIENT RAW STDOUT (truncated):", r.stdout[:2000])
        print("CLIENT STDERR:", r.stderr[:2000])
        raise

if __name__ == "__main__":
    if sys.argv[1] == "--state":
        print(json.dumps(call("computer_state", {}), indent=1)[:3000])
        sys.exit(0)
    out = sys.argv[1]
    extra = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
    res = call("screenshot", extra)
    saved = None
    for block in res.get("content", []):
        if block.get("type") == "image" and block.get("data"):
            raw = base64.b64decode(block["data"])
            with open(out, "wb") as f:
                f.write(raw)
            saved = (out, len(raw), block.get("mimeType"))
    if saved:
        print("saved", saved)
    else:
        print("NO IMAGE in result:", json.dumps(res)[:2000])
        sys.exit(1)

import urllib.request, json, os

req = urllib.request.Request("https://api.github.com/repos/transmission/transmission/releases")
req.add_header("User-Agent", "GitHub-Actions")

with urllib.request.urlopen(req) as response:
    releases = json.loads(response.read().decode())

stable = next((r for r in releases if not r["prerelease"]), None)
latest = releases[0] if releases else None

builds = {}
def add_build(ref, tag):
    if ref not in builds: builds[ref] = []
    builds[ref].append(tag)

add_build("main", "main")

if stable:
    add_build(stable["tag_name"], stable["tag_name"])
    add_build(stable["tag_name"], "latest")

if latest:
    add_build(latest["tag_name"], latest["tag_name"])
    add_build(latest["tag_name"], "latest-include-beta")

matrix = [{"ref": ref, "tags": list(set(tags))} for ref, tags in builds.items()]

with open(os.environ["GITHUB_OUTPUT"], "a") as f:
    f.write(f"matrix={json.dumps(matrix)}\n")

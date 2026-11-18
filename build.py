"""Build the LÖVE archive and portable releases using Python 3.9+."""
import argparse
import hashlib
import io
from pathlib import Path
import shutil
import tarfile
import tempfile
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parent
NAME = "upo"
DIST = ROOT / "dist"
CACHE = ROOT / ".cache"
BASE = "https://github.com/love2d/love/releases/download/11.5/"
RUNTIMES = {
    "windows": (BASE + "love-11.5-win64.zip", "ba6e56be2685e53c817749c4a5007f51137136fe5a3ab64920508babc2e74369"),
    "linux": (BASE + "love-11.5-x86_64.AppImage", "65a673406431eff7167a15a032bf7a2e4ba50108e091eb7b176465831f9b5e00"),
    "web": ("https://registry.npmjs.org/love.js/-/love.js-11.4.1.tgz", "9eb2db1f789254faed8e5cf7eeeded46a7e56ecbc931c88be809526c448d25fb"),
}


def runtime(target):
    url, digest = RUNTIMES[target]
    path = CACHE / url.rsplit("/", 1)[1]
    CACHE.mkdir(exist_ok=True)
    if path.exists() and hashlib.sha256(path.read_bytes()).hexdigest() == digest:
        return path
    with tempfile.TemporaryDirectory(dir=CACHE) as temp:
        download = Path(temp) / path.name
        print("Downloading", path.name, flush=True)
        with urllib.request.urlopen(url, timeout=90) as stream, download.open("wb") as out:
            shutil.copyfileobj(stream, out)
        if hashlib.sha256(download.read_bytes()).hexdigest() != digest:
            raise ValueError(f"Checksum mismatch for {path.name}")
        download.replace(path)
    return path


def love_archive(output):
    files = list(ROOT.glob("*.lua")) + list(ROOT.glob("CREDITS.txt"))
    for folder in ("assets", "songs", "levels", "lib", "objects", "managers", "states"):
        files.extend(p for p in (ROOT / folder).rglob("*") if p.is_file())
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(files):
            archive.write(path, path.relative_to(ROOT))


def windows(output, game):
    with zipfile.ZipFile(runtime("windows")) as engine, zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        for item in engine.namelist():
            name = Path(item).name
            if name == "love.exe":
                archive.writestr(NAME + ".exe", engine.read(item) + game.read_bytes())
            elif name.endswith(".dll") or name == "license.txt":
                archive.writestr(name, engine.read(item))
        archive.write(ROOT / "discord-rpc.dll", "discord-rpc.dll")


def linux(output, game):
    launcher = b"""#!/bin/sh
set -eu
cd "$(dirname "$0")"
game_dir=$(pwd)
if [ -r /dev/fuse ] && ldconfig -p 2>/dev/null | grep -q 'libfuse.so.2'; then
    exec ./love.AppImage ./game.love "$@"
fi
# Older AppImage runtimes need extraction on systems without FUSE 2.
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
cd "$work"
"$game_dir/love.AppImage" --appimage-extract >/dev/null
./squashfs-root/AppRun "$game_dir/game.love" "$@"
"""
    with tarfile.open(output, "w:gz") as archive:
        for name, data, mode in [(NAME, launcher, 0o755), ("game.love", game.read_bytes(), 0o644),
                                 ("love.AppImage", runtime("linux").read_bytes(), 0o755)]:
            member = tarfile.TarInfo(NAME + "/" + name)
            member.size, member.mode = len(data), mode
            archive.addfile(member, io.BytesIO(data))


def web(output, game):
    with tarfile.open(runtime("web")) as engine, zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        for name in ("love.js", "love.wasm"):
            archive.writestr(name, engine.extractfile("package/src/compat/" + name).read())
        archive.writestr("license.txt", engine.extractfile("package/LICENSE").read())
        archive.write(ROOT / "web" / "index.html", "index.html")
        archive.write(game, "game.love")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("targets", nargs="*", metavar="TARGET", help="love, web, windows, linux (default: all)")
    parser.add_argument("--serve", action="store_true", help="build and play web locally on port 8000")
    args = parser.parse_args()
    targets = args.targets or (["web"] if args.serve else ["web", "windows", "linux"])
    if args.serve and "web" not in targets:
        targets.append("web")
    if set(targets) - {"web", "windows", "linux", "love"}:
        parser.error("unknown target")
    DIST.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(dir=DIST) as temp:
        stage = Path(temp)
        game = stage / (NAME + ".love")
        love_archive(game)
        for target, build, suffix in [("web", web, "-web.zip"), ("windows", windows, "-windows.zip"),
                                      ("linux", linux, "-linux-x64.tar.gz")]:
            if target in targets:
                output = stage / (NAME + suffix)
                build(output, game)
                output.replace(DIST / output.name)
                print(DIST / output.name)
        game.replace(DIST / game.name)
        print(DIST / game.name)

    if args.serve:
        from functools import partial
        from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
        with tempfile.TemporaryDirectory(dir=DIST) as preview:
            with zipfile.ZipFile(DIST / (NAME + "-web.zip")) as archive:
                archive.extractall(preview)
            handler = partial(SimpleHTTPRequestHandler, directory=preview)
            with ThreadingHTTPServer(("127.0.0.1", 8000), handler) as server:
                print("Open http://localhost:8000 (Ctrl+C to stop)", flush=True)
                try:
                    server.serve_forever()
                except KeyboardInterrupt:
                    pass


if __name__ == "__main__":
    main()

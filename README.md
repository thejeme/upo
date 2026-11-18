# upo

Run from source with LÖVE 11.5 using `love .`.

Tap the original menu items and drag one finger to steer. On a gamepad, use either stick to steer, A to select, X for the secondary action, and Start/Back to end a run. Y toggles stick movement in the menu. Landscape gives the largest playfield on phones.

Run `python build.py` in this folder to create the .love, web ZIP, portable Windows x64 ZIP, and Linux x86_64 tarball in `dist/`. Python 3.9+ and an internet connection for the first runtime download are sufficient. You can also build one target, e.g. `python build.py web`.

Use `python build.py --serve` to test the browser build at http://localhost:8000. To host it, extract the web ZIP to a static HTTPS host. For Windows, extract the entire ZIP and launch upo.exe. For Linux, extract the tarball and run `./upo/upo`.

In Options, cycle through window sizes from smallest to largest, then Fullscreen. Back applies the choice. Window sizes leave room for the frame and taskbar on the current monitor. Fullscreen uses the desktop resolution. The browser fits the game automatically.

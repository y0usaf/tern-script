# tern-run

tern-run opens a fuzzy application launcher in its own chrome-free Tern window.

Install Tern 0.9.11 or later, then run:

```sh
nix build --no-link
nix run
```

Type to filter installed desktop applications. Prefix matches come before substring
and ordered-letter matches. Arrow keys move the selection, Enter opens it,
Backspace edits the query, Ctrl+U clears it, and Escape closes the window.
Terminal applications open a new tab in the main Tern session; graphical applications
start normally. Tern must already be running for terminal application launches.

Each invocation reads Tern settings and the active Mini, Ozette, YoRHa or Grok
look from the existing ui-menu configuration. It uses Tern’s native picker and
loads the look through Tern’s plugin styles, preserving configured fonts and
System light/dark changes without a launcher palette. The launcher owns a
temporary configuration and daemon, removed together when its program or window
closes; it never loads the main window’s accounts or sessions. Window startup and
launcher-session creation run concurrently rather than waiting for one another.
The picker sends a new frame only when input changes its query or selection;
protocol acknowledgements do not trigger another render.

Bind `tern-run` to Win+R. On Tomoe, float and centre windows with app ID
`so.stencil.tern` and title `launcher`; the main terminal has the same app ID.
The flake packages Python; Tern is supplied by the host installation.

On Tomoe, the matching launcher rule can hide its border with
`(window-properties id :border '(:focused "#00000000" :unfocused "#00000000"))`.
Ordinary Tern windows keep their configured border.

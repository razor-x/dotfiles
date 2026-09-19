---
name: mod-pi
description: Modify local Pi extensions or skills.
disable-model-invocation: true
---

# Pi modification

Treat the user's arguments as the requested Pi change.

1. Read Pi's documentation from `/usr/lib/pi` completely, including linked
   references relevant to the change.
2. Locate sources independently of the working directory:
   - Local extensions: `$PI_LOCAL_EXTENSION_SOURCE`
   - Local skills: `$PI_LOCAL_SKILLS_SOURCE`

   Ask for a missing environment-provided location instead of guessing. Create
   new local skills under `$PI_LOCAL_SKILLS_SOURCE`.

   For a system-prompt or global-instructions change, proceed only when its
   authoritative source is in the current repository. Otherwise tell the user
   the request must be made from that repository and offer a copyable handoff
   prompt describing the requested change.
3. Change only those authoritative sources. Keep installed runtime copies under
   `$XDG_CONFIG_HOME/pi` untouched.
4. Run the changed component's checks, then the repository's `just format` and
   `just check`.
5. Call `reload_runtime` to sync and reload Pi. Complete this yourself instead
   of delegating it to the user.
6. For a visual UI change, call `capture_ui` and inspect its returned image.
   If the tool reports an unavailable helper, tell the user: “The capture helper isn’t
   responding. Please restart `just capture-pi-ui` outside the sandbox from the
   Kitty window showing this session, and leave the helper running.”
   Compare the rendered UI with the request. Refine the authoritative source,
   repeat checks and runtime reload, and capture again until the UI is done.

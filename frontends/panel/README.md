# Description
See frontends/common/README.md

# Twitch

Twitch won't accept WebAssembly, but Flutter no longer supports html web renderer since 3.27.4. 
Therefore, when compiling for Twitch, we need to use this version. 
The easiest way to do so is to use `fvm` which is configure for that version. 
You can therefore compile using the command:

```bash
fvm flutter build web --web-renderer html
```
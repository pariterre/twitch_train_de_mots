# configuration

This is the configuration website for the extension

## Web

There is two steps to be able to properly compile the configuration part of the extension:
1. Add the following line to `web/index.html`: `<script src="https://extension-files.twitch.tv/helper/v1/twitch-ext.min.js"></script>`, to either the `<head>` or the `<body>` of the file.
2. Remove the line `<base href="$FLUTTER_BASE_HREF">` in the `<head>` of the file.

Any JS must be in the asset folder as Twitch does not allow external JS files.


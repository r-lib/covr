# Vendored highlight.js

`highlight.min.js` is [highlight.js](https://highlightjs.org/) v11.11.1 with
only the core and the R language, from the npm package
<https://www.npmjs.com/package/highlight.js/v/11.11.1> (source:
<https://github.com/highlightjs/highlight.js/releases/tag/11.11.1>). It sets
`window.covrHljs` instead of `hljs`, so it doesn't replace the `hljs` of a
document that includes a covr report. The colors of the tokens (`hljs-*`
classes) are in `../../report.css`. The license is in `LICENSE`.

To rebuild (needs [bun](https://bun.sh/)):

```sh
npm install highlight.js@11.11.1
cat > entry.js <<'EOF'
import hljs from "highlight.js/lib/core";
import r from "highlight.js/lib/languages/r";
hljs.registerLanguage("r", r);
window.covrHljs = hljs;
EOF
bun build entry.js --minify --format=iife --target=browser --outfile=out.js
```

then prepend the header comment of `highlight.min.js` to `out.js`.

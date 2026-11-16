{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    // Run the Wasm build on Safari (WebKit) and Firefox (Gecko) too.
    // Chromium (blink) is enabled by default.
    wasmAllowList: {
      webkit: true,
      gecko: true,
    },
  },
});

// Compiles a dart2wasm-generated main module from `source` which can then
// be instantiated via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string'], importedStringConstants: ''};
  return new CompiledApp(
      await _compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm module from `bytes` which is then
// instantiable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string'], importedStringConstants: ''};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

let _isCompileStreamingSupported;
async function _compileStreaming(source, builtins) {
  _isCompileStreamingSupported ??= WebAssembly.compileStreaming(
    new Response(
      new Uint8Array([0,97,115,109,1,0,0,0,1,4,1,96,0,0,2,23,1,14,119,97,115,109,58,106,115,45,115,116,114,105,110,103,4,99,97,115,116,0,0]),
      {headers: {'Content-Type': 'application/wasm'}},
    ),
    builtins,
  ).then(() => false, (e) => e instanceof WebAssembly.CompileError);
  if (await _isCompileStreamingSupported) {
    return WebAssembly.compileStreaming(source, builtins);
  }
  return WebAssembly.compile(await (await source).arrayBuffer(), builtins);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredModules` is a JS function that takes an array of module names
  //   matching wasm files produced by the dart2wasm compiler. It also takes a
  //   callback that should be invoked for each loaded module with 2 arguments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDeferredId` is a JS function that takes load ID produced by the
  //   compiler when the `use-load-ids` option is passed. Each load ID maps to
  //   one or more wasm files as specified in the emitted JSON file. It also
  //   takes a callback that should be invoked for each loaded module with 2
  //   arguments: (1) the module name, (2) the loaded module in a format
  //   supported by `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  //   The callback returns a Promise that resolves when the module is
  //   instantiated.
  //   loadDeferredId should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  async instantiate(additionalImports, {loadDeferredModules, loadDeferredId} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            AB: o => o instanceof RegExp,
      AC: o => o.buffer,
      AD: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      AE: (x0,x1) => x0.appendChild(x1),
      AF: (x0,x1) => { x0.action = x1 },
      AG: x0 => new ResizeObserver(x0),
      AH: x0 => x0.clientHeight,
      AI: x0 => x0.isMuted(),
      AJ: x0 => x0.displayWidth,
      AK: (x0,x1) => { x0.width = x1 },
      AL: x0 => x0.body,
      B: s => printToConsole(s),
      BB: o => o,
      BC: (b, o) => new DataView(b, o),
      BD: x0 => x0.state,
      BE: x0 => x0.debugShowSemanticsNodes,
      BF: (x0,x1) => { x0.method = x1 },
      BG: x0 => globalThis.parseFloat(x0),
      BH: x0 => x0.clientWidth,
      BI: x0 => x0.requestFullscreen(),
      BJ: x0 => x0.duration,
      BK: (x0,x1) => { x0.border = x1 },
      BL: (x0,x1) => new OffscreenCanvas(x0,x1),
      C: Function.prototype.call.bind(Number.prototype.toString),
      CB: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      CC: (b, o, l) => new DataView(b, o, l),
      CD: x0 => x0.hash,
      CE: (o, c) => o instanceof c,
      CF: (x0,x1) => { x0.noValidate = x1 },
      CG: (x0,x1) => x0.getComputedStyle(x1),
      CH: x0 => x0.innerWidth,
      CI: x0 => x0.exitFullscreen(),
      CJ: (x0,x1) => ({frameIndex: x0,completeFramesOnly: x1}),
      CK: (x0,x1) => { x0.title = x1 },
      CL: x0 => x0.assetBase,
      D: Function.prototype.call.bind(BigInt.prototype.toString),
      DB: x0 => x0.dotAll,
      DC: Function.prototype.call.bind(DataView.prototype.getUint8),
      DD: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      DE: x0 => x0.vendor,
      DF: x0 => x0.isConnected,
      DG: x0 => x0.documentElement,
      DH: (x0,x1) => x0.removeChild(x1),
      DI: x0 => x0.fullscreenElement,
      DJ: (x0,x1) => x0.decode(x1),
      DK: (x0,x1) => { x0.referrerPolicy = x1 },
      DL: x0 => x0.loader,
      E: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      EB: x0 => x0.unicode,
      EC: Function.prototype.call.bind(DataView.prototype.setUint8),
      ED: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      EE: (x0,x1) => x0.createTextNode(x1),
      EF: x0 => x0.click(),
      EG: x0 => x0.computedStyleMap(),
      EH: x0 => x0.firstChild,
      EI: () => globalThis.document,
      EJ: x0 => x0.image,
      EK: (x0,x1) => { x0.allowFullscreen = x1 },
      EL: () => globalThis._flutter,
      F: () => new Error().stack,
      FB: x0 => x0.ignoreCase,
      FC: Function.prototype.call.bind(DataView.prototype.getFloat64),
      FD: x0 => x0.state,
      FE: (x0,x1) => { x0.nonce = x1 },
      FF: (x0,x1) => x0.getElementsByClassName(x1),
      FG: (x0,x1) => x0.get(x1),
      FH: x0 => x0.viewConstraints,
      FI: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      FJ: x0 => x0.close(),
      FK: (x0,x1) => { x0.allow = x1 },
      G: s => JSON.stringify(s),
      GB: x0 => x0.multiline,
      GC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      GD: (x0,x1,x2) => x0.addEventListener(x1,x2),
      GE: x0 => x0.nonce,
      GF: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      GG: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      GH: x0 => x0.hostElement,
      GI: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      GJ: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      GK: x0 => x0.origin,
      H: Function.prototype.call.bind(Number.prototype.toString),
      HB: (o, p, r) => o.replace(p, () => r),
      HC: (t, s) => t.set(s),
      HD: (x0,x1) => x0.go(x1),
      HE: () => globalThis.window.flutterConfiguration,
      HF: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      HG: x0 => x0.matches,
      HH: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      HI: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      HJ: x0 => new window.ImageDecoder(x0),
      HK: x0 => x0.location,
      I: Function.prototype.call.bind(String.prototype.indexOf),
      IB: s => s.toUpperCase(),
      IC: Function.prototype.call.bind(DataView.prototype.setFloat32),
      ID: (x0,x1) => x0.append(x1),
      IE: (x0,x1) => x0.attachShadow(x1),
      IF: (x0,x1) => x0.contains(x1),
      IG: (x0,x1) => x0.matchMedia(x1),
      IH: x0 => ({runApp: x0}),
      II: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      IJ: x0 => x0.name,
      IK: () => globalThis.window,
      J: (s, p, i) => s.lastIndexOf(p, i),
      JB: Object.is,
      JC: Function.prototype.call.bind(DataView.prototype.getFloat32),
      JD: (x0,x1) => { x0.textContent = x1 },
      JE: x0 => x0.preventDefault(),
      JF: (s) => +s,
      JG: x0 => x0.matches,
      JH: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      JI: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      JJ: x0 => x0.repetitionCount,
      JK: (a, s, e) => a.slice(s, e),
      K: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      KB: (x0,x1) => x0.test(x1),
      KC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      KD: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      KE: (x0,x1) => x0.contains(x1),
      KF: x0 => x0.target,
      KG: x0 => x0.timeStamp,
      KH: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      KI: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      KJ: x0 => x0.frameCount,
      KK: (x0,x1,x2) => x0.insertBefore(x1,x2),
      L: o => o === undefined,
      LB: (a, i, v) => a[i] = v,
      LC: Function.prototype.call.bind(DataView.prototype.getUint32),
      LD: x0 => x0.parentElement,
      LE: (x0,x1) => x0.focus(x1),
      LF: (x0,x1) => x0.dispatchEvent(x1),
      LG: (x0,x1) => x0.hasAttribute(x1),
      LH: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      LI: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      LJ: x0 => x0.selectedTrack,
      LK: x0 => x0.id,
      M: o => String(o),
      MB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      MC: Function.prototype.call.bind(DataView.prototype.setUint32),
      MD: (x0,x1) => x0.querySelectorAll(x1),
      ME: (x0,x1) => x0.closest(x1),
      MF: (x0,x1) => x0.createEvent(x1),
      MG: x0 => x0.type,
      MH: () => typeof dartUseDateNowForTicks !== "undefined",
      MI: (x0,x1,x2,x3,x4,x5,x6) => ({onReady: x0,onStateChange: x1,onPlaybackRateChange: x2,onPlaybackQualityChange: x3,onError: x4,onApiChange: x5,onAutoplayBlocked: x6}),
      MJ: x0 => x0.completed,
      MK: x0 => x0.offsetHeight,
      N: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      NB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      NC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      ND: (x0,x1) => x0.item(x1),
      NE: (x0,x1) => x0.getAttribute(x1),
      NF: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      NG: (x0,x1) => x0.getModifierState(x1),
      NH: () => Date.now(),
      NI: x0 => ({events: x0}),
      NJ: x0 => x0.ready,
      NK: x0 => x0.offsetWidth,
      O: (x0,x1) => x0.didCreateEngineInitializer(x1),
      OB: Function.prototype.call.bind(String.prototype.toLowerCase),
      OC: Function.prototype.call.bind(DataView.prototype.getInt32),
      OD: x0 => x0.length,
      OE: x0 => x0.activeElement,
      OF: x0 => x0.readText(),
      OG: x0 => x0.buttons,
      OH: () => 1000 * performance.now(),
      OI: (x0,x1) => new YT.Player(x0,x1),
      OJ: x0 => x0.tracks,
      OK: x0 => x0.stopPropagation(),
      P: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      PB: (o, p, r) => o.replaceAll(p, () => r),
      PC: Function.prototype.call.bind(DataView.prototype.setInt32),
      PD: x0 => x0.userAgent,
      PE: (x0,x1) => x0.add(x1),
      PF: x0 => x0.clipboard,
      PG: x0 => x0.ctrlKey,
      PH: x0 => new Uint8Array(x0),
      PI: (o, t) => typeof o === t,
      PJ: () => globalThis.window.ImageDecoder,
      PK: x0 => x0.disabled,
      Q: (wasmFunction,f) => finalizeWrapper(f, function() { return wasmFunction(f,arguments.length) }),
      QB: x0 => x0.length,
      QC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      QD: x0 => x0.maxTouchPoints,
      QE: x0 => x0.classList,
      QF: (x0,x1) => x0.writeText(x1),
      QG: x0 => x0.getBoundingClientRect(),
      QH: (x0,x1,x2) => x0.slice(x1,x2),
      QI: x0 => x0.data,
      QJ: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      QK: (x0,x1) => { x0.min = x1 },
      R: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      RB: x0 => x0.flags,
      RC: o => o instanceof Uint16Array,
      RD: x0 => x0.platform,
      RE: x0 => x0.data,
      RF: x0 => x0.unlock(),
      RG: x0 => x0.y,
      RH: (x0,x1) => x0.decode(x1),
      RI: x0 => x0.getVideoData(),
      RJ: x0 => x0.status,
      RK: (x0,x1) => { x0.max = x1 },
      S: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      SB: s => s.trim(),
      SC: Function.prototype.call.bind(DataView.prototype.getUint16),
      SD: x0 => x0.navigator,
      SE: x0 => x0.scrollTop,
      SF: (x0,x1) => x0.lock(x1),
      SG: x0 => x0.x,
      SH: (x0,x1) => x0.adoptText(x1),
      SI: x0 => x0.getPlaybackRate(),
      SJ: x0 => x0.response,
      SK: (x0,x1) => { x0.disabled = x1 },
      T: x0 => new Promise(x0),
      TB: (a, s) => a.join(s),
      TC: Function.prototype.call.bind(DataView.prototype.setUint16),
      TD: s => new Date(s * 1000).getTimezoneOffset() * 60,
      TE: (handle) => clearTimeout(handle),
      TF: x0 => x0.orientation,
      TG: x0 => x0.top,
      TH: x0 => x0.first(),
      TI: x0 => x0.author,
      TJ: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
      TK: (x0,x1) => { x0.scrollLeft = x1 },
      U: (x0,x1,x2) => x0.call(x1,x2),
      UB: x0 => x0.random(),
      UC: o => o instanceof Int16Array,
      UD: Date.now,
      UE: (x0,x1) => x0.removeAttribute(x1),
      UF: (x0,x1) => x0.querySelector(x1),
      UG: x0 => x0.left,
      UH: x0 => x0.next(),
      UI: x0 => x0.title,
      UJ: (x0,x1) => { x0.responseType = x1 },
      UK: (x0,x1) => { x0.spellcheck = x1 },
      V: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      VB: () => globalThis.Math,
      VC: Function.prototype.call.bind(DataView.prototype.getInt16),
      VD: (x0,x1,x2) => x0.setAttribute(x1,x2),
      VE: (x0,x1) => { x0.value = x1 },
      VF: (x0,x1) => { x0.content = x1 },
      VG: x0 => x0.offsetTop,
      VH: x0 => x0.current(),
      VI: x0 => x0.video_id,
      VJ: () => new XMLHttpRequest(),
      VK: (x0,x1) => { x0.disabled = x1 },
      W: x0 => new Array(x0),
      WB: (x0,x1) => x0.error(x1),
      WC: Function.prototype.call.bind(DataView.prototype.setInt16),
      WD: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      WE: (x0,x1) => { x0.value = x1 },
      WF: x0 => x0.head,
      WG: x0 => x0.scrollLeft,
      WH: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      WI: (x0,x1) => { x0.src = x1 },
      WJ: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      WK: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9) => x0.drawImage(x1,x2,x3,x4,x5,x6,x7,x8,x9),
      X: o => [o],
      XB: () => globalThis.console,
      XC: o => o instanceof Uint8ClampedArray,
      XD: x0 => x0.style,
      XE: x0 => x0.value,
      XF: (x0,x1) => { x0.name = x1 },
      XG: x0 => x0.offsetLeft,
      XH: x0 => x0.v8BreakIterator,
      XI: (a, i) => a.splice(i, 1),
      XJ: x0 => new WeakRef(x0),
      XK: (x0,x1) => x0.getContext(x1),
      Y: (o0, o1) => [o0, o1],
      YB: s => s.trimRight(),
      YC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      YD: (x0,x1) => x0.createElement(x1),
      YE: x0 => x0.selectionDirection,
      YF: (x0,x1) => { x0.title = x1 },
      YG: x0 => x0.offsetParent,
      YH: () => globalThis.Intl,
      YI: a => a.pop(),
      YJ: x0 => x0.deref(),
      YK: (x0,x1) => { x0.height = x1 },
      Z: (o0, o1, o2) => [o0, o1, o2],
      ZB: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      ZC: Function.prototype.call.bind(DataView.prototype.setInt8),
      ZD: x0 => x0.body,
      ZE: x0 => x0.selectionStart,
      ZF: () => globalThis.document,
      ZG: x0 => x0.offsetY,
      ZH: (x0,x1) => x0.segment(x1),
      ZI: x0 => x0.naturalHeight,
      ZJ: () => globalThis.WeakRef,
      ZK: (x0,x1) => { x0.width = x1 },
      a: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      aB: () => ({}),
      aC: Function.prototype.call.bind(DataView.prototype.getInt8),
      aD: x0 => x0.remove(),
      aE: x0 => x0.selectionEnd,
      aF: (x0,x1) => x0.vibrate(x1),
      aG: x0 => x0.offsetX,
      aH: x0 => x0.index,
      aI: x0 => x0.naturalWidth,
      aJ: (x0,x1) => { x0.backgroundColor = x1 },
      aK: (x0,x1) => x0.transferFromImageBitmap(x1),
      b: (x0,x1,x2) => { x0[x1] = x2 },
      bB: (o, p, v) => o[p] = v,
      bC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      bD: (x0,x1) => x0.getPropertyValue(x1),
      bE: x0 => x0.value,
      bF: (o, p) => p in o,
      bG: x0 => x0.deltaMode,
      bH: x0 => x0.next(),
      bI: (x0,x1) => x0.createElement(x1),
      bJ: x0 => x0.style,
      bK: x0 => x0.rasterEndMilliseconds,
      c: o => o,
      cB: () => [],
      cC: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      cD: (x0,x1) => x0.warn(x1),
      cE: x0 => x0.selectionDirection,
      cF: x0 => x0.arrayBuffer(),
      cG: x0 => x0.deltaY,
      cH: x0 => x0.value,
      cI: (x0,x1) => { x0.pointerEvents = x1 },
      cJ: x0 => x0.pop(),
      cK: x0 => x0.rasterStartMilliseconds,
      d: (o, p) => o[p],
      dB: (a, i) => a.push(i),
      dC: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      dD: x0 => x0.console,
      dE: x0 => x0.selectionStart,
      dF: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof ArrayBuffer) return 1;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 2;
        }
        return 3;
      },
      dG: x0 => x0.deltaX,
      dH: x0 => x0.done,
      dI: (x0,x1) => { x0.height = x1 },
      dJ: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      dK: x0 => x0.imageBitmaps,
      e: () => globalThis,
      eB: b => !!b,
      eC: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      eD: (x0,x1) => { x0.id = x1 },
      eE: x0 => x0.selectionEnd,
      eF: x0 => x0.status,
      eG: x0 => x0.wheelDeltaY,
      eH: (o, m, a) => o[m].apply(o, a),
      eI: (x0,x1) => { x0.width = x1 },
      eJ: x0 => x0.destroy(),
      eK: x0 => x0.canvasKitMaximumSurfaces,
      f: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      fB: x0 => new Int8Array(x0),
      fC: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      fD: (x0,x1) => x0.requestAnimationFrame(x1),
      fE: (x0,x1) => { x0.name = x1 },
      fF: (x0,x1) => x0.fetch(x1),
      fG: x0 => x0.wheelDeltaX,
      fH: x0 => x0.iterator,
      fI: x0 => x0.style,
      fJ: x0 => x0.remove(),
      fK: x0 => x0.nextSibling,
      g: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      gB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      gC: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      gD: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      gE: (x0,x1) => { x0.placeholder = x1 },
      gF: x0 => x0.content,
      gG: x0 => x0.bottom,
      gH: () => globalThis.Symbol,
      gI: (x0,x1) => { x0.src = x1 },
      gJ: (x0,x1) => x0.append(x1),
      gK: (x0,x1) => x0.debug(x1),
      h: (x0,x1) => ({addView: x0,removeView: x1}),
      hB: x0 => new Uint8Array(x0),
      hC: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      hD: x0 => x0.now(),
      hE: (x0,x1) => { x0.autocomplete = x1 },
      hF: x0 => x0.document,
      hG: x0 => x0.right,
      hH: (x0,x1) => new Intl.Segmenter(x0,x1),
      hI: () => globalThis.document,
      hJ: (wasmFunction,f) => finalizeWrapper(f, function() { return wasmFunction(f,arguments.length) }),
      hK: x0 => x0.hostElement,
      i: (string, token) => string.split(token),
      iB: x0 => new Uint8ClampedArray(x0),
      iC: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      iD: x0 => x0.performance,
      iE: (x0,x1) => { x0.type = x1 },
      iF: x0 => x0.language,
      iG: x0 => x0.clientY,
      iH: x0 => x0.Segmenter,
      iI: x0 => x0.src,
      iJ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      iK: x0 => x0.location,
      j: o => o instanceof Array,
      jB: x0 => new Int16Array(x0),
      jC: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      jD: (x0,x1) => x0.unregister(x1),
      jE: (x0,x1) => { x0.name = x1 },
      jF: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      jG: x0 => x0.clientX,
      jH: x0 => x0.buffer,
      jI: x0 => x0.decode(),
      jJ: (x0,x1) => { x0.onerror = x1 },
      jK: (x0,x1) => x0.getModifierState(x1),
      k: (a, i) => a[i],
      kB: x0 => new Uint16Array(x0),
      kC: x0 => x0.history,
      kD: () => globalThis.window.FinalizationRegistry,
      kE: (x0,x1) => { x0.placeholder = x1 },
      kF: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      kG: x0 => x0.changedTouches,
      kH: x0 => x0.wasmMemory,
      kI: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      kJ: x0 => x0.src,
      kK: x0 => x0.metaKey,
      l: a => a.length,
      lB: x0 => new Int32Array(x0),
      lC: () => globalThis.window,
      lD: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      lE: (x0,x1) => { x0.scrollTop = x1 },
      lF: (x0,x1) => x0.querySelector(x1),
      lG: x0 => x0.key,
      lH: () => globalThis.window._flutter_skwasmInstance,
      lI: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      lJ: (x0,x1) => { x0.async = x1 },
      lK: x0 => x0.altKey,
      m: (string, times) => string.repeat(times),
      mB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      mC: x0 => x0.search,
      mD: x0 => new window.FinalizationRegistry(x0),
      mE: x0 => x0.tagName,
      mF: (x0,x1) => x0.querySelectorAll(x1),
      mG: x0 => x0.identifier,
      mH: () => new TextDecoder(),
      mI: (x0,x1,x2) => x0.addEventListener(x1,x2),
      mJ: (x0,x1) => { x0.src = x1 },
      mK: x0 => x0.ctrlKey,
      n: (decoder, codeUnits) => decoder.decode(codeUnits),
      nB: x0 => new Uint32Array(x0),
      nC: o => {
        if (o === null || o === undefined) return 0;
        if (typeof(o) === 'string') return 1;
        return 2;
      },
      nD: x0 => x0.scale,
      nE: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      nF: x0 => x0.tabIndex,
      nG: x0 => x0.touches,
      nH: (map, o, v) => map.set(o, v),
      nI: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      nJ: (x0,x1) => x0.createElement(x1),
      nK: x0 => x0.isComposing,
      o: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      oB: x0 => new Float32Array(x0),
      oC: x0 => x0.location,
      oD: x0 => x0.visualViewport,
      oE: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      oF: x0 => x0.parentNode,
      oG: x0 => x0.pressure,
      oH: (map, o) => map.get(o),
      oI: x0 => x0.send(),
      oJ: (o, p, v) => o[p] = v,
      oK: x0 => x0.code,
      p: () => new TextDecoder("utf-8", {fatal: true}),
      pB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      pC: x0 => x0.pathname,
      pD: x0 => x0.devicePixelRatio,
      pE: x0 => x0.visibilityState,
      pF: x0 => x0.clientY,
      pG: x0 => x0.tiltY,
      pH: () => new WeakMap(),
      pI: x0 => x0.close(),
      pJ: x0 => x0.call(),
      pK: x0 => x0.repeat,
      q: () => new TextDecoder("utf-8", {fatal: false}),
      qB: x0 => new Float64Array(x0),
      qC: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      qD: (d, digits) => d.toFixed(digits),
      qE: x0 => x0.hasFocus(),
      qF: x0 => x0.clientX,
      qG: x0 => x0.tiltX,
      qH: x0 => x0.debugSkipFontRetryDelay,
      qI: x0 => x0.height,
      qJ: (x0,x1) => { x0.href = x1 },
      qK: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      r: s => s.trimLeft(),
      rB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      rC: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      rD: x0 => x0.maxHeight,
      rE: x0 => x0.relatedTarget,
      rF: x0 => x0.shiftKey,
      rG: x0 => x0.pointerType,
      rH: (x0,x1,x2) => x0.set(x1,x2),
      rI: x0 => x0.width,
      rJ: (x0,x1) => { x0.rel = x1 },
      rK: x0 => x0.extraAssets,
      s: (l, r) => l === r,
      sB: x0 => new ArrayBuffer(x0),
      sC: o => Object.keys(o),
      sD: x0 => x0.maxWidth,
      sE: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      sF: x0 => x0.disconnect(),
      sG: x0 => x0.pointerId,
      sH: x0 => x0.fontFallbackBaseUrl,
      sI: (x0,x1,x2,x3,x4,x5) => x0.createImageBitmap(x1,x2,x3,x4,x5),
      sJ: x0 => x0.head,
      sK: x0 => x0.fontManifest,
      t: (x0,x1) => x0[x1],
      tB: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      tC: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      tD: x0 => x0.minHeight,
      tE: x0 => x0.keyCode,
      tF: x0 => new Intl.Locale(x0),
      tG: x0 => x0.getCoalescedEvents(),
      tH: (handle) => clearInterval(handle),
      tI: (x0,x1) => x0.createImageBitmap(x1),
      tJ: x0 => x0.Player,
      tK: x0 => x0.assetManifest,
      u: o => o,
      uB: (x0,x1,x2) => new DataView(x0,x1,x2),
      uC: f => f.dartFunction,
      uD: x0 => x0.minWidth,
      uE: (x0,x1) => x0.scrollIntoView(x1),
      uF: x0 => x0.region,
      uG: x0 => x0.blur(),
      uH: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      uI: x0 => new Blob(x0),
      uJ: () => globalThis.YT,
      uK: x0 => x0.buildConfig,
      v: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      vB: (o, p) => o[p],
      vC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      vD: x0 => x0.height,
      vE: x0 => x0.multiViewEnabled,
      vF: x0 => x0.script,
      vG: x0 => x0.button,
      vH: () => Date.now(),
      vI: x0 => x0.close(),
      vJ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      vK: x0 => x0.length,
      w: x0 => x0.index,
      wB: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      wC: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      wD: x0 => x0.width,
      wE: x0 => x0.parent,
      wF: x0 => x0.language,
      wG: (x0,x1) => x0.prepend(x1),
      wH: x0 => x0.getCurrentTime(),
      wI: x0 => x0.naturalHeight,
      wJ: (x0,x1,x2) => x0.addEventListener(x1,x2),
      wK: x0 => x0.getReader(),
      x: (x0,x1) => x0.exec(x1),
      xB: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      xC: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      xD: x0 => x0.screen,
      xE: (x0,x1) => x0.replaceWith(x1),
      xF: x0 => x0.languages,
      xG: x0 => x0.innerHeight,
      xH: x0 => x0.getVideoLoadedFraction(),
      xI: x0 => x0.naturalWidth,
      xJ: (x0,x1) => { x0.pointerEvents = x1 },
      xK: x0 => x0.value,
      y: (x0,x1) => { x0.lastIndex = x1 },
      yB: Function.prototype.call.bind(DataView.prototype.setFloat64),
      yC: (o, i) => o[i],
      yD: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      yE: (x0,x1) => { x0.className = x1 },
      yF: (x0,x1) => x0.observe(x1),
      yG: x0 => x0.height,
      yH: x0 => x0.getDuration(),
      yI: (x0,x1) => { x0.src = x1 },
      yJ: (x0,x1) => { x0.display = x1 },
      yK: x0 => x0.done,
      z: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      zB: o => o.byteOffset,
      zC: o => o.length,
      zD: (x0,x1) => x0.removeProperty(x1),
      zE: (x0,x1) => { x0.tabIndex = x1 },
      zF: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      zG: x0 => x0.width,
      zH: x0 => x0.getVolume(),
      zI: x0 => x0.displayHeight,
      zJ: (x0,x1) => { x0.height = x1 },
      zK: x0 => x0.read(),

    };

    const baseImports = {
      _: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      WebAssembly: {
        JSTag: WebAssembly.JSTag,
      },
      "": new Proxy({}, { get(_, prop) { return prop; } }),

    };

    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}

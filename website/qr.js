/**
 * Local, zero-dependency QR Code SVG generator (ISO/IEC 18004, Byte mode, ECC-M)
 * and Regiday download CTA progressive enhancer.
 *
 * Works completely offline with no third-party QR image APIs.
 */
(function () {
  'use strict';

  // Minimal Reed-Solomon GF(256) with primitive polynomial 0x11D
  const EXP = new Uint8Array(512);
  const LOG = new Uint8Array(256);
  (function initGF() {
    let x = 1;
    for (let i = 0; i < 255; i++) {
      EXP[i] = x;
      LOG[x] = i;
      x <<= 1;
      if (x & 0x100) x ^= 0x11d;
    }
    for (let i = 255; i < 512; i++) EXP[i] = EXP[i - 255];
  })();

  function gfMul(a, b) {
    if (a === 0 || b === 0) return 0;
    return EXP[LOG[a] + LOG[b]];
  }

  function rsGenerator(degree) {
    let poly = [1];
    for (let i = 0; i < degree; i++) {
      const next = new Array(poly.length + 1).fill(0);
      const factor = EXP[i];
      for (let j = 0; j < poly.length; j++) {
        next[j] ^= poly[j];
        next[j + 1] ^= gfMul(poly[j], factor);
      }
      poly = next;
    }
    return poly;
  }

  function rsEncode(data, ecCount) {
    const gen = rsGenerator(ecCount);
    const out = new Uint8Array(data.length + ecCount);
    out.set(data);
    for (let i = 0; i < data.length; i++) {
      const coef = out[i];
      if (coef !== 0) {
        for (let j = 0; j < gen.length; j++) {
          out[i + j] ^= gfMul(gen[j], coef);
        }
      }
    }
    return out.slice(data.length);
  }

  // Supported versions (ECC Level M): [version, totalCodewords, ecPerBlock, blocks]
  // Version 2..6 covers URLs up to 106 UTF-8 bytes cleanly (Play Store URLs are ~60-85 bytes).
  const VERSIONS_M = [
    { v: 2, size: 25, total: 44, ecPerBlock: 16, blocks: 1, align: [6, 18] },
    { v: 3, size: 29, total: 70, ecPerBlock: 26, blocks: 1, align: [6, 22] },
    { v: 4, size: 33, total: 100, ecPerBlock: 18, blocks: 2, align: [6, 26] },
    { v: 5, size: 37, total: 134, ecPerBlock: 24, blocks: 2, align: [6, 30] },
    { v: 6, size: 41, total: 172, ecPerBlock: 16, blocks: 4, align: [6, 34] },
  ];

  function encodeQR(text) {
    const bytes = new TextEncoder().encode(text);
    let spec = null;
    for (const cand of VERSIONS_M) {
      const dataCapacity = cand.total - cand.ecPerBlock * cand.blocks;
      if (bytes.length + 2 <= dataCapacity) {
        spec = cand;
        break;
      }
    }
    if (!spec) {
      throw new Error('URL exceeds local QR capacity.');
    }

    const dataCapacity = spec.total - spec.ecPerBlock * spec.blocks;
    const bits = [];
    function pushBits(val, len) {
      for (let i = len - 1; i >= 0; i--) bits.push((val >>> i) & 1);
    }

    // Mode: Byte (0100), Length: 8 bits (valid for versions 1-9)
    pushBits(0b0100, 4);
    pushBits(bytes.length, 8);
    for (const b of bytes) pushBits(b, 8);

    const maxBits = dataCapacity * 8;
    pushBits(0, Math.min(4, maxBits - bits.length));
    while (bits.length % 8 !== 0) bits.push(0);

    const dataBytes = [];
    for (let i = 0; i < bits.length; i += 8) {
      let b = 0;
      for (let j = 0; j < 8; j++) b = (b << 1) | bits[i + j];
      dataBytes.push(b);
    }
    const pad = [0xec, 0x11];
    let p = 0;
    while (dataBytes.length < dataCapacity) {
      dataBytes.push(pad[p++ % 2]);
    }

    // Split into blocks & interleave
    const blockSize = Math.floor(dataCapacity / spec.blocks);
    const dataBlocks = [];
    const ecBlocks = [];
    let offset = 0;
    for (let b = 0; b < spec.blocks; b++) {
      const slice = new Uint8Array(dataBytes.slice(offset, offset + blockSize));
      offset += blockSize;
      dataBlocks.push(slice);
      ecBlocks.push(rsEncode(slice, spec.ecPerBlock));
    }

    const codewords = [];
    for (let i = 0; i < blockSize; i++) {
      for (let b = 0; b < spec.blocks; b++) codewords.push(dataBlocks[b][i]);
    }
    for (let i = 0; i < spec.ecPerBlock; i++) {
      for (let b = 0; b < spec.blocks; b++) codewords.push(ecBlocks[b][i]);
    }

    const n = spec.size;
    const modules = Array.from({ length: n }, () => new Uint8Array(n));
    const isFunc = Array.from({ length: n }, () => new Uint8Array(n));

    function setMod(r, c, dark, func) {
      if (r < 0 || c < 0 || r >= n || c >= n) return;
      modules[r][c] = dark ? 1 : 0;
      if (func) isFunc[r][c] = 1;
    }

    function drawFinder(r0, c0) {
      for (let r = -1; r <= 7; r++) {
        for (let c = -1; c <= 7; c++) {
          const rr = r0 + r;
          const cc = c0 + c;
          if (rr < 0 || cc < 0 || rr >= n || cc >= n) continue;
          const inOuter = r >= 0 && r <= 6 && c >= 0 && c <= 6;
          const dark =
            inOuter &&
            (r === 0 ||
              r === 6 ||
              c === 0 ||
              c === 6 ||
              (r >= 2 && r <= 4 && c >= 2 && c <= 4));
          setMod(rr, cc, dark, true);
        }
      }
    }

    drawFinder(0, 0);
    drawFinder(0, n - 7);
    drawFinder(n - 7, 0);

    // Alignment pattern
    const aPos = spec.align[1];
    for (let r = -2; r <= 2; r++) {
      for (let c = -2; c <= 2; c++) {
        const dark =
          Math.max(Math.abs(r), Math.abs(c)) === 2 || (r === 0 && c === 0);
        setMod(aPos + r, aPos + c, dark, true);
      }
    }

    // Timing patterns
    for (let i = 8; i < n - 8; i++) {
      setMod(6, i, i % 2 === 0, true);
      setMod(i, 6, i % 2 === 0, true);
    }

    // Dark module & reserve format info
    setMod(n - 8, 8, true, true);
    for (let i = 0; i <= 8; i++) {
      if (i !== 6) {
        isFunc[8][i] = 1;
        isFunc[i][8] = 1;
      }
    }
    for (let i = n - 8; i < n; i++) {
      isFunc[8][i] = 1;
      isFunc[i][8] = 1;
    }

    // Place data bits (mask 0: (r + c) % 2 === 0)
    const bitStream = [];
    for (const cw of codewords) {
      for (let i = 7; i >= 0; i--) bitStream.push((cw >>> i) & 1);
    }

    let bitIdx = 0;
    let upward = true;
    for (let col = n - 1; col > 0; col -= 2) {
      if (col === 6) col--;
      for (let i = 0; i < n; i++) {
        const r = upward ? n - 1 - i : i;
        for (let dc = 0; dc < 2; dc++) {
          const c = col - dc;
          if (isFunc[r][c]) continue;
          const bit = bitIdx < bitStream.length ? bitStream[bitIdx++] : 0;
          const masked = bit ^ ((r + c) % 2 === 0 ? 1 : 0);
          modules[r][c] = masked;
        }
      }
      upward = !upward;
    }

    // Format bits for ECC-M (00) + Mask 0 (000) -> 00000 -> BCH + mask 0x5412 = 0x5412
    const fmt = 0x5412;
    for (let i = 0; i < 6; i++) {
      const bit = (fmt >>> (14 - i)) & 1;
      modules[8][i] = bit;
      modules[n - 1 - i][8] = bit;
    }
    modules[8][7] = (fmt >>> 8) & 1;
    modules[8][8] = (fmt >>> 7) & 1;
    modules[7][8] = (fmt >>> 6) & 1;
    for (let i = 0; i < 6; i++) {
      const bit = (fmt >>> (5 - i)) & 1;
      modules[5 - i][8] = bit;
      modules[8][n - 6 + i] = bit;
    }
    modules[8][n - 8] = (fmt >>> 7) & 1;
    modules[8][n - 7] = (fmt >>> 6) & 1;

    return modules;
  }

  function renderQrSvg(url) {
    const matrix = encodeQR(url);
    const n = matrix.length;
    const quiet = 4;
    const total = n + quiet * 2;
    let path = '';
    for (let r = 0; r < n; r++) {
      for (let c = 0; c < n; c++) {
        if (matrix[r][c]) {
          path += `M${c + quiet},${r + quiet}h1v1h-1z`;
        }
      }
    }
    return (
      `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${total} ${total}" ` +
      `role="img" aria-label="QR code to download Regiday on Google Play" shape-rendering="crispEdges">` +
      `<rect width="${total}" height="${total}" fill="#FFFFFF"/>` +
      `<path d="${path}" fill="#111936"/>` +
      `</svg>`
    );
  }

  function applyConfig() {
    const cfg = window.REGIDAY_CONFIG || {};
    const url = typeof cfg.playStoreUrl === 'string' ? cfg.playStoreUrl.trim() : '';
    const isLive = /^https:\/\/play\.google\.com\/store\/apps\/details\?id=/.test(url) ||
      /^https:\/\//.test(url);

    const downloadLinks = document.querySelectorAll('[data-regiday-download]');
    const qrTarget = document.getElementById('regiday-qr-box');
    const qrTitle = document.getElementById('regiday-qr-title');
    const qrSubtitle = document.getElementById('regiday-qr-subtitle');
    const statusNote = document.getElementById('regiday-download-note');

    if (isLive) {
      downloadLinks.forEach((el) => {
        el.setAttribute('href', url);
        el.setAttribute('target', '_blank');
        el.setAttribute('rel', 'noopener noreferrer');
        el.removeAttribute('aria-disabled');
        const label = el.getAttribute('data-live-label') || 'Get Regiday on Google Play';
        el.textContent = label;
      });
      if (qrTarget) {
        qrTarget.innerHTML = renderQrSvg(url);
      }
      if (qrTitle) qrTitle.textContent = 'Scan to download Regiday';
      if (qrSubtitle) qrSubtitle.textContent = 'Opens the verified Google Play Store listing on your Android phone.';
      if (statusNote) statusNote.textContent = 'Available for Android via Google Play.';
    } else {
      downloadLinks.forEach((el) => {
        el.setAttribute('href', '#download');
        el.setAttribute('aria-disabled', 'true');
        el.textContent = el.getAttribute('data-soon-label') || 'Google Play — Coming soon';
      });
      if (qrTarget) {
        qrTarget.innerHTML = '<div class="qr-placeholder">Coming<br>soon</div>';
      }
      if (qrTitle) qrTitle.textContent = 'Scan to download Regiday';
      if (qrSubtitle) {
        qrSubtitle.textContent = 'The Google Play Store link and QR code will appear here as soon as the public listing goes live.';
      }
      if (statusNote) {
        statusNote.textContent = 'Android public listing coming soon. No account or cloud sign-up required.';
      }
    }
  }

  // Expose encoder for local QA verification
  window.RegidayQR = { encodeQR: encodeQR, renderQrSvg: renderQrSvg, applyConfig: applyConfig };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', applyConfig);
  } else {
    applyConfig();
  }
})();

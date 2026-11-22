// X05 ANIME brand asset renderer.
//
// Source of truth for every logo raster in the repo. The geometry is authored
// as SVG so the same mark can be rasterised at 20 px (iOS Settings) and
// 4640 px (tvOS Top Shelf) without a resampling pass.
//
// Usage: node tool/gen_brand_assets.mjs
// Requires Chrome (headless) on Windows at the path below.

import { spawn, spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const CHROME = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const TMP = path.join(os.tmpdir(), 'x05-brand-render');
const PROFILE = path.join(TMP, 'chrome-profile');
fs.mkdirSync(TMP, { recursive: true });
fs.mkdirSync(PROFILE, { recursive: true });

const P = {
  signature: {
    bg: ['#0B1226', '#060A15', '#03050B'],
    glow: '#1677FF',
    glowOpacity: 0.42,
    barA: ['#FFFFFF', '#F2F8FF', '#AFCDFF'],
    barB: ['#63B0FF', '#1677FF', '#083BB4'],
    play: ['#FFFFFF', '#A9CEFF'],
    disc: '#05080F',
    discStroke: '#8FC4FF',
    ring: true,
    spark: true,
  },
  ice: {
    bg: ['#0C1A2E', '#071221', '#030912'],
    glow: '#8FC4FF',
    glowOpacity: 0.3,
    barA: ['#FFFFFF', '#F4FAFF', '#D8EAFF'],
    barB: ['#C9E4FF', '#7FB7FF', '#3F79D1'],
    play: ['#FFFFFF', '#D8EAFF'],
    disc: '#06101E',
    discStroke: '#A6CFFF',
    ring: false,
    spark: false,
  },
  midnight: {
    bg: ['#080D18', '#04070F', '#010308'],
    glow: '#0B5BD6',
    glowOpacity: 0.32,
    barA: ['#E8F1FF', '#FFFFFF', '#BFD8FF'],
    barB: ['#3A78FF', '#0B3FA8', '#05206B'],
    play: ['#FFFFFF', '#BFD8FF'],
    disc: '#03060C',
    discStroke: '#5E97E8',
    ring: false,
    spark: false,
  },
};

const BARS = (fillA = 'url(#barA)', fillB = 'url(#barB)') => `
  <path d="M232 186 L404 186 L792 838 L620 838 Z" fill="${fillA}"/>
  <path d="M620 186 L792 186 L404 838 L232 838 Z" fill="${fillB}"/>`;

const DISC = (p) => `
  <circle cx="512" cy="512" r="176" fill="${p.disc}"/>
  <circle cx="512" cy="512" r="176" fill="none" stroke="${p.discStroke}"
          stroke-opacity=".38" stroke-width="3"/>
  <path d="M466 430 L466 594 L630 512 Z" fill="url(#play)"/>`;

const SPARK = `
  <g transform="translate(816 222)">
    <circle r="54" fill="#1677FF" opacity=".14"/>
    <path d="M0 -34 L8 -8 L34 0 L8 8 L0 34 L-8 8 L-34 0 L-8 -8 Z" fill="#FFFFFF"/>
  </g>`;

const VIGNETTE = `
  <radialGradient id="vignette" cx=".5" cy=".45" r=".72">
    <stop offset=".62" stop-color="#000" stop-opacity="0"/>
    <stop offset="1" stop-color="#000" stop-opacity=".42"/>
  </radialGradient>`;

const SPEED_LINES = `
  <g opacity=".10" stroke="#7CBBFF" stroke-width="2">
    <path d="M-60 900 L1100 60"/>
    <path d="M-60 990 L1100 150"/>
    <path d="M-60 1080 L1100 240"/>
  </g>`;

function defs(p, { shadow = false } = {}) {
  return `
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${p.bg[0]}"/>
      <stop offset=".5" stop-color="${p.bg[1]}"/>
      <stop offset="1" stop-color="${p.bg[2]}"/>
    </linearGradient>
    <radialGradient id="glow" cx=".5" cy=".47" r=".58">
      <stop offset="0" stop-color="${p.glow}" stop-opacity="${p.glowOpacity}"/>
      <stop offset=".42" stop-color="${p.glow}" stop-opacity="${p.glowOpacity * 0.32}"/>
      <stop offset="1" stop-color="${p.glow}" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="barA" x1=".1" y1="0" x2=".9" y2="1">
      <stop offset="0" stop-color="${p.barA[0]}"/>
      <stop offset=".52" stop-color="${p.barA[1]}"/>
      <stop offset="1" stop-color="${p.barA[2]}"/>
    </linearGradient>
    <linearGradient id="barB" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${p.barB[0]}"/>
      <stop offset=".48" stop-color="${p.barB[1]}"/>
      <stop offset="1" stop-color="${p.barB[2]}"/>
    </linearGradient>
    <linearGradient id="play" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${p.play[0]}"/>
      <stop offset="1" stop-color="${p.play[1]}"/>
    </linearGradient>
    <linearGradient id="ring" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#CDE6FF" stop-opacity=".95"/>
      <stop offset=".45" stop-color="#4C9CFF" stop-opacity=".42"/>
      <stop offset="1" stop-color="#1677FF" stop-opacity="0"/>
    </linearGradient>
    ${VIGNETTE}
    ${
      shadow
        ? `<filter id="softGlow" x="-40%" y="-40%" width="180%" height="180%">
             <feGaussianBlur stdDeviation="24" result="b"/>
             <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
           </filter>
           <filter id="barShadow" x="-30%" y="-30%" width="160%" height="160%">
             <feDropShadow dx="0" dy="18" stdDeviation="26" flood-color="#000000" flood-opacity=".55"/>
           </filter>`
        : ''
    }
  </defs>`;
}

function fullIcon(p, size) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 1024 1024">
  ${defs(p, { shadow: true })}
  <rect width="1024" height="1024" fill="url(#bg)"/>
  <rect width="1024" height="1024" fill="url(#glow)"/>
  ${SPEED_LINES}
  ${
    p.ring
      ? `<g transform="rotate(-30 512 512)">
           <circle cx="512" cy="512" r="388" fill="none" stroke="url(#ring)" stroke-width="3.5"
                   stroke-linecap="round" stroke-dasharray="700 150 90 440" opacity=".82"/>
           <circle cx="512" cy="512" r="334" fill="none" stroke="#FFFFFF" stroke-opacity=".09" stroke-width="1.5"/>
         </g>`
      : ''
  }
  <g filter="url(#barShadow)">
    <g filter="url(#softGlow)">${BARS()}</g>
    ${DISC(p)}
  </g>
  ${p.spark ? SPARK : ''}
  <rect width="1024" height="1024" fill="url(#vignette)"/>
</svg>`;
}

// Small sizes drop the orbit, spark, bloom and shadow: at 20–96 px those turn
// into mud. The X itself is scaled up to keep the mark legible.
function compactIcon(p, size) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 1024 1024">
  ${defs(p)}
  <rect width="1024" height="1024" fill="url(#bg)"/>
  <rect width="1024" height="1024" fill="url(#glow)"/>
  <g transform="translate(512 512) scale(1.06) translate(-512 -512)">
    ${BARS()}
    ${DISC(p)}
  </g>
  <rect width="1024" height="1024" fill="url(#vignette)"/>
</svg>`;
}

// Adaptive foreground: 108 dp canvas, X held inside the 66 dp circular safe
// zone the launcher guarantees.
function adaptiveForeground(p, size, { mono = false } = {}) {
  const scale = 0.0985;
  if (mono) {
    // One-colour silhouette: the X with the play triangle knocked out of the
    // solid crossing. No disc, because a tinted circle would swallow the
    // triangle at launcher sizes.
    return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 108 108">
  <defs>
    <mask id="cut">
      <rect width="108" height="108" fill="#000"/>
      <g transform="translate(54 54) scale(${scale}) translate(-512 -512)">
        <g fill="#fff">${BARS('#fff', '#fff')}</g>
        <path d="M466 430 L466 594 L630 512 Z" fill="#000"/>
      </g>
    </mask>
  </defs>
  <rect width="108" height="108" fill="#fff" mask="url(#cut)"/>
</svg>`;
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 108 108">
  <defs>
    <radialGradient id="halo" cx=".5" cy=".5" r=".5">
      <stop offset="0" stop-color="${p.glow}" stop-opacity=".34"/>
      <stop offset=".62" stop-color="${p.glow}" stop-opacity=".10"/>
      <stop offset="1" stop-color="${p.glow}" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="barA" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${p.barA[0]}"/>
      <stop offset=".52" stop-color="${p.barA[1]}"/>
      <stop offset="1" stop-color="${p.barA[2]}"/>
    </linearGradient>
    <linearGradient id="barB" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${p.barB[0]}"/>
      <stop offset=".48" stop-color="${p.barB[1]}"/>
      <stop offset="1" stop-color="${p.barB[2]}"/>
    </linearGradient>
    <linearGradient id="play" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${p.play[0]}"/>
      <stop offset="1" stop-color="${p.play[1]}"/>
    </linearGradient>
  </defs>
  <circle cx="54" cy="54" r="54" fill="url(#halo)"/>
  <g transform="translate(54 54) scale(${scale}) translate(-512 -512)">
    ${BARS()}
    ${DISC(p)}
  </g>
</svg>`;
}

function markSvg(p, size) {
  // Transparent lockup for in-app use. No drop shadow or bloom: on a dark
  // screen a blurred dark halo reads as grey mud around the mark, and the
  // Flutter widgets already add their own accent glow.
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 1024 1024">
  ${defs(p)}
  ${BARS()}
  ${DISC(p)}
</svg>`;
}

function wordmarkSvg(width = 1440, height = 420) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 1440 420">
  <defs>
    <linearGradient id="wgrad" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset=".55" stop-color="#DCEBFF"/>
      <stop offset="1" stop-color="#7DB6FF"/>
    </linearGradient>
    <linearGradient id="wline" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1677FF" stop-opacity="0"/>
      <stop offset=".5" stop-color="#1677FF" stop-opacity=".9"/>
      <stop offset="1" stop-color="#1677FF" stop-opacity="0"/>
    </linearGradient>
  </defs>
  <g font-family="'Arial Black','Segoe UI',sans-serif" font-weight="900" font-style="italic">
    <text x="56" y="300" font-size="290" letter-spacing="-6" fill="url(#wgrad)">X05</text>
  </g>
  <rect x="756" y="92" width="3" height="250" rx="1.5" fill="url(#wline)"/>
  <text x="814" y="295" font-family="'Segoe UI',Arial,sans-serif" font-weight="700"
        font-size="94" letter-spacing="25" fill="#A9C7EE">ANIME</text>
</svg>`;
}

function tvBannerSvg(w = 320, h = 180) {
  const s = h / 180;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 320 180">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#0B1226"/>
      <stop offset=".55" stop-color="#060A15"/>
      <stop offset="1" stop-color="#03050B"/>
    </linearGradient>
    <radialGradient id="glow" cx=".16" cy=".5" r=".5">
      <stop offset="0" stop-color="#1677FF" stop-opacity=".5"/>
      <stop offset=".55" stop-color="#1677FF" stop-opacity=".12"/>
      <stop offset="1" stop-color="#1677FF" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="barA" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset="1" stop-color="#AFCDFF"/>
    </linearGradient>
    <linearGradient id="barB" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#63B0FF"/>
      <stop offset="1" stop-color="#083BB4"/>
    </linearGradient>
    <linearGradient id="wgrad" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset=".6" stop-color="#DCEBFF"/>
      <stop offset="1" stop-color="#7DB6FF"/>
    </linearGradient>
    <linearGradient id="wline" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1677FF" stop-opacity=".1"/>
      <stop offset=".5" stop-color="#1677FF"/>
      <stop offset="1" stop-color="#1677FF" stop-opacity=".1"/>
    </linearGradient>
  </defs>
  <rect width="320" height="180" fill="url(#bg)"/>
  <rect width="320" height="180" fill="url(#glow)"/>
  <g opacity=".12" stroke="#7CBBFF" stroke-width="1">
    <path d="M150 205 L340 -20"/>
    <path d="M172 205 L360 -20"/>
  </g>
  <circle cx="283" cy="34" r="110" fill="none" stroke="#1677FF" stroke-opacity=".18" stroke-width="1.5"/>
  <g transform="translate(74 90) scale(0.102) translate(-512 -512)">
    ${BARS()}
    <circle cx="512" cy="512" r="176" fill="#05080F"/>
    <circle cx="512" cy="512" r="176" fill="none" stroke="#8FC4FF" stroke-opacity=".45" stroke-width="3"/>
    <path d="M466 430 L466 594 L630 512 Z" fill="#EAF4FF"/>
  </g>
  <rect x="148" y="46" width="1.5" height="88" rx=".75" fill="url(#wline)"/>
  <text x="166" y="105" font-family="'Arial Black','Segoe UI',sans-serif" font-weight="900"
        font-style="italic" font-size="62" letter-spacing="-1.5" fill="url(#wgrad)">X05</text>
  <text x="169" y="135" font-family="'Segoe UI',Arial,sans-serif" font-weight="700"
        font-size="17" letter-spacing="9" fill="#A9C7EE">ANIME</text>
</svg>`;
}

function topShelfSvg(w, h) {
  const s = h / 720;
  const cx = w / 2;
  const u = (n) => n * s;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#0C1428"/>
      <stop offset=".5" stop-color="#060A15"/>
      <stop offset="1" stop-color="#02040A"/>
    </linearGradient>
    <radialGradient id="glow" cx=".5" cy=".46" r=".52">
      <stop offset="0" stop-color="#1677FF" stop-opacity=".34"/>
      <stop offset=".55" stop-color="#1677FF" stop-opacity=".09"/>
      <stop offset="1" stop-color="#1677FF" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="edge" cx=".5" cy=".5" r=".5">
      <stop offset="0" stop-color="#1677FF" stop-opacity=".16"/>
      <stop offset="1" stop-color="#1677FF" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="barA" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset="1" stop-color="#AFCDFF"/>
    </linearGradient>
    <linearGradient id="barB" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#63B0FF"/>
      <stop offset="1" stop-color="#083BB4"/>
    </linearGradient>
    <linearGradient id="wgrad" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset=".55" stop-color="#DCEBFF"/>
      <stop offset="1" stop-color="#7DB6FF"/>
    </linearGradient>
    <linearGradient id="wline" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1677FF" stop-opacity="0"/>
      <stop offset=".5" stop-color="#1677FF"/>
      <stop offset="1" stop-color="#1677FF" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="rule" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#1677FF" stop-opacity="0"/>
      <stop offset=".5" stop-color="#1677FF" stop-opacity=".85"/>
      <stop offset="1" stop-color="#1677FF" stop-opacity="0"/>
    </linearGradient>
  </defs>
  <rect width="${w}" height="${h}" fill="url(#bg)"/>
  <rect width="${w}" height="${h}" fill="url(#glow)"/>
  <g opacity=".15" stroke="#7CBBFF" stroke-width="${u(1.6)}">
    <path d="M${u(-80)} ${u(860)} L${u(2100)} ${u(-40)}"/>
    <path d="M${u(-80)} ${u(960)} L${u(2100)} ${u(60)}"/>
  </g>
  <circle cx="${cx + u(470)}" cy="${u(360)}" r="${u(330)}" fill="url(#edge)"/>
  <g transform="rotate(-28 ${cx + u(470)} ${u(360)})">
    <circle cx="${cx + u(470)}" cy="${u(360)}" r="${u(300)}" fill="none" stroke="#4C9CFF"
            stroke-opacity=".20" stroke-width="${u(2)}"
            stroke-dasharray="${u(640)} ${u(120)} ${u(70)} ${u(380)}"/>
    <circle cx="${cx + u(470)}" cy="${u(360)}" r="${u(250)}" fill="none" stroke="#FFFFFF"
            stroke-opacity=".05" stroke-width="${u(1.2)}"/>
  </g>

  <!-- Lockup, optically centred as a whole. -->
  <g transform="translate(${cx - u(365)} 0)">
    <g transform="translate(${u(130)} ${u(360)}) scale(${0.255 * s}) translate(-512 -512)">
      ${BARS()}
      <circle cx="512" cy="512" r="176" fill="#05080F"/>
      <circle cx="512" cy="512" r="176" fill="none" stroke="#8FC4FF" stroke-opacity=".42" stroke-width="3"/>
      <path d="M466 430 L466 594 L630 512 Z" fill="#EAF4FF"/>
    </g>
    <rect x="${u(292)}" y="${u(242)}" width="${u(2)}" height="${u(236)}" rx="${u(1)}" fill="url(#wline)"/>
    <text x="${u(330)}" y="${u(410)}" font-family="'Arial Black','Segoe UI',sans-serif"
          font-weight="900" font-style="italic" font-size="${u(152)}" letter-spacing="${u(-3)}"
          fill="url(#wgrad)">X05</text>
    <text x="${u(336)}" y="${u(474)}" font-family="'Segoe UI',Arial,sans-serif" font-weight="700"
          font-size="${u(45)}" letter-spacing="${u(25)}" fill="#A9C7EE">ANIME</text>
  </g>

  <rect x="${cx - u(170)}" y="${u(560)}" width="${u(340)}" height="${u(1.4)}" fill="url(#rule)"/>
  <text x="${cx}" y="${u(616)}" text-anchor="middle" font-family="'Segoe UI',Arial,sans-serif"
        font-weight="600" font-size="${u(24)}" letter-spacing="${u(13)}"
        fill="#7F9CC8">STREAM. DISCOVER. REPEAT.</text>
</svg>`;
}

// tvOS app icon layers. Back stays opaque; middle/front are transparent for
// parallax. The large canvas is 1280x768 (5:3), the small 400x240.
function tvBack(w, h) {
  const s = h / 768;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#0B1226"/>
      <stop offset=".5" stop-color="#060A15"/>
      <stop offset="1" stop-color="#03050B"/>
    </linearGradient>
    <radialGradient id="glow" cx=".5" cy=".46" r=".55">
      <stop offset="0" stop-color="#1677FF" stop-opacity=".34"/>
      <stop offset=".55" stop-color="#1677FF" stop-opacity=".08"/>
      <stop offset="1" stop-color="#1677FF" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="vig" cx=".5" cy=".45" r=".72">
      <stop offset=".6" stop-color="#000" stop-opacity="0"/>
      <stop offset="1" stop-color="#000" stop-opacity=".5"/>
    </radialGradient>
  </defs>
  <rect width="${w}" height="${h}" fill="url(#bg)"/>
  <rect width="${w}" height="${h}" fill="url(#glow)"/>
  <g opacity=".10" stroke="#7CBBFF" stroke-width="${2 * s}">
    <path d="M${-80 * s} ${1000 * s} L${1360 * s} ${-40 * s}"/>
    <path d="M${-80 * s} ${1090 * s} L${1360 * s} ${50 * s}"/>
    <path d="M${-80 * s} ${1180 * s} L${1360 * s} ${140 * s}"/>
  </g>
  <rect width="${w}" height="${h}" fill="url(#vig)"/>
</svg>`;
}

function tvMiddle(w, h) {
  const s = h / 768;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">
  <defs>
    <radialGradient id="halo" cx=".5" cy=".5" r=".5">
      <stop offset="0" stop-color="#1677FF" stop-opacity=".30"/>
      <stop offset=".55" stop-color="#1677FF" stop-opacity=".08"/>
      <stop offset="1" stop-color="#1677FF" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="ring" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#CDE6FF" stop-opacity=".80"/>
      <stop offset=".45" stop-color="#4C9CFF" stop-opacity=".35"/>
      <stop offset="1" stop-color="#1677FF" stop-opacity="0"/>
    </linearGradient>
  </defs>
  <circle cx="${w / 2}" cy="${h / 2}" r="${330 * s}" fill="url(#halo)"/>
  <g transform="rotate(-30 ${w / 2} ${h / 2})">
    <circle cx="${w / 2}" cy="${h / 2}" r="${300 * s}" fill="none" stroke="url(#ring)"
            stroke-width="${3 * s}" stroke-linecap="round"
            stroke-dasharray="${540 * s} ${120 * s} ${70 * s} ${340 * s}" opacity=".8"/>
    <circle cx="${w / 2}" cy="${h / 2}" r="${258 * s}" fill="none" stroke="#FFFFFF"
            stroke-opacity=".08" stroke-width="${1.4 * s}"/>
  </g>
</svg>`;
}

function tvFront(w, h, { spark = true } = {}) {
  const s = h / 768;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">
  <defs>
    <linearGradient id="barA" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset=".52" stop-color="#F2F8FF"/>
      <stop offset="1" stop-color="#AFCDFF"/>
    </linearGradient>
    <linearGradient id="barB" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#63B0FF"/>
      <stop offset=".48" stop-color="#1677FF"/>
      <stop offset="1" stop-color="#083BB4"/>
    </linearGradient>
    <linearGradient id="play" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset="1" stop-color="#A9CEFF"/>
    </linearGradient>
    <filter id="soft" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="${10 * s}" result="b"/>
      <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>
  <g transform="translate(${w / 2} ${h / 2}) scale(${0.225 * s}) translate(-512 -512)" filter="url(#soft)">
    ${BARS()}
    ${DISC(P.signature)}
  </g>
  ${
    spark
      ? `<g transform="translate(${w / 2 + 165 * s} ${h / 2 - 165 * s})">
           <circle r="${26 * s}" fill="#1677FF" opacity=".16"/>
           <path transform="scale(${s})" d="M0 -26 L6 -6 L26 0 L6 6 L0 26 L-6 6 L-26 0 L-6 -6 Z" fill="#FFFFFF"/>
         </g>`
      : ''
  }
</svg>`;
}

let renderSeq = 0;

async function render(svg, outRel, w, h) {
  const out = path.join(ROOT, outRel);
  fs.mkdirSync(path.dirname(out), { recursive: true });
  const id = `${String(renderSeq++).padStart(3, '0')}_${outRel.replace(/[^a-z0-9]+/gi, '_')}`;
  const svgPath = path.join(TMP, `${id}.svg`);
  const shot = path.join(TMP, `${id}.png`);
  fs.writeFileSync(svgPath, svg, 'utf8');
  fs.rmSync(shot, { force: true });

  const args = [
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-extensions',
    '--disable-background-networking',
    '--metrics-recording-only',
    '--force-device-scale-factor=1',
    `--user-data-dir=${PROFILE}`,
    '--default-background-color=00000000',
    `--screenshot=${shot}`,
    `--window-size=${w},${h}`,
    `file:///${svgPath.replace(/\\/g, '/')}`,
  ];

  for (let attempt = 0; attempt < 2 && !fs.existsSync(shot); attempt++) {
    const child = spawn(CHROME, args, { stdio: 'ignore' });
    await new Promise((resolve) => {
      const timer = setTimeout(() => {
        child.kill();
        resolve();
      }, 30000);
      child.on('exit', () => {
        clearTimeout(timer);
        resolve();
      });
      child.on('error', () => {
        clearTimeout(timer);
        resolve();
      });
    });
    for (let i = 0; i < 60 && !fs.existsSync(shot); i++) {
      await new Promise((r) => setTimeout(r, 100));
    }
    if (!fs.existsSync(shot)) await new Promise((r) => setTimeout(r, 500));
  }

  if (!fs.existsSync(shot)) throw new Error(`render failed: ${outRel}`);
  const buf = fs.readFileSync(shot);
  if (buf.toString('ascii', 1, 4) !== 'PNG') throw new Error(`not a png: ${outRel}`);
  const pw = buf.readUInt32BE(16);
  const ph = buf.readUInt32BE(20);
  if (pw !== w || ph !== h) throw new Error(`size mismatch ${outRel}: ${pw}x${ph} != ${w}x${h}`);
  fs.copyFileSync(shot, out);
  return out;
}

function writeSource(rel, contents) {
  const out = path.join(ROOT, rel);
  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, contents, 'utf8');
}

const jobs = [];

// Brand sources (checked in for future regenerations).
writeSource('assets/brand/x05-icon.svg', fullIcon(P.signature, 1024));
writeSource('assets/brand/x05-icon-ice.svg', fullIcon(P.ice, 1024));
writeSource('assets/brand/x05-icon-midnight.svg', fullIcon(P.midnight, 1024));
writeSource('assets/brand/x05-mark.svg', markSvg(P.signature, 1024));
writeSource('assets/brand/x05-wordmark.svg', wordmarkSvg());
writeSource('assets/brand/x05-tv-banner.svg', tvBannerSvg());
writeSource('assets/brand/x05-top-shelf.svg', topShelfSvg(1920, 720));
writeSource('assets/brand/x05-top-shelf-wide.svg', topShelfSvg(2320, 720));

// In-app raster assets.
jobs.push(() => render(fullIcon(P.signature, 1024), 'assets/icon/app_icon.png', 1024, 1024));
jobs.push(() => render(markSvg(P.signature, 1024), 'assets/icon/logo_mark.png', 1024, 1024));
jobs.push(() => render(wordmarkSvg(), 'assets/icon/wordmark.png', 1440, 420));
jobs.push(() => render(fullIcon(P.signature, 512), 'assets/icon/preview_crescent.png', 512, 512));
jobs.push(() => render(fullIcon(P.ice, 512), 'assets/icon/preview_default.png', 512, 512));
jobs.push(() => render(fullIcon(P.midnight, 512), 'assets/icon/preview_classic.png', 512, 512));

// Android launcher icons: legacy, adaptive foreground, themed mono.
const density = {
  mdpi: { legacy: 48, fg: 108 },
  hdpi: { legacy: 72, fg: 162 },
  xhdpi: { legacy: 96, fg: 216 },
  xxhdpi: { legacy: 144, fg: 324 },
  xxxhdpi: { legacy: 192, fg: 432 },
};
for (const [name, d] of Object.entries(density)) {
  const base = `android/app/src/main/res/mipmap-${name}`;
  jobs.push(() => render(compactIcon(P.signature, d.legacy), `${base}/ic_launcher_crescent.png`, d.legacy, d.legacy));
  jobs.push(() => render(compactIcon(P.ice, d.legacy), `${base}/ic_launcher.png`, d.legacy, d.legacy));
  jobs.push(() => render(compactIcon(P.midnight, d.legacy), `${base}/ic_launcher_classic.png`, d.legacy, d.legacy));

  jobs.push(() => render(adaptiveForeground(P.signature, d.fg), `${base}/ic_launcher_crescent_fg.png`, d.fg, d.fg));
  jobs.push(() => render(adaptiveForeground(P.ice, d.fg), `${base}/ic_launcher_fg.png`, d.fg, d.fg));
  jobs.push(() => render(adaptiveForeground(P.midnight, d.fg), `${base}/ic_launcher_classic_fg.png`, d.fg, d.fg));
  jobs.push(() => render(adaptiveForeground(P.signature, d.fg, { mono: true }), `${base}/ic_launcher_crescent_mono.png`, d.fg, d.fg));
}

// Android TV banner.
jobs.push(() => render(tvBannerSvg(), 'android/app/src/main/res/drawable-xhdpi/tv_banner.png', 320, 180));

// iOS AppIcon.
const ios = {
  'Icon-App-20x20@1x.png': 20,
  'Icon-App-20x20@2x.png': 40,
  'Icon-App-20x20@3x.png': 60,
  'Icon-App-29x29@1x.png': 29,
  'Icon-App-29x29@2x.png': 58,
  'Icon-App-29x29@3x.png': 87,
  'Icon-App-40x40@1x.png': 40,
  'Icon-App-40x40@2x.png': 80,
  'Icon-App-40x40@3x.png': 120,
  'Icon-App-57x57@1x.png': 57,
  'Icon-App-57x57@2x.png': 114,
  'Icon-App-60x60@2x.png': 120,
  'Icon-App-60x60@3x.png': 180,
  'Icon-App-72x72@1x.png': 72,
  'Icon-App-72x72@2x.png': 144,
  'Icon-App-76x76@1x.png': 76,
  'Icon-App-76x76@2x.png': 152,
  'Icon-App-83.5x83.5@2x.png': 167,
  'Icon-App-1024x1024@1x.png': 1024,
};
for (const [file, size] of Object.entries(ios)) {
  const svg = size >= 128 ? fullIcon(P.signature, size) : compactIcon(P.signature, size);
  jobs.push(() => render(svg, `ios/Runner/Assets.xcassets/AppIcon.appiconset/${file}`, size, size));
}

// tvOS layered icons.
const tvLayers = [
  { stack: 'App Icon - Large.imagestack', prefix: 'large', base: [1280, 768], make: tvBack },
  { stack: 'App Icon - Large.imagestack', prefix: 'large', base: [1280, 768], make: tvMiddle },
  { stack: 'App Icon - Large.imagestack', prefix: 'large', base: [1280, 768], make: tvFront },
  { stack: 'App Icon - Small.imagestack', prefix: 'small', base: [400, 240], make: tvBack },
  { stack: 'App Icon - Small.imagestack', prefix: 'small', base: [400, 240], make: tvMiddle },
  { stack: 'App Icon - Small.imagestack', prefix: 'small', base: [400, 240], make: tvFront },
];
for (const { stack, prefix, base, make } of tvLayers) {
  const layer = make === tvBack ? 'Back' : make === tvMiddle ? 'Middle' : 'Front';
  for (const is2x of [false, true]) {
    const w = base[0] * (is2x ? 2 : 1);
    const h = base[1] * (is2x ? 2 : 1);
    const file = `${prefix}_${layer.toLowerCase()}${is2x ? '@2x' : ''}.png`;
    jobs.push(() => render(make(w, h), `tvos/Runner/Assets.xcassets/AppIcon.brandassets/${stack}/${layer}.imagestacklayer/Content.imageset/${file}`, w, h));
  }
}

// tvOS Top Shelf.
jobs.push(() => render(topShelfSvg(1920, 720), 'tvos/Runner/Assets.xcassets/AppIcon.brandassets/Top Shelf Image.imageset/top_shelf.png', 1920, 720));
jobs.push(() => render(topShelfSvg(3840, 1440), 'tvos/Runner/Assets.xcassets/AppIcon.brandassets/Top Shelf Image.imageset/top_shelf@2x.png', 3840, 1440));
jobs.push(() => render(topShelfSvg(2320, 720), 'tvos/Runner/Assets.xcassets/AppIcon.brandassets/Top Shelf Image Wide.imageset/top_shelf_wide.png', 2320, 720));
jobs.push(() => render(topShelfSvg(4640, 1440), 'tvos/Runner/Assets.xcassets/AppIcon.brandassets/Top Shelf Image Wide.imageset/top_shelf_wide@2x.png', 4640, 1440));

for (const job of jobs) {
  const out = await job();
  console.log('rendered', path.relative(ROOT, out));
}

// The transparent lockups are drawn with BoxFit.contain, so crop the empty
// canvas away. Pillow is optional for the icon pipeline but present wherever
// this script is normally run; a missing runtime only costs some padding.
const trimScript = path.join(ROOT, 'tool', 'trim_transparent.py');
function trimTransparent(args) {
  const result = spawnSync('python', [trimScript, ...args], {
    stdio: 'inherit',
  });
  if (result.error || result.status !== 0) {
    console.warn('warning: could not trim transparent brand PNGs (need Python + Pillow)');
  }
}
trimTransparent(['--square', '--padding', '24', path.join(ROOT, 'assets/icon/logo_mark.png')]);
trimTransparent(['--padding', '24', path.join(ROOT, 'assets/icon/wordmark.png')]);

console.log(`\nDone: ${jobs.length} rasters.`);

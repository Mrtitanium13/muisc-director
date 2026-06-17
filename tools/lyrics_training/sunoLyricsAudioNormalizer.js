/**
 * Suno Post-Generation Text Normalizer
 * Translates complex LLM lyrics into streamlined, audio-safe AI tags.
 */

const DJ_INTRO_RE = /\[\d+-bar\s+DJ\s+intro[^\]]*\]/gi;
const DJ_OUTRO_RE = /\[\d+-bar\s+DJ\s+outro[^\]]*\]/gi;
const DEAD_ROOM_RE = /\[Dead-room[^\]]*\]/gi;
const MALE_INTIMATE_RE = /\[Male\s+Vocal,\s*Intimate[^\]]*\]/gi;
const MALE_WHISPERED_RE = /\[Male\s+Vocal,\s*Whispered[^\]]*\]/gi;
const MALE_BUILDING_RE = /\[Male\s+Vocal,\s*Building\s+Intensity[^\]]*\]/gi;
const SECTION_HEADER_RE = /^\[([^\]]+)\]\s*$/;
const PAREN_ONLY_LINE_RE = /^\([^)]+\)\s*$/;

/**
 * @param {string} line
 * @returns {string|null}
 */
function shoutFromParenLine(line) {
  const m = line.trim().match(/^\(([^)]+)\)\s*$/);
  if (!m) return null;
  let text = m[1].trim();
  if (!text) return null;
  text = text.replace(/\.{2,}$/, '!');
  if (!/[!.?]$/.test(text)) text += '!';
  return text;
}

/**
 * @param {string} header
 * @returns {boolean}
 */
function isDropHeader(header) {
  const h = header.trim().toLowerCase();
  return h === 'drop' || h === 'final drop';
}

/**
 * @param {string} text
 * @returns {string}
 */
function fixParenOnlyDropSections(text) {
  const lines = text.split('\n');
  const out = [];
  let i = 0;

  while (i < lines.length) {
    const line = lines[i];
    const headerMatch = line.trim().match(SECTION_HEADER_RE);
    if (headerMatch && isDropHeader(headerMatch[1])) {
      const header = headerMatch[1].trim();
      const body = [];
      i += 1;
      while (i < lines.length) {
        const next = lines[i];
        if (SECTION_HEADER_RE.test(next.trim())) break;
        if (next.trim()) body.push(next);
        i += 1;
      }

      const onlyParens =
        body.length > 0 && body.every((l) => PAREN_ONLY_LINE_RE.test(l.trim()));

      if (onlyParens) {
        const shout = shoutFromParenLine(body[body.length - 1]);
        if (shout) {
          out.push('[Pre-Drop]');
          out.push(shout);
          out.push('');
        }
        out.push(`[${header}]`);
        out.push(
          header.toLowerCase().includes('final')
            ? '[Maximum Energy Instrumental Drop]'
            : '[Instrumental Drop]',
        );
        continue;
      }

      out.push(line);
      out.push(...body);
      continue;
    }

    out.push(line);
    i += 1;
  }

  return out.join('\n');
}

/**
 * @param {string} llmLyrics
 * @returns {string}
 */
function normalizeLyricsForAudioEngine(llmLyrics) {
  if (!llmLyrics) return '';

  let out = llmLyrics
    .replace(DJ_INTRO_RE, '[Intro]\n[Atmospheric Synth Intro]')
    .replace(DJ_OUTRO_RE, '[Outro]\n[Minimal Outro]')
    .replace(DEAD_ROOM_RE, '[Intimate Male Vocal]')
    .replace(MALE_INTIMATE_RE, '[Intimate Male Vocal]')
    .replace(MALE_WHISPERED_RE, '[Whispered Male Vocal]')
    .replace(
      MALE_BUILDING_RE,
      '[Building Intensity]\n[Accelerating Snare Roll]',
    )
    .replace(/Prophet-5/gi, 'Synth')
    .replace(/TR-909/gi, 'Drums')
    .replace(/TR-808/gi, 'Drums')
    .replace(
      /\[Drop\]\n\(Tonight\.\.\.\)\n\(Tonight\.\.\.\)/gi,
      '[Pre-Drop]\nTonight!\n\n[Drop]\n[Instrumental Drop]',
    )
    .replace(
      /\[Final Drop\]\n\(Tonight\.\.\.\)\n\(We're infinite\.\.\.\)/gi,
      '[Pre-Drop]\nWe are infinite!\n\n[Final Drop]\n[Maximum Energy Instrumental Drop]',
    );

  out = fixParenOnlyDropSections(out);
  out = out.replace(/\n{3,}/g, '\n\n').trim();
  return out;
}

module.exports = {
  normalizeLyricsForAudioEngine,
  fixParenOnlyDropSections,
  shoutFromParenLine,
};

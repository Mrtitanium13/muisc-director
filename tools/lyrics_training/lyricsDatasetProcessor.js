/**
 * Lyric arrangement tokenizer (Progressive House + Hardstyle profiles).
 *
 * Energy profile mirrors standard DAW block changes:
 * - valley    (Verse / Breakdown) — longer narrative lines
 * - monologue (Hardstyle spoken manifesto) — zero melodic weight, high narrative
 * - tension   (Pre-Chorus / Build) — shorter, repetitive push
 * - peak      (Chorus) — hook density
 * - drop      (Drop) — minimalist anchors / exclamations
 */

const SECTION_HEADER_RE = /^\[([^\]]+)\]\s*$/;

/** @typedef {'valley'|'monologue'|'tension'|'peak'|'drop'|'other'} EnergyProfile */

/**
 * @param {string} header
 * @returns {EnergyProfile}
 */
function classifySectionEnergy(header) {
  const h = header.toLowerCase();
  if (h.includes('drop')) return 'drop';
  if (h.includes('monologue') || h.includes('spoken')) return 'monologue';
  if (
    h.includes('pre-chorus') ||
    h.includes('pre chorus') ||
    h.includes('build') ||
    h.includes('rise')
  ) {
    return 'tension';
  }
  if (h.includes('verse') || h.includes('breakdown') || h.includes('bridge')) {
    return 'valley';
  }
  if (h.includes('chorus') || h.includes('hook')) return 'peak';
  return 'other';
}

/**
 * @param {EnergyProfile} energy
 * @param {string} line
 * @returns {'narrative'|'cinematic'|'tension'|'hook'|'minimal'|'neutral'}
 */
function classifyLineDensity(energy, line) {
  const text = line.trim();
  const words = text.split(/\s+/).filter(Boolean);
  const wordCount = words.length;

  if (energy === 'monologue') {
    return wordCount >= 6 ? 'cinematic' : 'narrative';
  }
  if (energy === 'drop') {
    return wordCount <= 4 ? 'minimal' : 'hook';
  }
  if (energy === 'tension') {
    return wordCount <= 8 ? 'tension' : 'neutral';
  }
  if (energy === 'valley') {
    return wordCount >= 9 ? 'narrative' : 'neutral';
  }
  if (energy === 'peak') {
    return wordCount <= 6 ? 'hook' : 'neutral';
  }
  return 'neutral';
}

/**
 * Hardstyle [Monologue] blocks: spoken cinematic overlay, not sung melody.
 *
 * @param {EnergyProfile} energy
 */
function sectionMelodicWeight(energy) {
  if (energy === 'monologue') return 0;
  if (energy === 'drop') return 0.25;
  if (energy === 'tension') return 0.5;
  if (energy === 'peak') return 1;
  if (energy === 'valley') return 0.75;
  return 0.5;
}

/**
 * @param {EnergyProfile} energy
 * @returns {'low'|'medium'|'high'}
 */
function sectionNarrativeWeight(energy) {
  if (energy === 'monologue') return 'high';
  if (energy === 'valley') return 'high';
  if (energy === 'tension') return 'medium';
  if (energy === 'peak') return 'medium';
  if (energy === 'drop') return 'low';
  return 'medium';
}

/**
 * Tokenize bracket-structured lyrics into an arrangement-aware line matrix.
 *
 * @param {string} lyrics
 * @returns {Array<Record<string, unknown>>}
 */
function tokenizeArrangement(lyrics) {
  const tokens = [];
  let currentSection = '';
  /** @type {EnergyProfile} */
  let currentEnergy = 'other';

  for (const rawLine of lyrics.split('\n')) {
    const trimmed = rawLine.trim();
    const sectionMatch = trimmed.match(SECTION_HEADER_RE);

    if (sectionMatch) {
      currentSection = sectionMatch[1];
      currentEnergy = classifySectionEnergy(currentSection);
      tokens.push({
        type: 'section',
        label: currentSection,
        energy: currentEnergy,
        melodicWeight: sectionMelodicWeight(currentEnergy),
        narrativeWeight: sectionNarrativeWeight(currentEnergy),
        zeroMelodic: currentEnergy === 'monologue',
      });
      continue;
    }

    if (!trimmed) {
      tokens.push({ type: 'break' });
      continue;
    }

    const wordCount = trimmed.split(/\s+/).filter(Boolean).length;
    tokens.push({
      type: 'line',
      section: currentSection,
      energy: currentEnergy,
      density: classifyLineDensity(currentEnergy, trimmed),
      melodicWeight: sectionMelodicWeight(currentEnergy),
      narrativeWeight: sectionNarrativeWeight(currentEnergy),
      zeroMelodic: currentEnergy === 'monologue',
      text: trimmed,
      wordCount,
      charCount: trimmed.length,
    });
  }

  return tokens;
}

/**
 * @param {unknown} songs
 * @param {{ profile?: 'progressive_house'|'hardstyle', expectedCount?: number }} [options]
 * @returns {string[]}
 */
function verifyDataset(songs, options = {}) {
  const profile = options.profile || 'progressive_house';
  const expectedCount = options.expectedCount ?? 20;
  const errors = [];

  if (!Array.isArray(songs)) {
    return ['Dataset root must be a JSON array.'];
  }
  if (songs.length !== expectedCount) {
    errors.push(`Expected ${expectedCount} tracks, found ${songs.length}.`);
  }

  songs.forEach((song, index) => {
    const label = `Track ${index + 1}`;
    if (!song || typeof song !== 'object') {
      errors.push(`${label}: not an object.`);
      return;
    }
    for (const key of ['title', 'artist', 'theme', 'lyrics']) {
      if (typeof song[key] !== 'string' || !song[key].trim()) {
        errors.push(`${label}: missing or empty "${key}".`);
      }
    }
    if (typeof song.lyrics !== 'string') return;

    const lyrics = song.lyrics;
    if (!/\[Drop\]/i.test(lyrics)) {
      errors.push(`${label} (${song.title}): missing [Drop] section.`);
    }
    if (!/\[Pre-Chorus\]/i.test(lyrics)) {
      errors.push(`${label} (${song.title}): missing [Pre-Chorus] section.`);
    }

    if (profile === 'progressive_house') {
      if (!/\[Verse/i.test(lyrics)) {
        errors.push(`${label} (${song.title}): missing [Verse] section.`);
      }
    } else if (profile === 'hardstyle') {
      if (!/\[Verse/i.test(lyrics) && !/\[Monologue\]/i.test(lyrics)) {
        errors.push(
          `${label} (${song.title}): missing [Verse] or [Monologue] opener.`,
        );
      }
    }

    const tokens = tokenizeArrangement(lyrics);
    const lineTokens = tokens.filter((t) => t.type === 'line');
    if (lineTokens.length < 4) {
      errors.push(
        `${label} (${song.title}): too few lyric lines (${lineTokens.length}).`,
      );
    }
  });

  return errors;
}

/**
 * @param {ReturnType<typeof tokenizeArrangement>} tokens
 */
function summarizeEnergyProfile(tokens) {
  const summary = {
    valley: 0,
    monologue: 0,
    tension: 0,
    peak: 0,
    drop: 0,
    other: 0,
  };
  for (const token of tokens) {
    if (token.type !== 'line') continue;
    const key = /** @type {EnergyProfile} */ (token.energy);
    summary[key] = (summary[key] ?? 0) + 1;
  }
  return summary;
}

module.exports = {
  tokenizeArrangement,
  verifyDataset,
  summarizeEnergyProfile,
  classifySectionEnergy,
  classifyLineDensity,
  sectionMelodicWeight,
  sectionNarrativeWeight,
};

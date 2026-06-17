/**
 * Export progressive-house dataset → OpenAI chat fine-tune JSONL.
 *
 * Usage: node exportFinetuneJsonl.js [outputPath]
 */
const fs = require('fs');
const path = require('path');
const { loadAndVerifyDataset } = require('./loadDataset');

const DEFAULT_OUT = path.join(__dirname, 'progressive_house_finetune.jsonl');

const SYSTEM_PROMPT = [
  'You are a progressive-house lyricist for Suno Block 2 output.',
  'Match DAW energy: long narrative verses, tightening pre-choruses,',
  'hook-dense choruses, minimalist drop anchors.',
  'Use only bracket section tags: [Verse 1], [Pre-Chorus], [Chorus], [Drop], [End].',
].join(' ');

function buildTrainingRows(pipeline) {
  return pipeline.map((track) => {
    const user = [
      `Genre: Progressive House / EDM`,
      `Theme: ${track.theme}`,
      `Reference artist lane: ${track.artist}`,
      `Write original Suno Block 2 lyrics with arrangement sections.`,
      `Energy map: ${JSON.stringify(track.energyProfile)}`,
    ].join('\n');

    const assistant = `${track.lyrics.trim()}\n[End]`;

    return {
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: user },
        { role: 'assistant', content: assistant },
      ],
    };
  });
}

function exportFinetuneJsonl(outputPath = DEFAULT_OUT) {
  const pipeline = loadAndVerifyDataset();
  if (!pipeline) {
    throw new Error('Dataset verification failed — cannot export JSONL.');
  }

  const rows = buildTrainingRows(pipeline);
  const body = rows.map((row) => JSON.stringify(row)).join('\n') + '\n';
  fs.writeFileSync(outputPath, body, 'utf8');
  console.log(`✅ Wrote ${rows.length} training rows → ${outputPath}`);
  return outputPath;
}

if (require.main === module) {
  const out = process.argv[2] ? path.resolve(process.argv[2]) : DEFAULT_OUT;
  exportFinetuneJsonl(out);
}

module.exports = { exportFinetuneJsonl, buildTrainingRows, SYSTEM_PROMPT };

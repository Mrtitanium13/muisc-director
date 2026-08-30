// loadAmapianoDataset.js
const fs = require('fs');
const path = require('path');
const {
  tokenizeArrangement,
  verifyDataset,
  summarizeEnergyProfile,
} = require('./lyricsDatasetProcessor');

const LOCAL_DATASET = path.join(__dirname, 'amapianoDataset.json');

function resolveDatasetPath() {
  return LOCAL_DATASET;
}

function loadAmapianoDataset() {
  const dataPath = resolveDatasetPath();
  const rawData = fs.readFileSync(dataPath, 'utf8');
  return JSON.parse(rawData);
}

function loadAndVerifyDataset() {
  try {
    const songs = loadAmapianoDataset();
    console.log(`📦 Loaded amapiano dataset containing ${songs.length} cadence references.`);

    const errors = verifyDataset(
      songs.map((s) => ({
        title: s.title,
        artist: s.artist,
        theme: s.theme,
        lyrics: `[Verse 1]\n${s.cadenceNote}\n[Chorus]\nReference cadence only.\n[Drop]\n[Drop: Heavy Rolling Log Drum]`,
      })),
      { profile: 'progressive_house', expectedCount: 20 },
    );
    if (errors.length > 0) {
      console.error('❌ Amapiano dataset verification failed:');
      for (const err of errors) console.error(`   • ${err}`);
      process.exitCode = 1;
      return null;
    }

    console.log('🔥 Amapiano cadence reference matrix verified.');
    return songs;
  } catch (error) {
    console.error('❌ Execution Error parsing amapiano reference array:', error);
    process.exitCode = 1;
    return null;
  }
}

if (require.main === module) {
  loadAndVerifyDataset();
}

module.exports = {
  loadAmapianoDataset,
  loadAndVerifyDataset,
  resolveDatasetPath,
};

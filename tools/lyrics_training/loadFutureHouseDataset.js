// loadFutureHouseDataset.js
const fs = require('fs');
const path = require('path');
const {
  tokenizeArrangement,
  verifyDataset,
  summarizeEnergyProfile,
} = require('./lyricsDatasetProcessor');

const LOCAL_DATASET = path.join(__dirname, 'futureHouseDataset.json');

function resolveDatasetPath() {
  return LOCAL_DATASET;
}

function loadFutureHouseDataset() {
  const dataPath = resolveDatasetPath();
  const rawData = fs.readFileSync(dataPath, 'utf8');
  return JSON.parse(rawData);
}

function loadAndVerifyDataset() {
  try {
    const songs = loadFutureHouseDataset();
    console.log(`📦 Loaded future house dataset containing ${songs.length} master tracks.`);

    const errors = verifyDataset(songs, {
      profile: 'progressive_house',
      expectedCount: 10,
    });
    if (errors.length > 0) {
      console.error('❌ Dataset verification failed:');
      for (const err of errors) console.error(`   • ${err}`);
      process.exitCode = 1;
      return null;
    }

    const fullyTokenizedPipeline = songs.map((song) => {
      const tokens = tokenizeArrangement(song.lyrics);
      return {
        title: song.title,
        artist: song.artist,
        theme: song.theme,
        lyrics: song.lyrics,
        tokens,
        energyProfile: summarizeEnergyProfile(tokens),
      };
    });

    console.log('🔥 Verification: Future house tokenization matrix build successful!');
    return fullyTokenizedPipeline;
  } catch (error) {
    console.error('❌ Execution Error parsing future house training array:', error);
    process.exitCode = 1;
    return null;
  }
}

if (require.main === module) {
  loadAndVerifyDataset();
}

module.exports = {
  loadFutureHouseDataset,
  loadAndVerifyDataset,
  resolveDatasetPath,
};

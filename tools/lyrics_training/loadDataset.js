// loadDataset.js
const fs = require('fs');
const path = require('path');
const {
  tokenizeArrangement,
  verifyDataset,
  summarizeEnergyProfile,
} = require('./lyricsDatasetProcessor');

const DATASET_FILE = 'progressiveHouseDataset.json';

function loadProgressiveHouseDataset() {
  const dataPath = path.join(__dirname, DATASET_FILE);
  const rawData = fs.readFileSync(dataPath, 'utf8');
  return JSON.parse(rawData);
}

function loadAndVerifyDataset() {
  const dataPath = path.join(__dirname, DATASET_FILE);

  try {
    const songs = loadProgressiveHouseDataset();
    console.log(`📦 Loaded dataset containing ${songs.length} master tracks.`);

    const errors = verifyDataset(songs, {
      profile: 'progressive_house',
      expectedCount: 20,
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

    console.log('🔥 Verification: Tokenization structural matrix build successful!');
    console.log(
      `   Sections tokenized across ${fullyTokenizedPipeline.length} tracks.`,
    );
    console.log(
      `   Sample (${fullyTokenizedPipeline[0].title}):`,
      fullyTokenizedPipeline[0].energyProfile,
    );

    return fullyTokenizedPipeline;
  } catch (error) {
    console.error('❌ Execution Error parsing training array:', error);
    process.exitCode = 1;
    return null;
  }
}

if (require.main === module) {
  loadAndVerifyDataset();
}

module.exports = {
  DATASET_FILE,
  loadProgressiveHouseDataset,
  loadAndVerifyDataset,
};

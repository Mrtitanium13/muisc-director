// loadHardstyleDataset.js
const fs = require('fs');
const path = require('path');
const {
  tokenizeArrangement,
  verifyDataset,
  summarizeEnergyProfile,
} = require('./lyricsDatasetProcessor');

const DATASET_FILE = 'hardstyleDataset.json';

function loadHardstyleDataset() {
  const dataPath = path.join(__dirname, DATASET_FILE);
  const rawData = fs.readFileSync(dataPath, 'utf8');
  return JSON.parse(rawData);
}

function loadAndVerifyHardstyleDataset() {
  try {
    const songs = loadHardstyleDataset();
    console.log(`📦 Loaded hardstyle dataset containing ${songs.length} master tracks.`);

    const errors = verifyDataset(songs, {
      profile: 'hardstyle',
      expectedCount: 20,
    });
    if (errors.length > 0) {
      console.error('❌ Hardstyle dataset verification failed:');
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
        profile: 'hardstyle',
        tokens,
        energyProfile: summarizeEnergyProfile(tokens),
      };
    });

    console.log('🔥 Verification: Hardstyle tokenization matrix build successful!');
    const monologueTracks = fullyTokenizedPipeline.filter((t) =>
      t.tokens.some((tok) => tok.type === 'section' && tok.energy === 'monologue'),
    ).length;
    console.log(
      `   ${monologueTracks}/${fullyTokenizedPipeline.length} tracks use [Monologue] cinematic openers.`,
    );
    console.log(
      `   Sample (${fullyTokenizedPipeline[1].title}):`,
      fullyTokenizedPipeline[1].energyProfile,
    );

    return fullyTokenizedPipeline;
  } catch (error) {
    console.error('❌ Execution Error parsing hardstyle training array:', error);
    process.exitCode = 1;
    return null;
  }
}

if (require.main === module) {
  loadAndVerifyHardstyleDataset();
}

module.exports = {
  DATASET_FILE,
  loadHardstyleDataset,
  loadAndVerifyHardstyleDataset,
};

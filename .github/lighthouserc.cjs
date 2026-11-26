const baseUrl = 'http://127.0.0.1:3000';

module.exports = {
  ci: {
    collect: {
      url: [`${baseUrl}/`, `${baseUrl}/data`, `${baseUrl}/c14s/${process.env.LIGHTHOUSE_C14_ID}`],
      numberOfRuns: 1,
      settings: {
        preset: 'desktop',
        onlyCategories: ['accessibility'],
      },
    },
    upload: {
      target: 'filesystem',
      outputDir: 'tmp/lighthouse-reports',
    },
  },
};

module.exports = {
  branches: ["main"],
  tagFormat: "v${version}",
  plugins: [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    ["@semantic-release/changelog", { changelogFile: "CHANGELOG.md" }],
    ["@semantic-release/exec", {
      prepareCmd: "bash scripts/set-release-version.sh ${nextRelease.version}",
      successCmd: "echo ${nextRelease.version} > .release-version"
    }],
    ["@semantic-release/git", {
      assets: ["CHANGELOG.md", "build.gradle"],
      message: "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
    }],
    "@semantic-release/github"
  ]
};

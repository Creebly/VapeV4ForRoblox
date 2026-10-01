// Uses the original VapeBundler helpers by 7GrandDad (ISC license).
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const src = path.join(root, 'src');
const dest = path.join(root, 'runtime');
const { VARS } = require('./bundler/vars.js');
const processGame = require('./bundler/processGame.js');
const processUI = require('./bundler/processUI.js');
VARS.IS_DEV = false;
VARS.DEST_PATH = dest;
for (const directory of ['', 'assets', 'libraries', 'games', 'guis']) {
  fs.mkdirSync(path.join(dest, directory), { recursive: true });
}
for (const file of ['main.lua', 'loader.lua']) {
  fs.copyFileSync(path.join(src, file), path.join(dest, file));
}
for (const file of fs.readdirSync(path.join(src, 'libraries'))) {
  fs.copyFileSync(path.join(src, 'libraries', file), path.join(dest, 'libraries', file));
}
for (const gui of fs.readdirSync(path.join(src, 'guis'))) {
  processUI(path.join(src, 'guis', gui), gui);
}
for (const game of fs.readdirSync(path.join(src, 'games'))) {
  const gamePath = path.join(src, 'games', game);
  if (game.includes('-')) processGame(gamePath, game);
  else for (const extra of fs.readdirSync(gamePath)) processGame(path.join(gamePath, extra), extra);
}
function filesUnder(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))
    .flatMap(entry => entry.isDirectory() ? filesUnder(path.join(directory, entry.name)) : [path.join(directory, entry.name)]);
}
// Isolate cached files so upstream scripts cannot override this fork.
for (const file of filesUnder(dest).filter(file => file.endsWith('.lua'))) {
  let code = fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n');
  code = code.replaceAll('newvape', 'creeblyvape')
    .replaceAll('7GrandDadPGN/VapeCompiled/', 'Creebly/VapeV4ForRoblox/')
    .replaceAll("..'/'..select(1, path:gsub", "..'/runtime/'..select(1, path:gsub")
    .replaceAll("..'/loader.lua'", "..'/runtime/loader.lua'");
  fs.writeFileSync(file, code);
}
const version = crypto.createHash('sha256');
for (const file of [...filesUnder(src), ...filesUnder(path.join(root, 'scripts'))].sort()) {
  version.update(path.relative(root, file).replaceAll('\\', '/'));
  const data = fs.readFileSync(file);
  version.update(/\.(lua|luau|js|cjs)$/.test(file) ? data.toString('utf8').replace(/\r\n/g, '\n') : data);
}
const buildVersion = version.digest('hex');
fs.writeFileSync(path.join(dest, 'version.txt'), buildVersion + '\n');
const loaderPath = path.join(dest, 'loader.lua');
fs.writeFileSync(loaderPath, fs.readFileSync(loaderPath, 'utf8').replaceAll('__FORK_BUILD_VERSION__', buildVersion));
for (const filename of ['NewMainScript.lua', 'AutoBankLoader.lua']) {
  fs.copyFileSync(loaderPath, path.join(root, filename));
}
console.log('Built source and runtime for Creebly/VapeV4ForRoblox.');

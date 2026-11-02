const { test } = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const { text } = require('../scripts/catalog.cjs')

// The iPad and Mac apps are built on macOS only (no CI workflow since typle-r v0.70.0); these checks of their data run
// everywhere with `node --test tests/`. Shared/ holds the text both apps use, and Mac/Resources/*/Mac.strings replaces
// it on the Mac where it names the iPad. TYPLE_R, a checkout of typle-r, also compares the official packs with the web
// app's.
const root = path.join(__dirname, '..')
const typleR = process.env.TYPLE_R ? path.resolve(process.env.TYPLE_R) : undefined

function swiftFiles(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    const file = path.join(dir, entry.name)
    if (entry.isDirectory()) return entry.name === '.build' ? [] : swiftFiles(file)
    return entry.name.endsWith('.swift') ? [file] : []
  })
}

function readStrings(file) {
  const text = fs.readFileSync(file, 'utf8')
  const strings = new Map()
  for (const match of text.matchAll(/^"((?:[^"\\]|\\.)*)" = "((?:[^"\\]|\\.)*)";$/gm)) {
    assert.equal(strings.has(match[1]), false, `${file}: ${match[1]} twice`)
    strings.set(match[1], JSON.parse(`"${match[2]}"`))
  }
  return strings
}

// `%@`, `%ld` and their positional forms, as [position, type]; `%%` is a literal percent sign.
function placeholders(value) {
  let next = 0
  return [...value.replaceAll('%%', '').matchAll(/%(?:(\d+)\$)?(@|ld|d)/g)]
    .map(([, position, type]) => `${position ?? ++next}:${type}`).sort()
}

const languages = ['ja', 'en']
const shared = Object.fromEntries(languages.map(lang => [lang, readStrings(path.join(root, 'Shared/Resources', `${lang}.lproj/Localizable.strings`))]))
const mac = Object.fromEntries(languages.map(lang => [lang, readStrings(path.join(root, 'Mac/Resources', `${lang}.lproj/Mac.strings`))]))
// Words for the iPad and its touch screen, which the Mac has not.
const iPadWords = /iPad|タップ|\bTap\b/

function enumCases(sources, name) {
  const match = sources.match(new RegExp(`enum ${name}\\b[^{]*\\{(?:\\s*///[^\\n]*)*\\s*case ([^\\n]+)`))
  assert.ok(match, `enum ${name}`)
  return match[1].split(',').map(item => item.trim())
}

test('the apps bundle the official packs of the web app', { skip: !typleR && 'TYPLE_R is not set' }, () => {
  assert.equal(fs.readFileSync(path.join(root, 'TypleCore/Sources/TypleCore/Resources/catalog.json'), 'utf8'), text(typleR),
    'run node scripts/catalog.cjs <typle-r> again')
})

test('the apps judge handwriting with the same cases as the web app', { skip: !typleR && 'TYPLE_R is not set' }, () => {
  assert.equal(fs.readFileSync(path.join(root, 'TypleCore/Tests/TypleCoreTests/Fixtures/writing/match.json'), 'utf8'),
    fs.readFileSync(path.join(typleR, 'tests/fixtures/writing/match.json'), 'utf8'), 'copy tests/fixtures/writing/match.json of typle-r again')
})

test('the apps have Japanese and English text for every key they use, with the same placeholders', () => {
  const files = ['Shared', 'iPad', 'Mac', 'TypleCore/Sources'].flatMap(dir => swiftFiles(path.join(root, dir)))
  const sources = files.map(file => fs.readFileSync(file, 'utf8')).join('\n')
  const dynamic = { 'wordLists.order.': 'ListOrder', 'rankings.list.sorts.': 'ListSort', 'settings.languageNames.': 'AppLanguage', 'settings.languages.': 'AppLanguage', 'rankings.mode.': 'PracticeMode' }
  const used = new Set()
  for (const [, argument] of sources.matchAll(/\bL\(((?:"(?:[^"\\]|\\.)*"|[^,()"])*)/g)) {
    for (const [, key] of argument.matchAll(/"([^"]*)"/g)) {
      const at = key.indexOf('\\(')
      if (at < 0) { used.add(key); continue }
      const prefix = key.slice(0, at)
      assert.ok(dynamic[prefix], `unknown dynamic key ${key}`)
      for (const value of enumCases(sources, dynamic[prefix])) used.add(prefix + value)
    }
  }
  for (const [, key] of sources.matchAll(/TypleError\("(\w+)"/g)) used.add(`errors.${key}`)
  assert.ok(used.size > 100)

  // The Mac's menus (Mac/) use keys that only Mac.strings has.
  const macOnly = new Set([...swiftFiles(path.join(root, 'Mac')).map(file => fs.readFileSync(file, 'utf8')).join('\n')
    .matchAll(/\bL\("([^"\\]*)"/g)].map(([, key]) => key).filter(key => mac.ja.has(key)))
  const { ja, en } = shared
  for (const key of used) {
    if (macOnly.has(key)) continue
    assert.ok(ja.has(key), `ja: missing ${key}`)
    assert.ok(en.has(key), `en: missing ${key}`)
  }
  assert.deepEqual([...en.keys()].sort(), [...ja.keys()].sort())
  for (const [key, value] of ja) assert.deepEqual(placeholders(en.get(key)), placeholders(value), key)
})

test('the Mac app has its own text wherever the shared text names the iPad', () => {
  for (const lang of languages) {
    for (const [key, value] of shared[lang]) {
      if (iPadWords.test(value)) assert.ok(mac[lang].has(key), `${lang}: Mac.strings needs ${key} (${value})`)
    }
    for (const [key, value] of mac[lang]) {
      assert.doesNotMatch(value, iPadWords, `${lang}: ${key}`)
      if (shared[lang].has(key)) assert.deepEqual(placeholders(value), placeholders(shared[lang].get(key)), `${lang}: ${key}`)
    }
  }
  assert.deepEqual([...mac.en.keys()].sort(), [...mac.ja.keys()].sort())
  for (const [key, value] of mac.ja) assert.deepEqual(placeholders(mac.en.get(key)), placeholders(value), key)
})

test('each app builds the shared sources with its own practice field', () => {
  const project = fs.readFileSync(path.join(root, 'project.yml'), 'utf8')
  for (const target of ['TypleiPad', 'TypleMac']) assert.match(project, new RegExp(`\\n  ${target}:\\n`), target)
  assert.equal(project.match(/- path: Shared\n/g).length, 2)
  assert.match(project, /- path: iPad\n/)
  assert.match(project, /- path: Mac\n/)
  assert.match(project, /path: TypleCore\n/)
  // Each platform has its own text field: UITextField on the iPad, NSTextField on the Mac.
  assert.equal(fs.existsSync(path.join(root, 'Shared/Practice/PracticeTextField.swift')), false)
  assert.ok(fs.existsSync(path.join(root, 'iPad/Practice/PracticeTextField.swift')))
  assert.ok(fs.existsSync(path.join(root, 'Mac/Practice/PracticeTextField.swift')))
})

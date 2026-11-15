"""Package an exported Godot Web build for hosts with per-file size limits.
Usage: python3 tools/package_web.py /absolute/path/to/web/export
The engine bytes stay unchanged; the loader streams two smaller static files.
"""
import pathlib, sys, json, hashlib, re
root = pathlib.Path(sys.argv[1]).resolve()
wasm = root / 'index.wasm'
data = wasm.read_bytes()
size = 20 * 1024 * 1024
parts = []
for i, start in enumerate(range(0, len(data), size)):
    name = f'index.wasm.part{i}'
    (root / name).write_bytes(data[start:start+size])
    parts.append(name)
loader = '''// Reassemble the unchanged Godot engine from static files below hosting limits.
(() => {
  const originalFetch = globalThis.fetch.bind(globalThis);
  globalThis.fetch = async (resource, options) => {
    const input = resource instanceof Request ? resource.url : String(resource);
    const url = new URL(input, document.baseURI);
    const expected = new URL('index.wasm', document.baseURI);
    if (url.origin !== expected.origin || url.pathname !== expected.pathname) {
      return originalFetch(resource, options);
    }
    const names = PARTS;
    const responses = await Promise.all(names.map(name => originalFetch(new URL(name, url), options)));
    if (responses.some(response => !response.ok)) throw new Error('Download del motore Godot non riuscito. Ricarica la pagina.');
    const body = new ReadableStream({
      async start(controller) {
        try {
          for (const response of responses) {
            const reader = response.body.getReader();
            while (true) {
              const {value, done} = await reader.read();
              if (done) break;
              controller.enqueue(value);
            }
          }
          controller.close();
        } catch (error) { controller.error(error); }
      }
    });
    return new Response(body, {headers: {'Content-Type': 'application/wasm', 'Content-Length': 'WASM_SIZE'}});
  };
})();
'''.replace('PARTS', json.dumps(parts)).replace('WASM_SIZE', str(len(data)))
(root / 'wasm-loader.js').write_text(loader)
html = root / 'index.html'
s = html.read_text()
pack = root / 'index.pck'
if pack.exists():
    pack_name = 'game-' + hashlib.sha256(pack.read_bytes()).hexdigest()[:12] + '.pck'
    config_match = re.search(r'const GODOT_CONFIG = (.*?);', s)
    config = json.loads(config_match.group(1))
    pack_size = config['fileSizes'].pop('index.pck')
    config['fileSizes'][pack_name] = pack_size
    config['mainPack'] = pack_name
    s = s[:config_match.start(1)] + json.dumps(config) + s[config_match.end(1):]
    pack.rename(root / pack_name)
s = s.replace('<script src="index.js"></script>', '<script src="wasm-loader.js"></script>\n\t\t<script src="index.js"></script>')
html.write_text(s)
assert b''.join((root/name).read_bytes() for name in parts) == data
wasm.unlink()
print('Packaged Godot engine:', len(data), 'bytes; SHA256', hashlib.sha256(data).hexdigest())

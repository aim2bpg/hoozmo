import { DefaultRubyVM } from "@ruby/wasm-wasi/dist/browser";

const MATCH_STYLES = {
  empty: 'inline-block text-[0.85em] font-medium px-1.5 py-0.5 text-transparent border border-transparent rounded leading-normal',
  match: 'inline-block text-[0.85em] font-medium px-1.5 py-0.5 rounded text-[#155724] bg-[#d4edda] border border-[#c3e6cb] leading-normal',
  no_match: 'inline-block text-[0.85em] font-medium px-1.5 py-0.5 rounded text-[#721c24] bg-[#f8d7da] border border-[#f5c6cb] leading-normal',
  error: 'inline-block text-[0.85em] font-medium px-1.5 py-0.5 rounded text-[#856404] bg-[#fff3cd] border border-[#ffeaa7] leading-normal'
};

async function initHoozmo(rubyVersion = '3.4') {
  const pkg = `@ruby/${rubyVersion}-wasm-wasi@latest`;
  const wasmUrl = `https://cdn.jsdelivr.net/npm/${pkg}/dist/ruby+stdlib.wasm`;
  const response = await fetch(wasmUrl);
  const module = await WebAssembly.compileStreaming(response);
  const { vm } = await DefaultRubyVM(module);

  // Hoozmoライブラリをロード (require_relativeを使わないで全て読み込む)
  const nodeLib = await fetch('/lib/hoozmo/node.rb').then(r => r.text());
  const literalLib = await fetch('/lib/hoozmo/node/literal.rb').then(r => r.text());
  const concatenationLib = await fetch('/lib/hoozmo/node/concatenation.rb').then(r => r.text());
  const choiceLib = await fetch('/lib/hoozmo/node/choice.rb').then(r => r.text());
  const epsilonLib = await fetch('/lib/hoozmo/node/epsilon.rb').then(r => r.text());
  const parserLib = await fetch('/lib/hoozmo/parser.rb').then(r => r.text());
  const hoozmoLib = await fetch('/lib/hoozmo.rb').then(r => r.text());

  // require_relativeを削除して結合
  const nodeLibClean = nodeLib.replace(/require_relative .+/g, '');
  const hoozmoLibClean = hoozmoLib.replace(/require_relative .+/g, '');

  // 依存順に評価
  vm.eval(nodeLibClean);
  vm.eval(literalLib);
  vm.eval(concatenationLib);
  vm.eval(choiceLib);
  vm.eval(epsilonLib);
  vm.eval(parserLib);
  vm.eval(hoozmoLibClean);

  return vm;
}

function updateMatchInfo(state, message) {
  const matchInfo = document.getElementById('match-info');
  if (!matchInfo) {
    console.error('match-info element not found');
    return;
  }
  matchInfo.className = MATCH_STYLES[state];
  matchInfo.innerHTML = message;
  console.log('Updated match info:', state, message);
}

async function main() {
  try {
    updateMatchInfo('empty', 'Loading Ruby...');
    
    let versionSelect = document.getElementById('ruby-version');
    const currentVersion = new URLSearchParams(location.search).get('ruby') || versionSelect?.value || '3.4';
    const vm = await initHoozmo(currentVersion);
    
    updateMatchInfo('empty', '...');

    function checkRegex() {
      const pattern = document.getElementById('pattern').value;
      const test = document.getElementById('test').value;
      
      if (!pattern) {
        updateMatchInfo('empty', '...');
        return;
      }
      
      try {
        // パターンとテスト文字列をエスケープ
        const escapedPattern = pattern.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\n/g, '\\n');
        const escapedTest = test.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\n/g, '\\n');
        
        const result = vm.eval(`
          regex = Hoozmo.new('${escapedPattern}')
          regex.match?('${escapedTest}')
        `);
        
        if (result.toString() === 'true') {
          updateMatchInfo('match', 'Match');
        } else {
          updateMatchInfo('no_match', 'No match');
        }
      } catch (e) {
        updateMatchInfo('error', `Error: ${e.message}`);
      }
    }

    document.getElementById('pattern').addEventListener('input', checkRegex);
    document.getElementById('test').addEventListener('input', checkRegex);

  document.getElementById('reset').addEventListener('click', () => {
    document.getElementById('pattern').value = '';
    document.getElementById('test').value = '';
    updateMatchInfo('empty', '...');
  });

    // Ruby version selector (handled above before init)
    if (versionSelect) {
      const currentVersion = new URLSearchParams(location.search).get('ruby') || versionSelect.value || '3.4';
      versionSelect.value = currentVersion;
      versionSelect.addEventListener('change', () => {
        const params = new URLSearchParams(location.search);
        params.set('ruby', versionSelect.value);
        const newUrl = `${location.pathname}?${params.toString()}`;
        window.history.replaceState({}, '', newUrl);
        location.reload();
      });
    }
  } catch (e) {
    updateMatchInfo('error', `Failed to initialize: ${e.message}`);
    console.error('Initialization error:', e);
  }
}

// DOMが読み込まれてから実行
if (document.readyState === 'loading') {
  console.log('Waiting for DOMContentLoaded...');
  document.addEventListener('DOMContentLoaded', main);
} else {
  console.log('DOM already loaded, starting main...');
  main();
}

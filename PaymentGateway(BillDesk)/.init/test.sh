#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ekyc-application-125058-126434/PaymentGateway(BillDesk)"
cd "$WORKSPACE"
export NODE_ENV=${NODE_ENV:-development}
# ensure vitest present in package.json devDependencies; merge if absent
node -e "const fs=require('fs');const p=fs.existsSync('package.json')?JSON.parse(fs.readFileSync('package.json')):{name:'paymentgateway-billdesk',private:true,version:'0.0.1',scripts:{}};p.devDependencies=p.devDependencies||{};if(!p.devDependencies.vitest){p.devDependencies.vitest='1.3.0';fs.writeFileSync('package.json',JSON.stringify(p,null,2));process.exit(0);}"
# ensure node_modules/vitest exists; if not, install non-interactively
if [ ! -x ./node_modules/.bin/vitest ]; then
  npm install --no-audit --no-fund --silent
fi
# write vitest config (CommonJS) and dummy test
cat > vitest.config.cjs <<'JS'
module.exports = { test: { globals: true, environment: 'node' } }
JS
mkdir -p test
cat > test/dummy.test.cjs <<'JS'
const { describe, it, expect } = require('vitest');
describe('dummy', ()=>{ it('works', ()=> expect(1+1).toBe(2)) })
JS
# run tests via project script to ensure local vitest is used
if node -e "const p=require('./package.json');console.log(Boolean(p.scripts && p.scripts.test))" >/dev/null 2>&1; then
  npm run test --silent || { echo "tests failed" >&2; exit 5; }
else
  ./node_modules/.bin/vitest --run --reporter=dot || { echo "vitest run failed" >&2; exit 6; }
fi

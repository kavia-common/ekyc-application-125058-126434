#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/home/kavia/workspace/code-generation/ekyc-application-125058-126434/PaymentGateway(BillDesk)"
cd "$WORKSPACE"
export NODE_ENV=${NODE_ENV:-development}
export PORT=${PORT:-3000}

# verify node >=18
NODE_MAJOR=$(node -p "process && process.version && process.version.split('.')[0].replace(/^v/,'')" 2>/dev/null || echo "")
if [ -z "${NODE_MAJOR}" ] || [ "${NODE_MAJOR}" -lt 18 ]; then echo "node >=18 required (found $(node -v 2>/dev/null || 'none'))" >&2; exit 4; fi

# Merge minimal deps into package.json without clobbering existing fields
node -e "const fs=require('fs');const p=fs.existsSync('package.json')?JSON.parse(fs.readFileSync('package.json')):{name:'paymentgateway-billdesk',private:true,version:'0.0.1',scripts:{}};p.dependencies=p.dependencies||{};p.devDependencies=p.devDependencies||{};const wantDeps={react:'18.2.0','react-dom':'18.2.0'};const wantDev={vite:'5.0.0',vitest:'1.3.0','sirv-cli':'2.0.0',eslint:'8.0.0',prettier:'2.0.0'};for(const k of Object.keys(wantDeps))if(!p.dependencies[k])p.dependencies[k]=wantDeps[k];for(const k of Object.keys(wantDev))if(!p.devDependencies[k])p.devDependencies[k]=wantDev[k];if(!p.scripts) p.scripts={};p.scripts.start=p.scripts.start||'vite';p.scripts.build=p.scripts.build||'vite build';p.scripts.test=p.scripts.test||'vitest --run --reporter=dot';fs.writeFileSync('package.json',JSON.stringify(p,null,2))"

# Prefer deterministic install when lockfile present
if [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund --no-color --silent
else
  npm install --no-audit --no-fund --no-color --silent
fi

# Verify project-local binaries: prefer npx --no-install; fallback to node_modules/.bin
if ! npx --no-install vite --version >/dev/null 2>&1; then
  [ -x ./node_modules/.bin/vite ] || { echo "vite not available locally" >&2; exit 6; }
fi

# sirv-cli binary may be exposed as sirv; check both
if ! npx --no-install sirv --version >/dev/null 2>&1; then
  [ -x ./node_modules/.bin/sirv ] || [ -x ./node_modules/.bin/sirv-cli ] || { echo "sirv-cli not available locally" >&2; exit 7; }
fi

# verify react installed
[ -d node_modules/react ] || { echo "react missing after install" >&2; npm ls react --depth=0 || true; exit 8; }

# final quick validations (versions printed minimally)
node -v >/dev/null 2>&1 || { echo "node not available" >&2; exit 9; }
npm -v >/dev/null 2>&1 || { echo "npm not available" >&2; exit 10; }

# Success
exit 0

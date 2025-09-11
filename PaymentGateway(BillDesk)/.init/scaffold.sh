#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ekyc-application-125058-126434/PaymentGateway(BillDesk)"
export NODE_ENV=${NODE_ENV:-development}
export PORT=${PORT:-3000}
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
[ -f package.json ] && exit 0
cat > package.json <<'JSON'
{
  "name": "paymentgateway-billdesk",
  "private": true,
  "version": "0.0.1",
  "scripts": {
    "start": "vite",
    "build": "vite build",
    "serve": "node ./scripts/serve.js",
    "test": "vitest --run --reporter=dot"
  }
}
JSON
mkdir -p src scripts && cat > index.html <<'HTML'
<!doctype html>
<html>
  <head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"><title>PaymentGateway</title></head>
  <body><div id="root"></div><script type="module" src="/src/main.jsx"></script></body>
</html>
HTML
cat > src/main.jsx <<'JS'
import React from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
createRoot(document.getElementById('root')).render(<App />)
JS
cat > src/App.jsx <<'JS'
import React from 'react'
export default function App(){return <div>PaymentGateway (BillDesk) - dev environment</div>}
JS
cat > scripts/serve.js <<'JS'
const { spawn } = require('child_process');
const port = process.env.PORT || 3000;
const sirv = './node_modules/.bin/sirv';
const args = ['dist', '--single', '--host', '127.0.0.1', '--port', String(port)];
const ps = spawn(sirv, args, { stdio: 'inherit' });
ps.on('exit', (c) => process.exit(c));
JS
cat > .gitignore <<'GIT'
node_modules/
dist/
build/
.env
GIT

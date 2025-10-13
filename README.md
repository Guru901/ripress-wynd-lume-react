# Rust + React minimal full-stack

## File structure

```
rust-react/
  Cargo.toml
  src/
    main.rs
  frontend/
    index.html
    package.json
    tsconfig.json
    vite.config.ts
    src/
      App.tsx
      main.tsx
  dist/                # created by `npm run build` in frontend/
  .gitignore
  README.md
```

## Backend (Rust, Axum)

- Run server:

```bash
cargo run
```

- Endpoints:

  - GET `/hello` → `"Hello from Ripress!"`

- Static files: serves `./dist/` at `/`.

## Frontend (Vite + React + TS)

- Install deps:

```bash
cd frontend && npm install
```

- Dev (proxied API to 3000):

```bash
npm run dev
```

- Build to `../dist`:

```bash
npm run build
```

## Build & Run end-to-end

```bash
# 1) Build frontend into root dist/
cd frontend
npm install
npm run build

# 2) Run backend serving dist/ and APIs
cd ..
cargo run
# Open http://localhost:3000
```

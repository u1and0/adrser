/work下のxlsxファイルをパースして、データを抽出します。
データをJSONとして配信し、ブラウザ上で検索し、表示します。

# Usage

```bash
$ ./adrser
```

Then access http://localhost:3333 on browser, check display JSON data.

# Installation

```bash
$ git clone https://github.com/u1and0/adrser.git
```

# Build

```bash
$ nim compile -d:release adrser.nim  # backend build
$ npx tsc -p static/tsconfig.json    # frontend build
```

# Requirement

```bash
$ nimble install jester xlsx
$ npm install --save-dev fzf
```

# Test

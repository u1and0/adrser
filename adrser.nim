#[
# /work下のxlsxファイルをパースして、タプルへ落とし込み、
# データを抽出して標準出力します。
]#
import
  std/strformat,
  std/os,
  std/strutils,
  xlsx

const
  ROOT = "/work"
  LIMIT = 10

type Address = tuple[
  要求番号,
  要求年月日,
  生産命令番号,
  輸送区間,
  送り先,
  物品名称,
  重量長さ,
  荷姿,
  要求元: string]

proc extractData(filename: string): Address =
  const sheetName = "入力画面"
  let table = parseExcel(filename)
  let rows = table[sheetName].
    toSeq(skipHeaders = true)[0 .. 20] # 20行までにデータが入っている
  var col: seq[string]
  for row in rows:
    col.add(row[4])
  return (
      要求番号: col[0],
      要求年月日: col[1],
      生産命令番号: col[5],
      輸送区間: col[6],
      送り先: col[11],
      物品名称: col[12],
      重量長さ: col[13],
      荷姿: col[14],
      要求元: col[2],
    )

when isMainModule:
  var
    i: int
    df: seq[Address]
  for f in walkDirRec(ROOT):
    if i >= LIMIT: break
    if f.contains("00-") and f.endsWith(".xlsx"): # *00-*.xlsx
      try:
        let data: Address = extractData(f)
        df.add(data)
        i+=1 # 解析できたファイルのみカウント
      except KeyError:
        echo &"Invarid file error: {f}"
        continue
      except:
        echo &"Parse Excel error: {f}"
        continue

  echo &"パース成功ファイル数: {i}\n"
  echo &"全データ: {df}"
  for d in df: echo d.要求番号 # 特定フィールドのみ表示

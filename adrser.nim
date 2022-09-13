#[
# /work下のxlsxファイルをパースして、タプルへ落とし込み、
# データを抽出して標準出力します。
]#
import
  system/iterators,
  std/json,
  std/os,
  std/strutils,
  std/strformat,
  xlsx,
  jester, htmlgen, asyncdispatch

type Address = object
  要求番号: string
  要求年月日: string
  生産命令番号: string
  輸送区間: string
  送り先: string
  物品名称: string
  重量長さ: string
  荷姿: string
  要求元: string

proc toSeq(self: Address): seq[string] =
  for i in self.fields(): result.add(i)

proc concat(self: Address): string =
  self.toSeq().join(" ").replace("\n", "")

proc toTable(self: seq[Address]): Table[string, Address] =
  for a in self: result[a.concat()] = a

proc checkData(self: seq[Address]) =
  echo &"パース成功ファイル数: {len(self)}\n"
  echo &"全データ: {self}"
  echo "特定フィールドのみ表示"
  for d in self: echo d.要求番号

  echo "一行につなげて表示"
  echo self[4].concat()

  echo "JSON化"
  let j = %* self.toTable()
  echo j.pretty()

proc newAddress(filename: string): Address =
  const sheetName = "入力画面"
  let table = parseExcel(filename)
  let rows = table[sheetName].
    toSeq(skipHeaders = true)[0 .. 20] # 20行までにデータが入っている
  var col: seq[string]
  for row in rows:
    col.add(row[4])
  return Address(
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

proc convertAddress(root: string, limit: int): seq[Address] =
  for f in walkDirRec(root):
    if len(result) >= limit: break
    let filePattern = f.contains("00-") and f.endsWith(".xlsx") # *00-*.xlsx
    if filePattern:
      try:
        let data: Address = newAddress(f)
        result.add(data) # 解析できたファイルのみ追加
      except KeyError:
        echo &"Invarid file error: {f}"
        continue
      except:
        echo &"Parse Excel error: {f}"
        continue

iterator convertAddress(root: string): Address =
  for f in walkDirRec(root):
    let filePattern = f.contains("00-") and f.endsWith(".xlsx") # *00-*.xlsx
    if filePattern:
      try:
        yield newAddress(f)
      except KeyError:
        echo &"Invarid file error: {f}"
        continue
      except:
        echo &"Parse Excel error: {f}"
        continue

var df: seq[Address]
const LIMIT = 10
for a in convertAddress("/work"):
  if len(df) >= LIMIT: break
  df.add(a)


router route:
  get "/":
    let j = %* df.toTable()
    df.checkData()
    resp(Http200, j.pretty(), contentType = "application/json")
  get "/get":
    resp h1("hello World")

# Server routing
proc main() =
  let settings = newSettings(port = Port(3333), staticDir = "static/")
  var jes = initJester(route, settings = settings)
  jes.serve()

when isMainModule:
  main()

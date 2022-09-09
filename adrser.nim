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
  std/tables,
  xlsx,
  jester

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

var df: seq[Address]

proc toSeq(self: Address): seq[string] =
  for i in self.fields():
    result.add(i)

proc concat(self: Address): string =
  self.toSeq().join(" ").replace("\n", "")

# type AddressObject = object

# proc objectile(self: Address): AddressObject =
#   let a = newTable()


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

proc convertAddress(root: string, limit: int) =
  for f in walkDirRec(root):
    if len(df) >= limit: break
    let filePattern = f.contains("00-") and f.endsWith(".xlsx") # *00-*.xlsx
    if filePattern:
      try:
        let data: Address = newAddress(f)
        yield data
        # df.add(data) # 解析できたファイルのみ追加
      except KeyError:
        echo &"Invarid file error: {f}"
        continue
      except:
        echo &"Parse Excel error: {f}"
        continue

proc aconv(): Future[seq[JsonNode]] {.async.} =
  convertAddress("/work", 1000)
  echo &"パース成功ファイル数: {len(df)}\n"
  echo &"全データ: {df}"
  echo "特定フィールドのみ表示"
  for d in df: echo d.要求番号

  echo "一行につなげて表示"
  echo df[4].concat()


  echo "JSON化"
  let j = %* df
  echo j.pretty()
  return j.await


router route:
  get "/":
    let j = await aconv()
    resp(Http200, j.pretty(), contentType = "application/json")

# Server routing
proc main() =
  let settings = newSettings(port = Port(3333))
  var jes = initJester(route, settings = settings)
  jes.serve()


when isMainModule:
  main()

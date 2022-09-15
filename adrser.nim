#[
# /work下のxlsxファイルをパースして、データを抽出します。
# データをJSONとして配信し、ブラウザ上で検索し、表示します。
#
# Usage
# $ ./adrser
# Then access http://localhost:3333 on browser, check display JSON data.
#
# With option
# $ ./adrser -l=10 -d=/path/to/xlsxdir
]#
import
  system/iterators,
  std/json,
  std/os,
  std/parseopt,
  std/sets,
  std/strutils,
  std/strformat,
  std/sugar,
  xlsx,
  jester, htmlgen, asyncdispatch

const
  VERSION = "v0.1.0"
  LIMIT = 100000
  ROOT = "/work"

proc printHelp() =
  echo &"""
/work下のxlsxファイルをパースして、データを抽出します。
データをJSONとして配信し、ブラウザ上で検索し、表示します。

Usage
$ ./adrser
Then access http://localhost:3333 on browser, check display JSON data.

With option
$ ./adrser -l=10 -d=/path/to/xlsxdir

Options:
  --limit, -l=[VALUE]     Change limit value (default {LIMIT})
  --dir, -d=[VALUE]       Change parse excel files directory (default {ROOT})
  --version, -v           Show version
  --help, -h              Show help
  """
  quit()

proc printVersion() =
  echo "adrser version: " & VERSION
  quit()

## Address: 住所録型
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

## toSeq(): Addressの値のみを出力してseqにする
func toSeq(self: Address): seq[string] =
  for i in self.fields(): # Addressの値のみ出力
    result.add(i)

## concat(): Addressの値のみを連結して一要素の文字列にする
func concat(self: Address): string =
  self.toSeq().join(" ").replace("\n", "")

## toTable(): seq[Address]を連結文字列のキーとAddressの値のTableにする
func toTable(self: seq[Address]): Table[string, Address] =
  for a in self:
    result[a.concat()] = a

## checkData(): echo data frame
proc checkData(self: seq[Address]) =
  echo &"パース成功ファイル数: {len(self)}\n"
  let j = %* self.toTable()
  echo j.pretty()

## newAddress(): parse excel file then export Address
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

## yieldFiles(): root下のマッチしたファイルのみyieldする
iterator yieldFiles(root: string): string =
  for f in walkDirRec(root):
    let filePattern = f.contains("00-") and f.endsWith(".xlsx") # *00-*.xlsx
    if filePattern:
      yield f

## df: All data parsed by excel files
var df: seq[Address]

## init(): initialize data
## parse command line options.
## parse xlsx by newAddress() in yielded file set.
proc init() =
  # Command line parse
  var # Default value
    limit = LIMIT
    root = ROOT
  for kind, key, val in getopt():
    case kind
    of cmdArgument: discard
    of cmdLongOption, cmdShortOption:
      case key
      of "help", "h": printHelp()
      of "version", "v": printVersion()
      of "limit", "l": limit = parseInt(val)
      of "dir", "d": root = val
    of cmdEnd: discard

  # Excel parse
  var fileset = collect:
    for f in yieldFiles(root): {f}
  for f in fileset:
    if len(df) >= limit: break
    try:
      let ad = newAddress(f)
      df.add(ad)
    except KeyError:
      echo &"Invarid file error: {f}"
      continue
    except:
      echo &"Parse Excel error: {f}"
      continue

router route:
  get "/": # Heart beat
    const msg = "Hello, this is adrser heart beeat monitor. Try access to /json, /search API"
    resp(Http200, msg, contentType = "application/json")
  get "/json": # JSON API
    let j = %* df.toTable()
    df.checkData()
    resp(Http200, j.pretty(), contentType = "application/json")
  get "/search": # Distribute search UI for browser
    let
      favicon = link(type = "image/png",
                  rel = "icon",
                  href = "/favicon.png")
      bootstrap = link(href = "https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css",
                    rel = "stylesheet",
                    crossorigin = "anonymous")
      head = head(favicon & bootstrap)

      searchForm = input(
          name = "search-form",
          id = "search-form",
          type = "text",
          placeholder = "検索キーワードを入力",
          size = "20",
          class = "hover",
        )
      searchResult = select(
          name = "search-result",
          id = "search-result",
          class = "form-select",
          size = "10",
        )
      searchContainer = `div`(searchForm, br(), searchResult)

      outputTable = table(
        class = "table table-striped table-hover",
        tr(
          td(style = "width:20%", "要求番号"),
          td(span(id = "要求番号")),
        ),
        tr(td("要求年月日"), td(span(id = "要求年月日"))),
        tr(td("要求番号"), td(span(id = "要求番号"))),
        tr(td("生産命令番号"), td(span(id = "生産命令番号"))),
        tr(td("輸送区間"), td(span(id = "輸送区間"))),
        tr(
          td("送り先"),
          td(textarea(id = "送り先", readonly = "",
            style = "width:400px; height:100px;")),
          ),
        tr(td("物品名称"), td(span(id = "物品名称"))),
        tr(td("重量長さ"), td(span(id = "重量長さ"))),
        tr(td("荷姿"), td(span(id = "荷姿"))),
        tr(td("要求元"), td(span(id = "要求元"))),
      )
      js = script(type = "module", src = "/dist/main.js")
      body = searchContainer & outputTable & js

      html = head & body
    resp(Http200, html)
    # Same as...
    #
    # resp """
    #   <div>
    #     <input name="search-form" id="search-form" type="text" placeholder="検索キーワードを入力" size="20" class="hover"><br>
    #     <select name="search-result" id="search-result" class="select-box" size="10"></select>
    #   </div>
    #   <table>
    #   <tr>
    #     <td> key </td>
    #     <td> span(id="...") </td>
    #   </tr>
    #   </table>
    #   <script type="module" src="/dist/main.js"></script>
    #   """

## main(): Server routing
proc main() =
  let settings = newSettings(port = Port(3333), staticDir = "static/")
  var jes = initJester(route, settings = settings)
  jes.serve()

when isMainModule:
  init()
  main()

import
  std/strformat,
  std/os,
  std/strutils,
  xlsx

const root = "/mnt/sec/"

type Address = tuple[id, date, seqtion: string]

proc extractData(filename: string): Address =
  const sheetName = "入力画面"
  let table = parseExcel(filename)
  let rows = table[sheetName].toSeq(skipHeaders = true)[0 .. 20]
  var col: seq[string]
  for row in rows:
    col.add(row[4])
  let a: Address = (col[0], col[1], col[2])
  return a

when isMainModule:
  var
    i: int
    df: seq[Address]
    data: Address
  for f in walkDirRec(root):
    if i >= 10: break
    if f.endsWith(".xlsx") and f.contains("00-"):
      try:
        data = extractData(f)
      except KeyError:
        echo &"Invarid file error: {f}"
        continue
      except:
        echo &"Parse Excel error: {f}"
        continue
      echo &"success: {f}"
      df.add(data)
      i+=1 # 解析できたファイルのみカウント

  echo &"ファイル数: {i}\n"

  echo df


  # echo "///住所///\n" & rows[18][4]

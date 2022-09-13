/* Jsonでデータを取得し、FZFで要素の検索、表示するモジュール
 *
 * # for build main.js
 * $ sudo npm i --save-dev --no-bin-links fzf typescript
 *
 * # for build main.js
 * $ cd /path/to/project/static  # tsconfig.jsonのある階層
 * $ npx tsc
*/

import { Fzf } from "../node_modules/fzf/dist/fzf.es.js";
const root: URL = new URL(window.location.href);
const url: string = root.origin;
let addresses: Addresses;

main();

type Addresses = Map<string, Address>;
type Address = {
  "要求番号": string;
  "要求年月日": string;
  "生産命令番号": string;
  "輸送区間": string;
  "送り先": string;
  "物品名称": string;
  "重量長さ": string;
  "荷姿": string;
  "要求元": string;
};

async function main() {
  addresses = await fetchPath(url + "/json");
  console.log(addresses);
}

const inputElem: HTMLElement = document.getElementById("search-form");
const outputElem = document.getElementById("search-result");
// formへの入力があるたびにoption書き換え
inputElem?.addEventListener("keyup", () => {
  while (outputElem?.firstChild) { // clear option
    outputElem.removeChild(outputElem.firstChild);
  }
  // Map.keys() メソッドがなぜか機能しないのでとりあえずObject.keys()使った。
  const result: string[] = fzfSearchList(
    Object.keys(addresses),
    inputElem.value,
  );
  console.log(result); // 結果をコンソールに表示
  // 結果をresult要素へ表示
  result.forEach((key: string) => {
    const option = document.createElement("option");
    option.text = key;
    option.value = key;
    outputElem?.append(option);
  });
});

function fzfSearchList(list: string[], keyword: string): string[] {
  const fzf = new Fzf(list);
  const entries = fzf.find(keyword);
  const ranking: string[] = entries.map((entry: Fzf) => entry.item);
  return ranking;
}

async function fetchPath(url: string): Promise<any> {
  return await fetch(url)
    .then((response) => {
      return response.json();
    })
    .catch((response) => {
      return Promise.reject(
        new Error(`{${response.status}: ${response.statusText}`),
      );
    });
}

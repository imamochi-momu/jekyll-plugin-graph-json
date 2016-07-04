# jekyll-plugin-graph-json

グラフ出力用プラグイン。
個人的に作ったもののため、他の使い道は多分ない。

## インストール

`<Jekyll Dir>/plugins/graph-json.rb`を突っ込むだけ。

## オプション

`_config.yml`には以下の設定が可能。

```yaml
graph-json:
  path: [String]
  level_undefined: [String]
```

- graph-json/path jsonファイルを出力する
- graph-json/level_undefined レベル未登録の場合に出力する内容

デフォルト値は以下の設定。

```yaml
graph-json:
  path: "graph.json"
  level_undefined: "レベル未登録"
```

## 使い方

jekyllにより勝手に出力される。お好みでD3.jsなどに食わせてあげる。

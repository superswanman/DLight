# DLight - Inline evaluation plugin

English follows Japanese

## これは何？

![Sample](http://i.imgur.com/WhYTpAH.gif)

## インストール

"DLight.dproj"を開き、プロジェクトマネージャの"DLight.bpl"上で右クリックし、インストールを選択して下さい。

## 更新履歴

- Ver.0.0.3
  - マルチバイト文字の横幅が適切に計算できないなかったのを修正

- Ver.0.0.2
  - 10 Seattleに対応
  - 10.1 Berlin Starter Editionに対応(監視式のみ)
  - 特定条件下でのデッドロックと特定プラットフォーム下のデバッガでしか動かない問題を修正

- Ver.0.0.1
  - 初回リリース

## 注意点

現状では拙作の16進数表示プラグイン（内のデバッガビジュアライザ）と相性が悪いです。
確認した範囲ではエラー等は出ていませんが、値の表示がおかしくなる場合があります。

## ライセンス

このプラグインは明示してある場合を除き、MITライセンスです。
詳しくはLICENSEファイルをお読み下さい。

このプラグインは[Delphi Detours Library](https://github.com/MahdiSafsafi/delphi-detours-library)を使用しています。
Delphi Detours LibraryはMozilla Public License Version 1.1で提供されています。

## Installation

1. Open "DLight.dproj"
2. Right click "DLight.bpl" on project manager
3. Choose "Install" menu

## History

- Ver.0.0.3
  - Fix wrong multibyte string width calculation

- Ver.0.0.2
  - Add support for 10 Seattle
  - Add Support for 10.1 Berlin Starter Edition (Only watch expressions)
  - Fix some bugs

- Ver.0.0.1
  - First release

## License

This plugin is released under the MIT License, see LICENSE file.

[Delphi Detours Library](https://github.com/MahdiSafsafi/delphi-detours-library) is licensed under Mozilla Public License Version 1.1.

# Misc.
Delphinus-Support

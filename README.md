# Craft Memory

## 概要
シンプルな思い出アルバムアプリは、カップルや夫婦、友達同士が相手の誕生日などの特別な日にアルバを作成する際に役立つアプリです。

ユーザーは日付、写真、出来事をリストごとに管理することができます。

多くの写真がある中で、その日の内容を全て覚えておくことは難しいですが、

このアプリを使用することで写真とそれに付随する思い出を選別し、メモとして活用することが可能です。

## デモ動画
//ここにURLを追加する

一連の流れを紹介したデモ動画です。

## 特徴
* シンプルなインターフェースと直感的な操作性とすることで、使いやすさを追求しました。
* 日付ごとに写真と出来事をリスト化することで、思い出を管理しやすくしました。
* 写真一覧ページでは、日付が付随された写真をGridViewとして表示し、視覚的に思い出を蘇らせることができます。

## 機能一覧
* ユーザー登録、ログイン機能
  * パスワード再設定機能
* リスト画面
  * 写真拡大機能
  * 削除機能
    * 確認メッセージ表示・非表示機能
  * 編集機能
* 登録画面
  * 画像登録
  * 日付登録
  * テキスト登録
  * 情報不足時の登録不可機能
* 写真一覧機能
  * 日付付き写真一覧表示機能
  * 写真拡大機能
* チュートリアル機能

## 使用技術
* Flutter 3.10.0
* Firebase
  * Cloud Firestore 4.5.0
  * Storage 11.1.0
  * Authentication 4.2.2

## 主要コンポーネント
* main.dart
  * メイン画面のUI構築、アプリの初期化、ルートウィジェットの構築、認証状態の監視を行なっているクラスです。
* item.dart
  * アプリ内の個々のアイテムを表すためのデータモデル
* photo_library.dart
  * 日付が付随された全ての写真をGridViewとして表示するクラス
* login.dart
  * ユーザーがログインするため、またパスワード再設定画面に遷移するためのクラスです。
* sign_up.dart
  * 新しいユーザーアカウントを作成するためのクラスです。
* forgot_password.dart
  * パスワードを忘れたユーザーが再設定を行うためのクラスです。

## 困難と解決策
* 削除したリスト以降の項目のインデックスが変更されるため、削除後に正しくデータを参照できなかった。
  * List<Item>を使用して、リストの各項目をItemオブジェクトとして格納しています。
 　　　　　　これにより、各項目の関連する情報をまとめて管理することができます。

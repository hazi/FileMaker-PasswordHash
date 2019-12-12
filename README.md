# FileMaker PasswordHash

UNIX Crypt implemented with FileMaker custom functions

このプロジェクトはUNIXのパスワードハッシュ化（復号できない暗号化）アルゴリズム（crypt）を
FileMakerのカスタム関数実装に置き換えたものです。

## 利用方法

`custom_functions` ディレクトリ内に関数のテキストファイルがあります。
下記のファイルを上から順に登録してください。

- AsciiFilter.fmfn
- PasswordSaltGenerate.fmfn
- PasswordHash_Round.fmfn
- PasswordHash.fmfn
- PasswordVerify.fmfn

`PasswordHash_DEBUG.fmfn` は通常利用しません。


### 情報登録

ユーザーのパスワード入力を受けた後、変数などを通じて `PasswordHash` 関数にパスワードを渡します

```java
// $password にユーザー入力値のパスワードが格納されている例
PasswordHash($password; ""; "") //=> $6f$AeV5CacT$1NTsNCi$a/oyZR8su9MLQuXc1dgvWo4oPyZCSt237LZ4bbPybsIdgv6bvazJcHilcpfBP337gQKXSf4Vr/aFrpNwwcGweg
```

`PasswordHash` の戻り値（ハッシュ値）をユーザーの認証情報として適切なフィールドに保存します。
戻り値が `?` から始まるエラーである可能性があります。その場合その値を保存するのは危険です。
必ず、チェックしてから保存するようにしてください。

```java
Let(
  ~hash = PasswordHash($password; ""; "");
  Case(
    Left(~hash; 1) = "?";
    "ERROR: " & ~hash;
    "Success!"
  )
)
```

パスワードに使用できない文字が含まれていないかチェックしたい場合は `AsciiFilter` を利用してください。

```java
If(
  Exact(AsciiFilter($password; $password));
  "PASS";
  "FAIL"
)
```

### 認証

認証時に入力を受けたパスワードと、すでに登録されているハッシュ値を使って認証を行います

```java
// $password にユーザー入力値のパスワード、User::hash にハッシュ値が格納されている例
Let(
  ~result = PasswordVerify($password; User::hash);
  Case(
    Exact(~result; True); "PASS";
    Exact(~result; False); "FAIL";
    "ERROR"
  )
)
```

必ず `Exact` で `True` が帰ってきているか検証してください。
`PasswordVerify` の戻り値をそのまま `If` で利用すると、エラー時の `?` も `True` と判断され、認証が正しく行えません。

## 実装詳細

残念ながら現在のところUNIX実装との互換性は実現していませんが、ほぼ同様のロジックを利用しています。
それを検証する為に、Ruby実装である [unix-crypt](https://github.com/mogest/unix-crypt) のFileMakerで実装不可能な部分のみを置き換えた実装を作成し、検証しています。

Rubyの実装は[crypt6fm_rubyディレクトリ](./crypt6fm_ruby)に設置されています。
下記の方法で実行可能です。

```powershell
$ cd crypt6fm_ruby
$ bundle install
$ rake run PASSWORD="10000round" ROUND="10000" SALT="d7NNUNKUfiL/vaP4"
```

DEBUGフラグを与えることで、`PasswordHash_DEBUG`関数と同様に途中経過のログを見ることができます。

```powershell
$ rake run DEBUG=1 PASSWORD="10000round" ROUND="10000" SALT="d7NNUNKUfiL/vaP4"
```

## コラボレーション

- リポジトリをフォークし、そのリポジトリのブランチを元にPull requestを作成してください。
- `spec.fmp12` ファイルを変更した後はXMLスキーマ情報をUTF-8, LFに変換してコミットしてください（FileMaker Pro 18 Advanced以降必須）。
- Issueでのご指摘受け付けていますので、お気軽にご連絡ください。
- 英語化などのご協力も募集中です。

## License

Licensed under the [BSD license](./LICENSE).


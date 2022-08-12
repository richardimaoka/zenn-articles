## 5. (Optional) TypeScript の静的型チェックによって EmailAddress に変換できない形式の string をエラーとして検出する

本チュートリアル[「2. graphql-scalars を field 型に使った際の動作確認」](#2-graphql-scalars%E3%82%92field%E5%9E%8B%E3%81%AB%E4%BD%BF%E3%81%A3%E3%81%9F%E9%9A%9B%E3%81%AE%E5%8B%95%E4%BD%9C%E7%A2%BA%E8%AA%8D)の最後で、以下のように記載しました。

:::note info
TypeScript の静的型チェックによって EmailAddress に変換できない形式の string をエラーとして検出するには、このチュートリアルの 5. および 6. で紹介する独自型の定義を使ったテクニックが必要です。
:::

ここからは、そのテクニックを実際に見ていきます。なお、以下の手順を作成するに当たり[Wantedly Engineer Blog - graphql-codegen と Nominal Typing(Branded Type) で Custom Scalar をちょっといい感じにする](https://en-jp.wantedly.com/companies/wantedly/post_articles/387161)を参考にしました。

:large_orange_diamond: Action: 以下のコマンドを入力してください。

```shell
git apply patches/2aa8329.patch # EmailAddressString type
```

<details><summary>:white_check_mark: Result: 上記コマンドで生成されるsrc/myTypes.ts</summary><div>

`str is EmailAddressString` となっているのは、TypeScript の[type predicates](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#using-type-predicates)です。

```typescript:src/myTypes.ts
export type EmailAddressString = string & { __type: "EmailAddressString" };

export const isEmailAddressString = (
  str: string
): str is EmailAddressString => {
  const EMAIL_ADDRESS_REGEX =
    /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;

  return EMAIL_ADDRESS_REGEX.test(str);
};
```

---

</div></details>

それでは、定義した EmailAddressString 型を、graphql.ts の中で import する設定を行いましょう。graphql.ts は GraphQL Codege によって自動生成されるので、ひと工夫必要です。

:large_orange_diamond: Action: 以下のコマンドを入力してください。

```shell
npm install --save-dev @graphql-codegen/add
git apply patches/e6f57b6.patch # Use EmailAddressString in codegen.yml
```

<details><summary>:white_check_mark: Result: 上記コマンドで更新されるconfig.yml</summary><div>

```diff:config.yml
     plugins:
       - "typescript"
       - "typescript-resolvers"
+      - "add":
+          content: "import * as myTypes from '../myTypes'"
     config:
       avoidOptionals: true
       scalars:
-        EmailAddress: string
+        EmailAddress: myTypes.EmailAddressString
 hooks:
   afterOneFileWrite:
     - npx prettier --write
```

---

</div></details>

<details><summary>:white_check_mark: Result: config.ymlに伴って自動更新されるgraphql.ts</summary><div>

```diff:server/src/generated/graphql.ts
+import * as myTypes from "../myTypes";
 export type Maybe<T> = T | null;
 export type InputMaybe<T> = Maybe<T>;
 export type Exact<T extends { [key: string]: unknown }> = {
@@ -25,7 +26,7 @@ export type Scalars = {
   Int: number;
   Float: number;
   CountryCode: any;
-  EmailAddress: string;
+  EmailAddress: myTypes.EmailAddressString;
 };
```

---

</div></details>

:large_orange_diamond: Action: 以下のコマンドを入力してください。

```shell
git apply patches/fdf1ea5.patch # emailAddress does not allow plain string
```

<details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

```diff:server/src/index.ts
       return parent.name;
     },
     emailAddress(parent, _args, _context, _info) {
-      return parent.emailAddress;
+      return "jason.summerwinnter@gmail.com";
     },
     country(parent, _args, _context, _info) {
       return parent.country;
```

---

</div></details>

<details><summary>:white_check_mark: Result: TypeScript型チェックによるエラーの確認</summary><div>

ただの String 型では、たとえ正しいメールアドレスのフォーマットであっても型エラーになります。

![2022-08-09_06h26_31.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/39ef6a64-8bc1-4c66-3170-ce9cc955c53a.png)

```
graphql.ts(193, 3): The expected type comes from property 'emailAddress' which is declared here on type 'PersonResolvers<LoadingDataContext, Person>'
```

---

</div></details>

それでは型チェックエラーを解決しましょう。

```shell
git apply patches/8b4740d.patch # explicit type checking by type predicates
```

<details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

下記の変更によって、明示的に isEmailAddress 関数を呼んで、string がただの string ではなく、EmailAddressString であることをチェックしています。

```diff:server/src/index.ts
     emailAddress(parent, _args, _context, _info) {
-      return "jason.summerwinnter@gmail.com";
+      const email = "jason.summerwinnter@gmail.com";
+      if (isEmailAddressString(email)) {
+        return email;
+      } else {
+        throw new Error(
+          "Internal Error occurred: could not retrieve emailAddress"
+        );
+      }
     },
```

`throw new Error` としているので、結局ランタイムエラーになるだけではないか？と思うかもしれませんが、強制的に「isEmailAddressString」を呼び出さざるをえないところがポイントで、ソースコードのどこで型チェックを行うか、プログラマが事前に考えて明示的に記述するようになります。

---

</div></details>

これで、TypeScript 型チェックを効かせてメールアドレスのフォーマットをチェックできるようになりました！

:::note info
この状態では、「どこかでメールアドレスのフォーマットチェック(isEmailAddressString 関数)」を呼び出すことによって、静的型チェックを通すことができます。すなわち、意図せぬ値を GraphQL custom scalar の validator に渡してしまってからエラーに気づくのではなく、どこで isEmailAddressString を呼ぶか事前に判断することになります。
:::

それでは、データベースからの呼び出し部分付近で isEmailAddressString 関数の呼び出しをする想定で、コードを更新しましょう。

:large_orange_diamond: Action: 以下のコマンドを入力してください。

```shell
git apply patches/d065fdd.patch # email is validated near the database
```

<details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

```diff:server/src/index.ts
+const loadEmailDeepInsideServer = (): EmailAddressString => {
+  // somewhere like database, deep inside the server side...
+  const valueFromDatabase = "jason.summerwinnter@gmail.com";
+  if (isEmailAddressString(valueFromDatabase)) {
+    return valueFromDatabase;
+  } else {
+    throw new TypeError(
+      `value from database = ${valueFromDatabase} is not a valid email address`
+    );
+  }
+};
+
 interface LoadingDataContext {
   Query: Query;
 }
@@ -25,11 +37,13 @@ const resolvers: Resolvers<LoadingDataContext> = {
     name(parent, _args, _context, _info) {
       return parent.name;
     },
-    emailAddress(parent, _args, _context, _info) {
-      const email = "jason.summerwinnter@gmail.com";
-      if (isEmailAddressString(email)) {
+    emailAddress(_parent, _args, _context, _info) {
+      try {
+        const email = loadEmailDeepInsideServer();
         return email;
-      } else {
+      } catch (error) {
+        //the server log only, not exposing the internal error detail to the API caller
+        console.log(error);
         throw new Error(
           "Internal Error occurred: could not retrieve emailAddress"
         );
```

---

</div></details>

:large_orange_diamond: Action: 以下のコマンドを入力してください。

```shell
git apply patches/80dda3e.patch # wrong format email address
```

<details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

```diff:server/src/index.ts
 const loadEmailDeepInsideServer = (): EmailAddressString => {
   // somewhere like database, deep inside the server side...
-  const valueFromDatabase = "jason.summerwinnter@gmail.com";
+  const valueFromDatabase = "jason.summerwinnter@@@@gmail.com";
   if (isEmailAddressString(valueFromDatabase)) {
     return valueFromDatabase;
   } else {
```

---

</div></details>

:large_orange_diamond: Action: Apollo Studio Explorer からクエリを実行してください

<details><summary>:white_check_mark: Result: ランタイムエラーの確認</summary><div>

![2022-08-09_06h48_09.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/159e7785-ea99-f907-7c52-5eac82fdfac9.png)

TypeError となっていますが、以下は Apollo Server のログに出力されるランタイム・エラーです

```
TypeError: value from database = jason.summerwinnter@@@@gmail.com is not a valid email address
```

---

</div></details>

```shell
git apply patches/749a10a.patch # correct email format
```

<details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

```diff:server/src/index.ts
 const loadEmailDeepInsideServer = (): EmailAddressString => {
   // somewhere like database, deep inside the server side...
-  const valueFromDatabase = "jason.summerwinnter@@@@gmail.com";
+  const valueFromDatabase = "jason.summerwinnter@gmail.com";
   if (isEmailAddressString(valueFromDatabase)) {
     return valueFromDatabase;
   } else {
```

---

</div></details>

最後に、ここまで 5. で行った変更をもとに戻しましょう。

:large_orange_diamond: Action: 以下のコマンドを入力してください。

```shell
git apply patches/6d06b65.patch # revert back index.ts
```

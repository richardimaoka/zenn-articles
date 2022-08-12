## 4. graphql-scalars を argument 型に使った際の動作確認

ここまでは field の型に custom scalar を使う方法を見てきましたが、ここからは argument 型の場合を見てみましょう。search という field を追加し、その argument で custom scalar である CountryCode を使います。

:large_orange_diamond: Action: 以下のコマンドを入力してください。

```shell
git apply patches/b1acf0c.patch # add CountryCode to schema.gql
git apply patches/09bc748.patch # add country to index.ts
git apply patches/6c02fe8.patch # update data/Query.json
```

<details><summary>:white_check_mark: Result: 上記コマンドで更新される schema.gql</summary><div>

```diff:server/schema.gql
scalar EmailAddress
+ scalar CountryCode

type Person {
  emailAddress: EmailAddress
  name: String
+   country: CountryCode
}

type Query {
  me: Person
+  search(country: CountryCode): [Person]
}
```

---

</div></details>

<details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

```diff:server/src/index.ts
import { ApolloServer, gql } from "apollo-server";
import * as fs from "fs";
- import { EmailAddressResolver } from "graphql-scalars";
+ import { CountryCodeResolver, EmailAddressResolver } from "graphql-scalars";
import { Query, Resolvers } from "./generated/graphql";

const typeDefs = gql`
@@ -16,6 +16,9 @@ const resolvers: Resolvers<LoadingDataContext> = {
    me(_parent, _args, context, _info) {
      return context.Query.me;
    },
+     search(_parent, _args, context, _info) {
+       return context.Query.search;
+     },
  },
  Person: {
    name(parent, _args, _context, _info) {
@@ -24,8 +27,12 @@ const resolvers: Resolvers<LoadingDataContext> = {
    emailAddress(parent, _args, _context, _info) {
      return parent.emailAddress;
    },
+     country(parent, _args, _context, _info) {
+       return parent.country;
+     },
  },
  EmailAddress: EmailAddressResolver,
+   CountryCode: CountryCodeResolver,
};

const readJsonFile = async (relativeFileName: string): Promise<any> => {
```

---

</div></details>

<details><summary>:white_check_mark: Result: 上記コマンドで更新される Query.json</summary><div>

```diff:server/data/Query.json
{
  "me": {
    "emailAddress": "jason.summerwinnter@gmail.com",
-     "name": "Jason Summerwinter"
-   }
+     "name": "Jason Summerwinter",
+     "country": "JP"
+   },
+   "search": [
+     {
+       "emailAddress": "jason.fallspring@gmail.com",
+       "name": "Jason FallSpring",
+       "country": "JP"
+     },
+     {
+       "emailAddress": "kate.heartspadediamond@gmail.com",
+       "name": "Kate HeartSpadeDiamond",
+       "country": "JP"
+     },
+     {
+       "emailAddress": "yosuke.kishidamax@gmail.com",
+       "name": "Yosuke KishidaMax",
+       "country": "JP"
+     },
+     {
+       "emailAddress": "bob.BobbDobb@gmail.com",
+       "name": "Bob BobbDobb",
+       "country": "JP"
+     }
+   ]
}
```

---

</div></details>

:large_orange_diamond: Action: Apollo Studio Explorer からクエリを実行して、動作を確認してください。

<details><summary>:white_check_mark: Result: Apollo Studio Explorerからクエリの実行</summary><div>

![2022-08-09_06h00_03.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/6ad07873-8c2e-123c-7632-6f5b73654089.png)

---

</div></details>

<details><summary>:white_check_mark: Apollo Studio Explorerで不正な形式のCountryCodeを渡して、ランタイムエラーを確認</summary><div>

country に CountryCode ではない不正な形式の String を渡すと、静的型チェックエラーではなくランタイムエラーになります

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/cd3991a8-5e3c-6734-7340-57e5bded3cd7.png)

---

</div></details>

<details><summary>:white_check_mark: Apollo Studio Explorerで、Int型の値を渡してランタイムエラーを確認</summary><div>

country に 10 を渡しても、静的型チェックエラーではなくランタイムエラーになります

![2022-08-09_06h07_46.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/49dc3907-fb5f-377c-2d43-7e882ef63279.png)

---

</div></details>

Apollo Studio Explorer のクエリエディタでは、クエリ・リテラルの静的型チェックエラーは働きません。argument で custom scalar を使ったときの動作がこれで確認できました。

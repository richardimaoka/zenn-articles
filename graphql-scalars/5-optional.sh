#!/bin/sh

cd "$(dirname "$0")" || exit # REMOVE THIS IN aggregate.sh
cd ../ || exit               # REMOVE THIS IN aggregate.sh - cd to the git repository root


# ## 5. (Optional) TypeScriptの静的型チェックによってEmailAddressに変換できない形式のstringをエラーとして検出する

# 本チュートリアル[「2. graphql-scalarsをfield型に使った際の動作確認」](#2-graphql-scalars%E3%82%92field%E5%9E%8B%E3%81%AB%E4%BD%BF%E3%81%A3%E3%81%9F%E9%9A%9B%E3%81%AE%E5%8B%95%E4%BD%9C%E7%A2%BA%E8%AA%8D)の最後で、TypeScriptの型チェックを効かせて不正なメールアドレスの形式を検出するには、独自型の利用が必要なことを述べました。以下ではそのテクニックを実際に見ていきます。

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
git apply patches/2aa8329.patch # EmailAddressString type
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで生成されるsrc/myTypes.ts。</summary><div>

# ```typescript:src/myTypes.ts
# export type EmailAddressString = string & { __type: "EmailAddressString" };

# export const isEmailAddressString = (
#   str: string
# ): str is EmailAddressString => {
#   const EMAIL_ADDRESS_REGEX =
#     /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;

#   return EMAIL_ADDRESS_REGEX.test(str);
# };
# ```

# ---

# </div></details>

# それでは、定義したEmailAddressString型を自動生成されるgraphql.tsの中で利用する設定を行いましょう。

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
npm install --save-dev @graphql-codegen/add
git apply patches/e6f57b6.patch # Use EmailAddressString in codegen.yml
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで更新されるconfig.yml</summary><div>

# ```diff:config.yml     
#      plugins:
#        - "typescript"
#        - "typescript-resolvers"
# +      - "add":
# +          content: "import * as myTypes from '../myTypes'"
#      config:
#        avoidOptionals: true
#        scalars:
# -        EmailAddress: string
# +        EmailAddress: myTypes.EmailAddressString
#  hooks:
#    afterOneFileWrite:
#      - npx prettier --write
# ```

# ---

# </div></details>


# <details><summary>:white_check_mark: Result: config.ymlに伴って自動更新されるgraphql.ts</summary><div>

# ```diff:server/src/generated/graphql.ts
# +import * as myTypes from "../myTypes";
#  export type Maybe<T> = T | null;
#  export type InputMaybe<T> = Maybe<T>;
#  export type Exact<T extends { [key: string]: unknown }> = {
# @@ -25,7 +26,7 @@ export type Scalars = {
#    Int: number;
#    Float: number;
#    CountryCode: any;
# -  EmailAddress: string;
# +  EmailAddress: myTypes.EmailAddressString;
#  };
# ```

# ---

# ---

# </div></details>


# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
git apply patches/fdf1ea5.patch # emailAddress does not allow plain string
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

# ```diff:server/src/index.ts
#        return parent.name;
#      },
#      emailAddress(parent, _args, _context, _info) {
# -      return parent.emailAddress;
# +      return "jason.summerwinnter@gmail.com";
#      },
#      country(parent, _args, _context, _info) {
#        return parent.country;
# ```

# ---

# </div></details>

# <details><summary>:white_check_mark: Result: TypeScript型チェックによるエラーの確認</summary><div>

# ただのString型では、たとえ正しいメールアドレスのフォーマットであっても型エラーになります。

# ![2022-08-09_06h26_31.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/39ef6a64-8bc1-4c66-3170-ce9cc955c53a.png)

# ```
# graphql.ts(193, 3): The expected type comes from property 'emailAddress' which is declared here on type 'PersonResolvers<LoadingDataContext, Person>'
# ```

# ---

# </div></details>

# これで、TypeScript型チェックを効かせてメールアドレスのフォーマットをチェックできるようになりました！

# :::note info
# この状態では、「どこかでメールアドレスのフォーマットチェック(isEmailAddressString関数)」を呼び出すことによって、静的型チェックを通すことができます。すなわち、意図せぬ値をGraphQL custom scalarのvalidatorに渡してしまってからエラーに気づくのではなく、どこでisEmailAddressStringを呼ぶか事前に判断することになります。
# :::

# それでは、データベースからの呼び出し部分付近でisEmailAddressString関数の呼び出しをする想定で、コードを更新しましょう。

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
git apply patches/8d95b4f.patch # email is validated near the database
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

# ```diff:server/src/index.ts
#  import * as fs from "fs";
#  import { CountryCodeResolver, EmailAddressResolver } from "graphql-scalars";
#  import { Query, Resolvers } from "./generated/graphql";
# +import { EmailAddressString, isEmailAddressString } from "./myTypes";
 
#  const typeDefs = gql`
#    ${fs.readFileSync(__dirname.concat("/../schema.gql"), "utf8")}
#  `;
 
# +const loadEmailDeepInsideServer = (): EmailAddressString => {
# +  // somewhere like database, deep inside the server side...
# +  const valueFromDatabase = "jason.summerwinnter@gmail.com";
# +  if (isEmailAddressString(valueFromDatabase)) {
# +    return valueFromDatabase;
# +  } else {
# +    throw new TypeError(
# +      `value from database = ${valueFromDatabase} is not a valid email address`
# +    );
# +  }
# +};
# +
#  interface LoadingDataContext {
#    Query: Query;
#  }
# @@ -24,8 +37,14 @@ const resolvers: Resolvers<LoadingDataContext> = {
#      name(parent, _args, _context, _info) {
#        return parent.name;
#      },
# -    emailAddress(parent, _args, _context, _info) {
# -      return "jason.summerwinnter@gmail.com";
# +    emailAddress(_parent, _args, _context, _info) {
# +      try {
# +        const email = loadEmailDeepInsideServer();
# +        return email;
# +      } catch (error) {
# +        console.log(error);
# +        throw new Error("An internal error occurred!");
# +      }
#      },
#      country(parent, _args, _context, _info) {
#        return parent.country;
# ```

# ---

# </div></details>

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
git apply patches/6e3ea45.patch # wrong format email address
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

# ```diff:server/src/index.ts
#  const loadEmailDeepInsideServer = (): EmailAddressString => {
#    // somewhere like database, deep inside the server side...
# -  const valueFromDatabase = "jason.summerwinnter@gmail.com";
# +  const valueFromDatabase = "jason.summerwinnter@@@@gmail.com";
#    if (isEmailAddressString(valueFromDatabase)) {
#      return valueFromDatabase;
#    } else {
# ```

# ---

# </div></details>

# :large_orange_diamond: Action: Apollo Studio Explorerからクエリを実行してください

# <details><summary>:white_check_mark: Result: ランタイムエラーの確認</summary><div>

# ![2022-08-09_06h48_09.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/159e7785-ea99-f907-7c52-5eac82fdfac9.png)

# TypeError となっていますが、以下はApollo Serverのログに出力されるランタイム・エラーです

# ```
# TypeError: value from database = jason.summerwinnter@@@@gmail.com is not a valid email address      
# ```

# ---

# </div></details>


# ```shell
git apply patches/f28a02e.patch # correct email format
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

# ```diff:server/src/index.ts
#  const loadEmailDeepInsideServer = (): EmailAddressString => {
#    // somewhere like database, deep inside the server side...
# -  const valueFromDatabase = "jason.summerwinnter@@@@gmail.com";
# +  const valueFromDatabase = "jason.summerwinnter@gmail.com";
#    if (isEmailAddressString(valueFromDatabase)) {
#      return valueFromDatabase;
#    } else {
# ```

# ---

# </div></details>

# 最後に、ここまで5. で行った変更をもとに戻しましょう。

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
git apply patches/3420df7.patch # revert back index.ts
# ```

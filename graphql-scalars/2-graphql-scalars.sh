#!/bin/sh

cd "$(dirname "$0")" || exit # REMOVE THIS IN aggregate.sh
cd ../ || exit               # REMOVE THIS IN aggregate.sh - cd to the git repository root

# ## 2. graphql-scalarsをfield型に使った際の動作確認

# :large_orange_diamond: Action: 新しいターミナルを立ち上げてください。

# ![アートボード 17.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/128eb33f-2f1f-b06c-3267-3714bc867e52.png)

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```:terminal
# shellcheck disable=SC2164 # REMOVE THIS IN aggregate.sh
(cd server && npm install graphql-scalars)
# ```

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
git apply patches/e7c78aa.patch # update schema.gql
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される schema.gql</summary><div>

# ```graphql:server/schema.gql
# scalar EmailAddress

# type Person {
#   emailAddress: EmailAddress
#   name: String
# }

# type Query {
#   me: Person
# }
# ```

# ---

# </div></details>

# :white_check_mark: Result: この状態ではエラーが出ます

# ```:terminal
Error: Query.hello defined in resolvers, but not in schema   
# ```

# このエラーを解決しましょう。

# :large_orange_diamond: Action: 以下のコマンドを入力してください。


# ```shell
git apply patches/94f9796.patch # update index.ts
git apply patches/789bf5a.patch # update Query.json
# ```


# <details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

# ```ts:server/src/index.ts
# import { ApolloServer, gql } from "apollo-server";
# import * as fs from "fs";
# import { EmailAddressResolver } from "graphql-scalars";
# import { Query, Resolvers } from "./generated/graphql";

# const typeDefs = gql`
#   ${fs.readFileSync(__dirname.concat("/../schema.gql"), "utf8")}
# `;

# interface LoadingDataContext {
#   Query: Query;
# }

# const resolvers: Resolvers<LoadingDataContext> = {
#   Query: {
#     me(_parent, _args, context, _info) {
#       return context.Query.me;
#     },
#   },
#   Person: {
#     name(parent, _args, _context, _info) {
#       return parent.name;
#     },
#     emailAddress(parent, _args, _context, _info) {
#       return parent.emailAddress;
#     },
#   },
#   EmailAddress: EmailAddressResolver,
# };

# const readJsonFile = async (relativeFileName: string): Promise<any> => {
#   const jsonDataFile = __dirname.concat(relativeFileName);
#   const fileContent = await fs.promises.readFile(jsonDataFile, "utf8");
#   const jsonData = JSON.parse(fileContent);
#   return jsonData;
# };

# const server = new ApolloServer({
#   typeDefs,
#   resolvers,
#   context: async ({ req }: any) => {
#     try {
#       const queryData: LoadingDataContext = await readJsonFile(
#         "/../data/Query.json"
#       );
#       return { Query: queryData };
#     } catch (err) {
#       console.log("***ERROR OCURRED***");
#       console.log(err);
#       throw new Error("internal error happened!!");
#     }
#   },
# });

# // The `listen` method launches a web server.
# server.listen().then(({ url }) => {
#   console.log(`🚀  Server ready at ${url}`);
# });

# ```

# ---

# </div></details>

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される Query.json</summary><div>

# ```json:server/data/Query.json
# {
#   "me": { 
#     "emailAddress": "jason.summerwinnter@gmail.com",
#     "name": "Jason Summerwinter"
#   }
# }
# ```

# ---

# </div></details>

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
git apply patches/3e255ab.patch # return 10 in EmailAddress
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

# ```diff:server/src/index.ts
# emailAddress(parent, _args, _context, _info) {
# -  return parent.emailAddress;
# +  return 10;
# }
# ```    

# ---

# </div></details>

# <details><summary> :white_check_mark: Result: Apollo Studio Explorerでランタイムエラーを確認</summary><div>

# ![2022-08-09_05h46_24.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/a72a1d8e-a33e-55bd-0452-828c056993bb.png)

# ---

# </div></details>


# 上記のソースコードは `return 10` としてnumber型の値を返していて、ランタイムエラーは出力されるのですが、TypeScriptの静的型チェックはエラーを出力してくれません。

# number型ではGraphQLのEmailAddress型の値を表現できないので、TypeScriptの型チェックでエラーを出してほしいところです。そこで以下の変更を行いましょう。

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
git apply patches/12e6f2b.patch # Update codegen.yml to set EmailAddress as string
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される config.yml</summary><div>

# ```diff:config.yml
# generates:
#   src/generated/graphql.ts:
#     plugins:
#       - "typescript"
#       - "typescript-resolvers"
#     config:
#       avoidOptionals: true
# +       scalars:
# +         EmailAddress: string
# ```    

# ---

# </div></details>


# <details><summary>:white_check_mark: Result: config.ymlの変更に伴って、generated/graphql.ts が自動更新されます。</summary><div>

# ```diff:server/src/generated/graphql.ts
# export type Scalars = {
#   ID: string;
#   String: string;
#   Boolean: boolean;
#   Int: number;
#   Float: number;
# -  EmailAddress: any;
# +  EmailAddress: string;
# };
# ```    

# ---

# </div></details>

# 上記の変更によって、型チェックが働きます。stringが期待されるemailAddressのResolverでnumberをreturnすると、エラーが表示されることが確認できます。

# <details><summary>:white_check_mark: Result: TypeScript型チェックによるエラーの確認</summary><div>

# ![2022-08-06_21h33_37.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/11ef1c95-72e1-1ce8-446b-dd61a50cfb23.png)


# ```terminal
# Type 'number' is not assignable to type 'Maybe<ResolverTypeWrapper<string>> | Promise<Maybe<ResolverTypeWrapper<string>>>'
# The expected type comes from property 'emailAddress' which is declared here on type 'PersonResolvers<LoadingDataContext, Person>'
# ```

# ---

# </div></details>

# TypeScriptの型チェックがうまく動作しましたが、上記のようなgraphql-scalarsが提供する機能のみを使った型チェックでは、以下のような限界があります:

#   - stringが期待されるところでnumberをreturnするようなエラーを検出できます
#   - しかし、stringではあるものの、EmailAddressの形式として間違っているものはエラーにはなりません

# それを確認しましょう。


# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
git apply patches/0bfed3d.patch # wrong email address format passes type checking
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

# ```diff:server/src/index.ts
# emailAddress(parent, _args, _context, _info) {
# -  return 10;
# +  return "jason.summerwinter@@@@gmail.com";
# }
# ```    

# ---

# </div></details>

# こちらはTypeScriptの型チェックではエラーを検出できず、ランタイムエラーでのみ検出可能になります。

# <details><summary>:white_check_mark: Result: Apollo Studio Explorerでランタイムエラーを確認</summary><div>

# ![2022-08-08_00h28_44.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/d0bbfce6-f18a-582c-5896-ec953f159c8d.png)

# ---

# </div></details>

# :::note info
# TypeScriptの静的型チェックによってEmailAddressに変換できない形式のstringをエラーとして検出するには、このチュートリアルの5. および 6. で紹介する独自型の定義を使ったテクニックが必要です。
# :::

# それでは、graphql-scalarsが提供する機能のみを使った場合の型チェックの動作がわかったので、emailAddressをQuery.jsonファイルから値を取得する形に戻します。

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
git apply patches/8dcf32c.patch # revert the emailAddress back to parent.emailAddress
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

# ```diff:server/src/index.ts
# emailAddress(parent, _args, _context, _info) {
# -  return "jason.summerwinnter@@@@gmail.com";
# +  return 10;
# }
# ```    

# ---

# </div></details>

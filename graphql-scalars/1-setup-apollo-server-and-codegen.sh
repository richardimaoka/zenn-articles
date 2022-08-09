#!/bin/sh

# ## 1. Apollo ServerとGraphQL Codegenのセットアップ

# 下図のように 3 つのターミナルを使います。まずは 1 つ目ターミナルを立ち上げて、テンプレートのセットアップから GraphQL Codegen の実行までを行いましょう。

# ![アートボード 15.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/2a1f7fc4-b122-eac6-1123-1bffec13dd34.png)

# :large_orange_diamond: Action: 以下のコマンドを入力してください。一気に全部コピー & ペーストして実行して構いません。

# ```terminal
mkdir server
# shellcheck disable=SC2164 # REMOVE THIS IN aggregate.sh
cd server

# # node.js setup
npm init -y
echo "node_modules" > .gitignore

# # install and initialize typescript
npm install --save-dev typescript
npx tsc --init

# # ts-node-dev: watch and restart a TypeScript server
npm install --save-dev ts-node-dev
npm pkg set scripts.start="ts-node-dev --watch src/* --respawn src/index.ts"

# # apollo server
npm install apollo-server graphql

# # install and setup graphql-codegen
npm install -D @graphql-codegen/cli # @2.10.0
# # ここで npx graphql-code-generator init を行ってもよいが、そうすると対話モードに入って手入力が増えるのと、
# # 結局は npx graphql-code-generator init で生成されたconfig.ymlを上書き更新することになるので、以下はnpm installのみ行って config.ymlは後ほど作成
npm install --save-dev  @graphql-codegen/typescript @graphql-codegen/typescript-resolvers
npm set-script generate "graphql-codegen --config codegen.yml --watch ./schema.gql" # update generate script


# # copy files
mkdir src
mkdir data
curl https://raw.githubusercontent.com/richardimaoka/tutorial-apollo-server-setup/main/server/codegen.yml > codegen.yml
curl https://raw.githubusercontent.com/richardimaoka/tutorial-apollo-server-setup/main/server/schema.gql > schema.gql
curl https://raw.githubusercontent.com/richardimaoka/tutorial-apollo-server-setup/main/server/src/index.ts > src/index.ts
curl https://raw.githubusercontent.com/richardimaoka/tutorial-apollo-server-setup/main/server/data/Query.json > data/Query.json
# ```

:large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```terminal
npm run generate
# ```

:white_check_mark: Result: 以下のように表示されれば OK です

# ```terminal
# ✔ Parse Configuration
# ✔ Generate outputs
#   ℹ Watching for changes...
# ```

# このターミナルはそのまま GraphQL Codegen プロセスを走らせ続けてください。

# :large_orange_diamond: Action: 新しいターミナルを立ち上げてください。

# ![アートボード 16.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/bee9641c-c23d-7dc1-3518-b09e7d212a58.png)

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```terminal
# cd server
# npm start
# ```

:white_check_mark: Result: 以下のように表示されれば OK です。これで Apollo Server が立ち上がりました。

# ```terminal
# [INFO] 14:30:40 ts-node-dev ver. 1.1.8 (using ts-node ver. 9.1.1, typescript ver. 4.5.4)
# 🚀  Server ready at http://localhost:4000/
# ```

#!/bin/sh

cd "$(dirname "$0")" || exit # REMOVE THIS IN aggregate.sh
cd ../ || exit               # REMOVE THIS IN aggregate.sh - cd to the git repository root

# ## 3. 複数のcustom scalarsを使う

# ここではEmailAddress以外のcustom scalarも使ってみましょう。

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
git apply patches/59c46fb.patch # many custom scalars
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される Query.json</summary><div>

# ```diff:server/data/Query.json
# {
#   "me": {
# -    "emailAddress": "jason.summerwinnter@gmail.com",
# -    "name": "Jason Summerwinter"
# +    "name": "Jason Summerwinter",
# +    "birthDate": "1992-12-03T10:15:30Z",
# +    "ageInYears": 30,
# +    "heightInInches": 180,
# +    "minimumHourlyRate": 3000,
# +    "currentlyActiveProjects": 3,
# +    "emailAddress": "jason.summerwinter@gmail.com",
# +    "homePage": "https://json.summer.winter.com",
# +    "phoneNumber": "+12312345678",
# +    "homePostalCode": "010-0000"
#   }
# }
# ```

# ---

# </div></details>

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される schema.gql</summary><div>

# ```diff:server/schema.gql
# + scalar DateTime
# + scalar PositiveInt
# + scalar PositiveFloat
# + scalar NonNegativeFloat
# + scalar NonNegativeInt
# + scalar EmailAddress
# + scalar URL
# + scalar PhoneNumber
# + scalar PostalCode
 
# type Person {
# -  emailAddress: EmailAddress
#   name: String
# +   birthDate: DateTime
# +   ageInYears: PositiveInt
# +   heightInInches: PositiveFloat
# +   minimumHourlyRate: NonNegativeFloat
# +   currentlyActiveProjects: NonNegativeInt
# +   emailAddress: EmailAddress
# +   homePage: URL
# +   phoneNumber: PhoneNumber
# +   homePostalCode: PostalCode
# }

# type Query {
#   me: Person
# }
# ```

# ---

# </div></details>

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

# ```diff:server/src/index.ts
# import { ApolloServer, gql } from "apollo-server";
# import * as fs from "fs";
# - import { EmailAddressResolver } from "graphql-scalars";
# + import {
# +   DateTimeResolver,
# +   EmailAddressResolver,
# +   NonNegativeFloatResolver,
# +   NonNegativeIntResolver,
# +   PhoneNumberResolver,
# +   PositiveFloatResolver,
# +   PositiveIntResolver,
# +   PostalCodeResolver,
# +   URLResolver,
# + } from "graphql-scalars";
# import { Query, Resolvers } from "./generated/graphql";

# const typeDefs = gql`
# @@ -21,11 +31,43 @@ const resolvers: Resolvers<LoadingDataContext> = {
#     name(parent, _args, _context, _info) {
#       return parent.name;
#     },
# +     birthDate(parent, _args, _context, _info) {
# +       return parent.birthDate;
# +     },
# +     ageInYears(parent, _args, _context, _info) {
# +       return parent.ageInYears;
# +     },
# +     heightInInches(parent, _args, _context, _info) {
# +       return parent.heightInInches;
# +     },
# +     minimumHourlyRate(parent, _args, _context, _info) {
# +       return parent.minimumHourlyRate;
# +     },
# +     currentlyActiveProjects(parent, _args, _context, _info) {
# +       return parent.currentlyActiveProjects;
# +     },
#     emailAddress(parent, _args, _context, _info) {
#       return parent.emailAddress;
#     },
# +     homePage(parent, _args, _context, _info) {
# +       return parent.homePage;
# +     },
# +     phoneNumber(parent, _args, _context, _info) {
# +       return parent.phoneNumber;
# +     },
# +     homePostalCode(parent, _args, _context, _info) {
# +       return parent.homePostalCode;
# +     },
#   },
# +   DateTime: DateTimeResolver,
# +   PositiveInt: PositiveIntResolver,
# +   PositiveFloat: PositiveFloatResolver,
# +   NonNegativeFloat: NonNegativeFloatResolver,
# +   NonNegativeInt: NonNegativeIntResolver,
#   EmailAddress: EmailAddressResolver,
# +   URL: URLResolver,
# +   PhoneNumber: PhoneNumberResolver,
# +   PostalCode: PostalCodeResolver,
# };


# ```

# ---

# </div></details>

# <details><summary>:white_check_mark: Result: Apollo Studio Explorerで確認</summary><div>

# ![2022-08-08_00h37_18.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/93190d7f-e8e2-ebd4-6d0f-9c1497bec43b.png)

# ---

# </div></details>

# 以上で複数のcustom scalarを使う方法がわかったので、ソースコードを元の状態に戻しましょう。

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
git apply patches/15071a8.patch # Revert "many custom scalars"
# ```

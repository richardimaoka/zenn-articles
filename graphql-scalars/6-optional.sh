#!/bin/sh

cd "$(dirname "$0")" || exit # REMOVE THIS IN aggregate.sh
cd ../ || exit               # REMOVE THIS IN aggregate.sh - cd to the git repository root


# ## 6. (Optional) Custom scalarであるEmailAddressの情報を復元するため、TypeScriptで独自型を利用する

# ```shell
git apply patches/b1acf0c.patch # add CountryCode to schema.gql
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される myTypes.ts</summary><div>

# ```diff:server/src/myTypes.ts
# +export type CountryString = string & { __type: "CountryString" };
# +
# +export const isCountryString = (str: string): str is CountryString => {
# +  const COUNTRY_CODE_REGEX =
# +    /^(AD|AE|AF|AG|AI|AL|AM|AO|AQ|AR|AS|AT|AU|AW|AX|AZ|BA|BB|BD|BE|BF|BG|BH|BI|BJ|BL|BM|BN|BO|BQ|BR|BS|BT|BV|BW|BY|BZ|CA|CC|CD|CF|CG|CH|CI|CK|CL|CM|CN|CO|CR|CU|CV|CW|CX|CY|CZ|DE|DJ|DK|DM|DO|DZ|EC|EE|EG|EH|ER|ES|ET|FI|FJ|FK|FM|FO|FR|GA|GB|GD|GE|GF|GG|GH|GI|GL|GM|GN|GP|GQ|GR|GS|GT|GU|GW|GY|HK|HM|HN|HR|HT|HU|ID|IE|IL|IM|IN|IO|IQ|IR|IS|IT|JE|JM|JO|JP|KE|KG|KH|KI|KM|KN|KP|KR|KW|KY|KZ|LA|LB|LC|LI|LK|LR|LS|LT|LU|LV|LY|MA|MC|MD|ME|MF|MG|MH|MK|ML|MM|MN|MO|MP|MQ|MR|MS|MT|MU|MV|MW|MX|MY|MZ|NA|NC|NE|NF|NG|NI|NL|NO|NP|NR|NU|NZ|OM|PA|PE|PF|PG|PH|PK|PL|PM|PN|PR|PS|PT|PW|PY|QA|RE|RO|RS|RU|RW|SA|SB|SC|SD|SE|SG|SH|SI|SJ|SK|SL|SM|SN|SO|SR|SS|ST|SV|SX|SY|SZ|TC|TD|TF|TG|TH|TJ|TK|TL|TM|TN|TO|TR|TT|TV|TW|TZ|UA|UG|UM|US|UY|UZ|VA|VC|VE|VG|VI|VN|VU|WF|WS|YE|YT|ZA|ZM|ZW)$/i;
# +
# +  return COUNTRY_CODE_REGEX.test(str);
# +};
# ```

# ---

# </div></details>

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
git apply patches/09bc748.patch # add country to index.ts
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される config.yml</summary><div>

# ```diff:server/codegen.yml
#        avoidOptionals: true
#        scalars:
#          EmailAddress: myTypes.EmailAddressString
# +        CountryCode: myTypes.CountryString
#  hooks:
#    afterOneFileWrite:
#      - npx prettier --write
# ```

# ---

# </div></details>

# <details><summary>:white_check_mark: Result: config.ymlにともなって自動生成されるgraphql.ts</summary><div>

# ```diff:server/src/generated/graphql.ts
#    Boolean: boolean;
#    Int: number;
#    Float: number;
# -  CountryCode: any;
# +  CountryCode: myTypes.CountryString;
#    EmailAddress: myTypes.EmailAddressString;
#  };
# ```

# ---

# </div></details>

# :large_orange_diamond: Action: 以下のコマンドを入力してください。

# ```shell
git apply patches/6c02fe8.patch # update data/Query.json
# ```

# <details><summary>:white_check_mark: Result: 上記コマンドで更新される myTypes.ts</summary><div>

# ```diff:server/src/myTypes.ts
# import * as fs from "fs";
#  import { CountryCodeResolver, EmailAddressResolver } from "graphql-scalars";
#  import { Query, Resolvers } from "./generated/graphql";
# +import { CountryString } from "./myTypes";
 
#  const typeDefs = gql`
#    ${fs.readFileSync(__dirname.concat("/../schema.gql"), "utf8")}
#  `;
 
# +// process `country`, guaranteed to be a valid Country Code
# +const processCounteryDeepInsideServer = (country: CountryString) => {
# +  console.log(country);
# +};
# +
#  interface LoadingDataContext {
#    Query: Query;
#  }
# @@ -16,7 +22,9 @@ const resolvers: Resolvers<LoadingDataContext> = {
#      me(_parent, _args, context, _info) {
#        return context.Query.me;
#      },
# -    search(_parent, _args, context, _info) {
# +    search(_parent, args, context, _info) {
# +      const countryString = args.country;
# +      processCounteryDeepInsideServer(countryString);
#        return context.Query.search;
#      },
#    },
# ```

# ---

# </div></details>

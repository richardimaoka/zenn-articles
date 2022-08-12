## 6. (Optional) GraphQL の argument に対して TypeScript で独自型を利用する

先程は GraphQL の field 型にたいして TypeScript の独自型を定義しましたが、今度は GraphQL の argument 型に対して TypeScript の独自型を定義しましょう。

```shell
git apply patches/e1814cb.patch # CoutryString type
```

<details><summary>:white_check_mark: Result: 上記コマンドで更新される myTypes.ts</summary><div>

```diff:server/src/myTypes.ts
+export type CountryString = string & { __type: "CountryString" };
+
+export const isCountryString = (str: string): str is CountryString => {
+  const COUNTRY_CODE_REGEX =
+    /^(AD|AE|AF|AG|AI|AL|AM|AO|AQ|AR|AS|AT|AU|AW|AX|AZ|BA|BB|BD|BE|BF|BG|BH|BI|BJ|BL|BM|BN|BO|BQ|BR|BS|BT|BV|BW|BY|BZ|CA|CC|CD|CF|CG|CH|CI|CK|CL|CM|CN|CO|CR|CU|CV|CW|CX|CY|CZ|DE|DJ|DK|DM|DO|DZ|EC|EE|EG|EH|ER|ES|ET|FI|FJ|FK|FM|FO|FR|GA|GB|GD|GE|GF|GG|GH|GI|GL|GM|GN|GP|GQ|GR|GS|GT|GU|GW|GY|HK|HM|HN|HR|HT|HU|ID|IE|IL|IM|IN|IO|IQ|IR|IS|IT|JE|JM|JO|JP|KE|KG|KH|KI|KM|KN|KP|KR|KW|KY|KZ|LA|LB|LC|LI|LK|LR|LS|LT|LU|LV|LY|MA|MC|MD|ME|MF|MG|MH|MK|ML|MM|MN|MO|MP|MQ|MR|MS|MT|MU|MV|MW|MX|MY|MZ|NA|NC|NE|NF|NG|NI|NL|NO|NP|NR|NU|NZ|OM|PA|PE|PF|PG|PH|PK|PL|PM|PN|PR|PS|PT|PW|PY|QA|RE|RO|RS|RU|RW|SA|SB|SC|SD|SE|SG|SH|SI|SJ|SK|SL|SM|SN|SO|SR|SS|ST|SV|SX|SY|SZ|TC|TD|TF|TG|TH|TJ|TK|TL|TM|TN|TO|TR|TT|TV|TW|TZ|UA|UG|UM|US|UY|UZ|VA|VC|VE|VG|VI|VN|VU|WF|WS|YE|YT|ZA|ZM|ZW)$/i;
+
+  return COUNTRY_CODE_REGEX.test(str);
+};
```

---

</div></details>

:large_orange_diamond: Action: 以下のコマンドを入力してください。

```shell
git apply patches/10f274d.patch # use CountryString in generated code
```

<details><summary>:white_check_mark: Result: 上記コマンドで更新される config.yml</summary><div>

```diff:server/codegen.yml
       avoidOptionals: true
       scalars:
         EmailAddress: myTypes.EmailAddressString
+        CountryCode: myTypes.CountryString
 hooks:
   afterOneFileWrite:
     - npx prettier --write
```

---

</div></details>

<details><summary>:white_check_mark: Result: config.ymlにともなって自動生成されるgraphql.ts</summary><div>

```diff:server/src/generated/graphql.ts
   Boolean: boolean;
   Int: number;
   Float: number;
-  CountryCode: any;
+  CountryCode: myTypes.CountryString;
   EmailAddress: myTypes.EmailAddressString;
 };
```

---

</div></details>

:large_orange_diamond: Action: 以下のコマンドを入力してください。

```shell
git apply patches/d224c5e.patch # args.country is typed as CountryString
```

<details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

```diff:server/src/index.ts
     me(_parent, _args, context, _info) {
       return context.Query.me;
     },
-    search(_parent, _args, context, _info) {
+    search(_parent, args, context, _info) {
+      const countryString = args.country;
+      console.log(countryString);
       return context.Query.search;
     },
   },
```

---

</div></details>

<details><summary>:white_check_mark: Result: args.countryがCountryString型になっています</summary><div>

![2022-08-10_04h35_54.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/75738/dc1f040d-3697-5a59-21bf-af3bfc26f298.png)

---

</div></details>

それでは、サーバー側ロジックの深い部分でこの CountryString 型を利用することを想定して、コードを書き換えてみましょう。

:large_orange_diamond: Action: 以下のコマンドを入力してください。

```shell
git apply patches/06d0d6c.patch # process args.country inside search
```

<details><summary>:white_check_mark: Result: 上記コマンドで更新される index.ts</summary><div>

```diff:server/src/index.ts
+import { CountryString } from "./myTypes";

 const typeDefs = gql`
   ${fs.readFileSync(__dirname.concat("/../schema.gql"), "utf8")}
 `;

+// process `country`, guaranteed to be a valid Country Code
+const processCounteryDeepInsideServer = (country: CountryString) => {
+  console.log(country);
+};
+
 interface LoadingDataContext {
   Query: Query;
 }
@@ -18,7 +24,7 @@ const resolvers: Resolvers<LoadingDataContext> = {
     },
     search(_parent, args, context, _info) {
       const countryString = args.country;
-      console.log(countryString);
+      processCounteryDeepInsideServer(countryString);
       return context.Query.search;
     },
   },
```

---

</div></details>

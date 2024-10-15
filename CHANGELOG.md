# Changelog

## [0.1.14](https://github.com/apiaframework/apia-openapi/compare/v0.1.13...v0.1.14) (2024-10-15)


### Bug Fixes

* only add mutually exclusive description if argument is a lookup argument set ([#81](https://github.com/apiaframework/apia-openapi/issues/81)) ([543dba2](https://github.com/apiaframework/apia-openapi/commit/543dba241a8e08c58e431c2c57080a02db110f63))
* only add mutually exclusive description if there are multiple arguments in a lookup argument set ([#83](https://github.com/apiaframework/apia-openapi/issues/83)) ([7b5d5e7](https://github.com/apiaframework/apia-openapi/commit/7b5d5e7005613f5fabea2b64252435dbc08bc0d4))

## [0.1.13](https://github.com/apiaframework/apia-openapi/compare/v0.1.12...v0.1.13) (2024-09-13)


### Bug Fixes

* only add mutually exclusive description to lookup argument sets ([#79](https://github.com/apiaframework/apia-openapi/issues/79)) ([77f0e31](https://github.com/apiaframework/apia-openapi/commit/77f0e31d4bf09ab2cafcc0446dcff24dba627565))

## [0.1.12](https://github.com/apiaframework/apia-openapi/compare/v0.1.11...v0.1.12) (2024-09-03)


### Bug Fixes

* don't insert `/` between prefix and scope, assume any prefix should contain it's own separator. ([#76](https://github.com/apiaframework/apia-openapi/issues/76)) ([8cad391](https://github.com/apiaframework/apia-openapi/commit/8cad39125b2a0d2c3ca920c23fac48a15cf74c63))

## [0.1.11](https://github.com/apiaframework/apia-openapi/compare/v0.1.10...v0.1.11) (2024-09-02)


### Bug Fixes

* security schemes keys to symbols ([#74](https://github.com/apiaframework/apia-openapi/issues/74)) ([3506742](https://github.com/apiaframework/apia-openapi/commit/3506742bb48d39bd1f3ce9651296a717019b1583))

## [0.1.10](https://github.com/apiaframework/apia-openapi/compare/v0.1.9...v0.1.10) (2024-08-30)


### Features

* allow passing of info + external_docs to the openapi specification. ([#72](https://github.com/apiaframework/apia-openapi/issues/72)) ([349f236](https://github.com/apiaframework/apia-openapi/commit/349f236bdbe17e8c81e3d0888079dfe01392cdba))
* allow passing over security_shemes to the specification and add… ([#73](https://github.com/apiaframework/apia-openapi/issues/73)) ([275d771](https://github.com/apiaframework/apia-openapi/commit/275d771051d6dfaf602bbb2b08113b420ad27369))


### Bug Fixes

* handle standard argument sets and array types for argument sets ([#70](https://github.com/apiaframework/apia-openapi/issues/70)) ([8d1d288](https://github.com/apiaframework/apia-openapi/commit/8d1d288738dac2a4702f0c8a50217d44a1d472b8))

## [0.1.9](https://github.com/apiaframework/apia-openapi/compare/v0.1.8...v0.1.9) (2024-08-21)


### Features

* add documentation details to endpoints ([#65](https://github.com/apiaframework/apia-openapi/issues/65)) ([ed9e9d2](https://github.com/apiaframework/apia-openapi/commit/ed9e9d239e463f22b10d6974c2d639e43f0af81a))

## [0.1.8](https://github.com/apiaframework/apia-openapi/compare/v0.1.7...v0.1.8) (2024-08-21)


### Bug Fixes

* ensure nested params don't break schema ([c224beb](https://github.com/apiaframework/apia-openapi/commit/c224beb44bd201d83691b05c5a4ad9f66ef13428))

## [0.1.7](https://github.com/apiaframework/apia-openapi/compare/v0.1.6...v0.1.7) (2024-05-22)


### Features

* Support plain text responses ([c3e0c6a](https://github.com/apiaframework/apia-openapi/commit/c3e0c6ac045581371d440c615c045815f7046dc4))

## [0.1.6](https://github.com/krystal/apia-openapi/compare/v0.1.5...v0.1.6) (2024-02-08)


### Bug Fixes

* handle nullable, remove duplication ([#60](https://github.com/krystal/apia-openapi/issues/60)) ([1ecfc13](https://github.com/krystal/apia-openapi/commit/1ecfc133071fb14e273e0a847f84112aaf7e2452)), closes [#55](https://github.com/krystal/apia-openapi/issues/55)

## [0.1.5](https://github.com/krystal/apia-openapi/compare/v0.1.4...v0.1.5) (2024-01-24)


### Features

* ensure apia objects can be declared as nullable ([#56](https://github.com/krystal/apia-openapi/issues/56)) ([7cb80e7](https://github.com/krystal/apia-openapi/commit/7cb80e773b2f27659b932288da0aaea7faf3c85a))

## [0.1.4](https://github.com/krystal/apia-openapi/compare/v0.1.3...v0.1.4) (2023-12-14)


### Features

* extract error response code enums into schemas ([#53](https://github.com/krystal/apia-openapi/issues/53)) ([ce2ba62](https://github.com/krystal/apia-openapi/commit/ce2ba623c6fb7bf82a98bbdbd50f84b763a77245)), closes [#52](https://github.com/krystal/apia-openapi/issues/52)

## [0.1.3](https://github.com/krystal/apia-openapi/compare/v0.1.2...v0.1.3) (2023-12-13)


### Bug Fixes

* use unique names across schemas and responses ([#50](https://github.com/krystal/apia-openapi/issues/50)) ([b4502d1](https://github.com/krystal/apia-openapi/commit/b4502d1525536c586f53a629a4f2d7ced0922d40)), closes [#49](https://github.com/krystal/apia-openapi/issues/49)

## [0.1.2](https://github.com/krystal/apia-openapi/compare/v0.1.1...v0.1.2) (2023-12-11)


### Features

* limit the generated names of the $refs ([#47](https://github.com/krystal/apia-openapi/issues/47)) ([8dec51f](https://github.com/krystal/apia-openapi/commit/8dec51f56ea8cf1a4deef09bc27166707078e6d6)), closes [#46](https://github.com/krystal/apia-openapi/issues/46)

## [0.1.1](https://github.com/krystal/apia-openapi/compare/v0.0.2...v0.1.1) (2023-12-06)


### Miscellaneous Chores

* release 0.0.2 ([806f469](https://github.com/krystal/apia-openapi/commit/806f469bc7ea0fc57caa40ba497e0499fdcb5915))
* release 0.1.1 ([dcead5d](https://github.com/krystal/apia-openapi/commit/dcead5db386ded0621ebd0fc02118b81482beb24))

## [0.0.2](https://github.com/krystal/apia-openapi/compare/v0.0.1...v0.0.2) (2023-12-06)


### Miscellaneous Chores

* release 0.0.1 ([f6633f5](https://github.com/krystal/apia-openapi/commit/f6633f514952e2a4a4645016f6946b63fd64cab9))
* release 0.0.2 ([cc62069](https://github.com/krystal/apia-openapi/commit/cc6206990915c717ef82e6dd84b041cb9712634a))

## [0.0.1](https://github.com/krystal/apia-openapi/compare/v0.0.1...v0.0.1) (2023-12-06)


### Miscellaneous Chores

* release 0.0.1 ([a00ef4b](https://github.com/krystal/apia-openapi/commit/a00ef4bfae9a8a727b60131f8734b01d63316423))

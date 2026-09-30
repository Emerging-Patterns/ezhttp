# Changelog

## [0.8.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.7.0...v0.8.0) (2026-09-30)


### ⚠ BREAKING CHANGES

* ezhttp's internal modules moved from ezhttp/ to src/, and the entry from ezhttp/main.bend to main.bend. Importers of main.bend by the package's hub name are unaffected; importers of any other module update the path, e.g. <hash>/http.bend becomes <hash>/src/http.bend.

### Features

* ez init's layout, main.bend at the root and modules under src/ ([#19](https://github.com/Emerging-Patterns/ezhttp/issues/19)) ([f1caaee](https://github.com/Emerging-Patterns/ezhttp/commit/f1caaee1dfe7d01903e67cc031973866aefb3783))

## [0.7.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.6.0...v0.7.0) (2026-09-29)


### ⚠ BREAKING CHANGES

* http.serve and http.serve_once (and server.listen, server.serve, server.once) take `host: String` before `port`, the address to bind, e.g. "127.0.0.1" for loopback or "0.0.0.0" for every interface. Replace `http.serve(handle, 8080, n)` with `http.serve(handle, "127.0.0.1", 8080, n)`. ezhttp now needs bend 2.0.32 or later.

### Features

* server takes the host to bind; bend 2.0.34 ([#17](https://github.com/Emerging-Patterns/ezhttp/issues/17)) ([f7158f9](https://github.com/Emerging-Patterns/ezhttp/commit/f7158f918f96035bd22825d11eea6200039d95dd))

## [0.6.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.5.0...v0.6.0) (2026-09-25)


### Bug Fixes

* bend 2.0.28 (wire effect registration, bench renames) ([#14](https://github.com/Emerging-Patterns/ezhttp/issues/14)) ([7225964](https://github.com/Emerging-Patterns/ezhttp/commit/72259648c1bd6f7e3c2afbba71d6d5a931323139))

## [0.5.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.4.0...v0.5.0) (2026-09-25)


### Bug Fixes

* **deps:** ezjson 1.1.0 from the hub ([#8](https://github.com/Emerging-Patterns/ezhttp/issues/8)) ([65980dc](https://github.com/Emerging-Patterns/ezhttp/commit/65980dc4a2068785cd5f23604a76e198ff96ac77))

## [0.4.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.3.0...v0.4.0) (2026-09-22)


### Features

* add fair client/server/load benches ([#5](https://github.com/Emerging-Patterns/ezhttp/issues/5)) ([5528439](https://github.com/Emerging-Patterns/ezhttp/commit/5528439a6788e2f491b2dca3dd8a3e5ac3ae51f8))

## [0.3.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.2.0...v0.3.0) (2026-09-22)


### Features

* deepen HTTP compliance laws ([#3](https://github.com/Emerging-Patterns/ezhttp/issues/3)) ([b1681a9](https://github.com/Emerging-Patterns/ezhttp/commit/b1681a9763f7549a73f97d5ce753db84e5ac3416))

## [0.2.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.1.0...v0.2.0) (2026-09-22)


### Features

* scaffold HTTP client and server ([#1](https://github.com/Emerging-Patterns/ezhttp/issues/1)) ([5777828](https://github.com/Emerging-Patterns/ezhttp/commit/5777828dc6362324b2f2d7cde3498c41aad27533))

## [0.1.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.1.0...v0.1.0) (2026-03-22)

### Features

* scaffold HTTP/1.1 client and server with shared message types and BYO JSON

# Changelog

## [0.22.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.21.0...v0.22.0) (2026-10-25)


### Features

* **nix:** build and check on x86_64-linux, aarch64-linux and aarch64-darwin ([#61](https://github.com/Emerging-Patterns/ezhttp/issues/61)) ([beba19e](https://github.com/Emerging-Patterns/ezhttp/commit/beba19e3e4caeca817aeae4fd8723149245dcd0b))

## [0.21.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.20.0...v0.21.0) (2026-10-23)


### ⚠ BREAKING CHANGES

* **client:** Client.Response is Response{status, headers, reason, bytes}; the eager `body` text is gone, and body_text(bytes) decodes it as UTF-8 when asked. Wire.wire.talk, talk.timed and run answer IO(Wire.Answer) (Failed{answer} or Received{octets}); http.heard is replaced by http.answer. wirespec's Got and the old read state are gone: wire.got(method) is an Http.Hear, Read is Again{hear} | Heard{}, and wire.read.next takes the state and a receive's text. Http.parse.frame, parse.agree, parse.te and parse.te.clash are replaced by head.plan and plan.text.

### Features

* **client:** read responses on packed octets, decode the body on demand ([#58](https://github.com/Emerging-Patterns/ezhttp/issues/58)) ([cab153b](https://github.com/Emerging-Patterns/ezhttp/commit/cab153b2bf4308127f454d8e204e6c85ae50aaaa))

## [0.20.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.19.0...v0.20.0) (2026-10-23)


### ⚠ BREAKING CHANGES

* **server:** connections are served concurrently, not one at a time; limited serves return once every forked connection is closed; replies are sent with bend-kit-wire's send.words; server.reply (the CORS helper) is renamed server.reply.text.

### Features

* **server:** fork per connection, a context for the handler, byte replies ([#56](https://github.com/Emerging-Patterns/ezhttp/issues/56)) ([9eaa048](https://github.com/Emerging-Patterns/ezhttp/commit/9eaa048b3e33667a65a3ca0bd5e673442612a6dc))

## [0.19.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.18.0...v0.19.0) (2026-10-23)


### ⚠ BREAKING CHANGES

* Client.Response is a Type with a new `bytes` field; Body is a Type and Body.Octets holds Bytes (`octets_list_body` takes the old list); form_file takes Bytes and form_field/form_file return Form.Upload; Form.Form is a Type; parse_response reads octets, one character each; post_req/put_req/delete_req take a text body.

### Features

* byte-exact bodies: what arrives is octets, octet bodies are Bytes ([#54](https://github.com/Emerging-Patterns/ezhttp/issues/54)) ([aca9eba](https://github.com/Emerging-Patterns/ezhttp/commit/aca9eba2b4c2143ddf54b50fba1595c8a4b1df2c))

## [0.18.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.17.0...v0.18.0) (2026-10-23)


### ⚠ BREAKING CHANGES

* **client:** EZ_LIBSSL is no longer read; set BEND_LIBSSL. A failed resolve names an errno (ENOENT, EAGAIN, ...) instead of an EAI_ code; a failed TLS handshake is `<name> (<n>): <reason>` instead of an SSL_ERROR code; a send over TLS is not bounded by the timeout; a body octet past 255 is sent as its low 8 bits instead of being refused.

### Features

* **client:** run the client over bend-kit-wire's sockets ([#52](https://github.com/Emerging-Patterns/ezhttp/issues/52)) ([6e3170c](https://github.com/Emerging-Patterns/ezhttp/commit/6e3170c89e29d59cfb567bf7e891a3052cfe0a93))

## [0.17.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.16.0...v0.17.0) (2026-10-23)


### Features

* **text:** unquote, query strings, html_unescape and the Cookie header sent back ([#44](https://github.com/Emerging-Patterns/ezhttp/issues/44)) ([d1b1669](https://github.com/Emerging-Patterns/ezhttp/commit/d1b1669dfae15f2e808eae677cbe58ca630eaa71))

## [0.16.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.15.0...v0.16.0) (2026-10-23)


### ⚠ BREAKING CHANGES

* **client:** Client.Response{status, headers, body} is now Client.Response{status, headers, body, reason}; a pattern match on it needs the fourth field (`_reason`).

### Features

* **client:** name the cause of a failed connection; expose the reason phrase ([#43](https://github.com/Emerging-Patterns/ezhttp/issues/43)) ([208f3d5](https://github.com/Emerging-Patterns/ezhttp/commit/208f3d5a441492947e5a3023a0a18c886a83205f))

## [0.15.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.14.0...v0.15.0) (2026-10-23)


### Performance Improvements

* **client:** judge chunked responses read by read, in linear time ([#45](https://github.com/Emerging-Patterns/ezhttp/issues/45)) ([c392d73](https://github.com/Emerging-Patterns/ezhttp/commit/c392d73641415e1dc4e5b4bf8ac0c5ee56d0e2b3))

## [0.14.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.13.0...v0.14.0) (2026-10-23)


### Features

* **client:** multipart/form-data bodies sent byte for byte; read responses by request method ([#40](https://github.com/Emerging-Patterns/ezhttp/issues/40)) ([6252588](https://github.com/Emerging-Patterns/ezhttp/commit/62525882935dbbd6e52c75a3405921ff1a3799e6))

## [0.13.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.12.0...v0.13.0) (2026-10-23)


### Features

* **client:** timed requests for every method; fix method on the wire and default-header overrides ([#38](https://github.com/Emerging-Patterns/ezhttp/issues/38)) ([91af3fb](https://github.com/Emerging-Patterns/ezhttp/commit/91af3fb92cbae3fd08a7387e97b1a76f9657e61c))

## [0.12.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.11.0...v0.12.0) (2026-10-23)


### Bug Fixes

* Host with port, complete-response reads, relative redirects, reason-phrases ([#36](https://github.com/Emerging-Patterns/ezhttp/issues/36)) ([4f90e37](https://github.com/Emerging-Patterns/ezhttp/commit/4f90e377f1bf0a0a4f55d9e49fb6df8198e1a650))

## [0.11.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.10.0...v0.11.0) (2026-10-23)


### Features

* **client:** GET timeout and redirect following, and html_escape (HTTP-CLI, HTTP-REDIR, HTTP-HTML) ([#33](https://github.com/Emerging-Patterns/ezhttp/issues/33)) ([e1d0223](https://github.com/Emerging-Patterns/ezhttp/commit/e1d02233752832ec3562bae80b998e8918f820ce))

## [0.10.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.9.0...v0.10.0) (2026-10-23)


### ⚠ BREAKING CHANGES

* the text/plain body constructor `Body.Text{text}` is now `Body.Plain{text}` (body.text, body.encode and Ez.text_body are unchanged). `Step.step.sent` now takes `Result<(U32 & String) & List<&2, U32>, Unit>`, matching Base's new TCP.send. ezhttp now needs bend 2.0.38 or later.

### Features

* port to Bend 2.0.38 ([#31](https://github.com/Emerging-Patterns/ezhttp/issues/31)) ([dc80838](https://github.com/Emerging-Patterns/ezhttp/commit/dc80838d53e0aec692406f66f2a6d6c83e6e9b07))
* **url:** quote_path and quote_component percent-encoding (HTTP-URL) ([#30](https://github.com/Emerging-Patterns/ezhttp/issues/30)) ([c9bf37c](https://github.com/Emerging-Patterns/ezhttp/commit/c9bf37c0d279b6a2de88767f78da528e0b2339f8))

## [0.9.0](https://github.com/Emerging-Patterns/ezhttp/compare/v0.8.0...v0.9.0) (2026-10-23)


### Features

* **server:** IO handlers, and a failed connection no longer ends the server ([#28](https://github.com/Emerging-Patterns/ezhttp/issues/28)) ([92fec51](https://github.com/Emerging-Patterns/ezhttp/commit/92fec513772d23fe3f411ca0451b0836d543d4e4))

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

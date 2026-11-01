# ezhttp's laws. Each guarantee is one file under laws/, its prose on top and
# its quantified laws under it, proved by the file of the same name under
# proofs/; LAWS.bend and PROOF.bend only import them. The gate: the first line
# `bend PROOF.bend` prints is exactly `ALL PROOFS CHECK`. Tests and fixtures
# are never evidence for a guarantee; what ezhttp cannot prove is said where
# it is assumed, on the code (`# Trusted, not proved:`). A guarantee whose
# prose says it is pending is proved only in part, and is not guaranteed
# until the rest is.
#
# The guarantees cover the server, percent-encoding, the client's requests,
# timeout and redirects, bodies as octets, multipart form bodies, HTML
# escaping, percent-decoding and query strings, HTML character references,
# and the Cookie header sent back after Set-Cookie. The first file of each
# family opens with what the family is about: laws/BadRequestAnswers400.bend
# (the server), laws/QuoteKeepsUnreserved.bend (percent-encoding),
# laws/RequestLineAndHost.bend (the client), laws/OneOctetPerChar.bend
# (bodies as octets), laws/RedirectsFollowLocation.bend (redirects),
# laws/FormRefusesBadRequests.bend (multipart forms),
# laws/HtmlEscapeCharByChar.bend (HTML escaping),
# laws/UnquoteReadsEscapes.bend (percent-decoding and query strings),
# laws/UnescapeFindsReferences.bend (character references) and
# laws/CookieHeaderEchoesStore.bend (cookies sent back).
#
# ezhttp's other laws are closed equalities for URL parsing (RFC 3986),
# HTTP/1.1 message framing (RFC 9112), HTTP semantics (RFC 9110), TLS
# selection (RFC 2818), Basic and Bearer credentials (RFC 7617, RFC 4648,
# RFC 6750), the cookie jar in src/cookie.bend (RFC 6265), caching
# directives (RFC 9111) and Fetch CORS. They are not inventoried as
# guarantees yet: each is a file named after its one law, with no prose
# (laws/PathAbsolute.bend, laws/CacheDirectives.bend), and promises nothing
# beyond the equality it states.
#
# Commits before these files name guarantees by the requirement IDs of
# docs/SPEC.md, the table these files replaced.
import Base
import ./laws/AbsoluteLocationsResolve.bend as AbsoluteLocationsResolve
import ./laws/AskClenExact.bend as AskClenExact
import ./laws/AskClenShort.bend as AskClenShort
import ./laws/AskEqualContentLengths.bend as AskEqualContentLengths
import ./laws/AskGetAsteriskRejected.bend as AskGetAsteriskRejected
import ./laws/AskKeepsFieldNameSpelling.bend as AskKeepsFieldNameSpelling
import ./laws/AskNeedsBlankLine.bend as AskNeedsBlankLine
import ./laws/AskNeedsRequestLine.bend as AskNeedsRequestLine
import ./laws/AskOptionsAsterisk.bend as AskOptionsAsterisk
import ./laws/AskOriginFormKeepsQuery.bend as AskOriginFormKeepsQuery
import ./laws/AskRejectsAbsoluteForm.bend as AskRejectsAbsoluteForm
import ./laws/AskRejectsClAndTe.bend as AskRejectsClAndTe
import ./laws/AskRejectsDisagreeingCl.bend as AskRejectsDisagreeingCl
import ./laws/AskRejectsRelativeTarget.bend as AskRejectsRelativeTarget
import ./laws/AskShowBadIsMarked.bend as AskShowBadIsMarked
import ./laws/B64Empty.bend as B64Empty
import ./laws/B64F.bend as B64F
import ./laws/B64Fo.bend as B64Fo
import ./laws/B64Foo.bend as B64Foo
import ./laws/B64GoEnd.bend as B64GoEnd
import ./laws/B64UserPass.bend as B64UserPass
import ./laws/BadRequestAnswers400.bend as BadRequestAnswers400
import ./laws/BareRepliesWriteHeadOnly.bend as BareRepliesWriteHeadOnly
import ./laws/BasicUserPass.bend as BasicUserPass
import ./laws/BearerIsAuthorization.bend as BearerIsAuthorization
import ./laws/CacheDirectiveCase.bend as CacheDirectiveCase
import ./laws/CacheDirectives.bend as CacheDirectives
import ./laws/CacheIgnoresSMaxage.bend as CacheIgnoresSMaxage
import ./laws/CacheMaxAgeIgnoresJunk.bend as CacheMaxAgeIgnoresJunk
import ./laws/CacheMaxAgePresent.bend as CacheMaxAgePresent
import ./laws/CacheNoCacheAlone.bend as CacheNoCacheAlone
import ./laws/CacheNoteExpires.bend as CacheNoteExpires
import ./laws/CachePrivateAlone.bend as CachePrivateAlone
import ./laws/ChunkDataUnchanged.bend as ChunkDataUnchanged
import ./laws/ChunksEmptyFuel.bend as ChunksEmptyFuel
import ./laws/ClenExact.bend as ClenExact
import ./laws/ContentLengthFramesBody.bend as ContentLengthFramesBody
import ./laws/CookieAgeSets.bend as CookieAgeSets
import ./laws/CookieDefaultPathDir.bend as CookieDefaultPathDir
import ./laws/CookieDefaultPathOneSlash.bend as CookieDefaultPathOneSlash
import ./laws/CookieDefaultPathRoot.bend as CookieDefaultPathRoot
import ./laws/CookieDefaultPathTrailing.bend as CookieDefaultPathTrailing
import ./laws/CookieDomainIpExact.bend as CookieDomainIpExact
import ./laws/CookieDomainIpSuffix.bend as CookieDomainIpSuffix
import ./laws/CookieDomainLowercased.bend as CookieDomainLowercased
import ./laws/CookieDomainNotSuffix.bend as CookieDomainNotSuffix
import ./laws/CookieDomainSuffix.bend as CookieDomainSuffix
import ./laws/CookieHeaderEchoesStore.bend as CookieHeaderEchoesStore
import ./laws/CookieInsecureOnTcp.bend as CookieInsecureOnTcp
import ./laws/CookieIpv4Literal.bend as CookieIpv4Literal
import ./laws/CookieIpv4Name.bend as CookieIpv4Name
import ./laws/CookieLineAttributes.bend as CookieLineAttributes
import ./laws/CookieMaxAgeIgnoresJunk.bend as CookieMaxAgeIgnoresJunk
import ./laws/CookieMaxAgeOne.bend as CookieMaxAgeOne
import ./laws/CookieMaxAgeOpen.bend as CookieMaxAgeOpen
import ./laws/CookieMaxAgeZero.bend as CookieMaxAgeZero
import ./laws/CookieParseRoundTrip.bend as CookieParseRoundTrip
import ./laws/CookiePathIdentical.bend as CookiePathIdentical
import ./laws/CookiePathLongerCookie.bend as CookiePathLongerCookie
import ./laws/CookiePathNotPrefix.bend as CookiePathNotPrefix
import ./laws/CookiePathPrefix.bend as CookiePathPrefix
import ./laws/CookiePathRoot.bend as CookiePathRoot
import ./laws/CookiePathSlashPrefix.bend as CookiePathSlashPrefix
import ./laws/CookieReceiveHostOnly.bend as CookieReceiveHostOnly
import ./laws/CookieRejectsEmptyName.bend as CookieRejectsEmptyName
import ./laws/CookieRequestJoins.bend as CookieRequestJoins
import ./laws/CookieSamesiteNone.bend as CookieSamesiteNone
import ./laws/CookieSamesiteStrict.bend as CookieSamesiteStrict
import ./laws/CookieSamesiteUnknown.bend as CookieSamesiteUnknown
import ./laws/CookieSecureNeedsTls.bend as CookieSecureNeedsTls
import ./laws/CookieSecureOnTls.bend as CookieSecureOnTls
import ./laws/CookieSendHostOnly.bend as CookieSendHostOnly
import ./laws/CookieSendOtherHost.bend as CookieSendOtherHost
import ./laws/CookieSendUnsetDomain.bend as CookieSendUnsetDomain
import ./laws/CookieSessionAlive.bend as CookieSessionAlive
import ./laws/CorsCredentialsExplicitOrigin.bend as CorsCredentialsExplicitOrigin
import ./laws/CorsCredentialsReflectOrigin.bend as CorsCredentialsReflectOrigin
import ./laws/CorsExplicitOrigin.bend as CorsExplicitOrigin
import ./laws/CorsGetIsNotPreflight.bend as CorsGetIsNotPreflight
import ./laws/CorsOnPreflight.bend as CorsOnPreflight
import ./laws/CorsOriginHeader.bend as CorsOriginHeader
import ./laws/CorsPreflightAllowed.bend as CorsPreflightAllowed
import ./laws/CorsPreflightBad.bend as CorsPreflightBad
import ./laws/CorsPreflightHeaderCase.bend as CorsPreflightHeaderCase
import ./laws/CorsPreflightHeaderDenied.bend as CorsPreflightHeaderDenied
import ./laws/CorsPreflightMethodDenied.bend as CorsPreflightMethodDenied
import ./laws/CorsPreflightOriginDenied.bend as CorsPreflightOriginDenied
import ./laws/CorsPreflightStar.bend as CorsPreflightStar
import ./laws/CorsRefusedOrigin.bend as CorsRefusedOrigin
import ./laws/CorsRequestHeadersHeader.bend as CorsRequestHeadersHeader
import ./laws/CorsRequestMethodHeader.bend as CorsRequestMethodHeader
import ./laws/CorsSimpleReflects.bend as CorsSimpleReflects
import ./laws/CorsSimpleRefused.bend as CorsSimpleRefused
import ./laws/CorsSimpleStar.bend as CorsSimpleStar
import ./laws/CorsStarWithoutCredentials.bend as CorsStarWithoutCredentials
import ./laws/CorsVaryEmpty.bend as CorsVaryEmpty
import ./laws/CorsVarySpecific.bend as CorsVarySpecific
import ./laws/CorsVaryStar.bend as CorsVaryStar
import ./laws/CutAtFirstEquals.bend as CutAtFirstEquals
import ./laws/DeadlineIsTimeout.bend as DeadlineIsTimeout
import ./laws/DechunkEmpty.bend as DechunkEmpty
import ./laws/DechunkIgnoresExtension.bend as DechunkIgnoresExtension
import ./laws/DechunkOnlyLast.bend as DechunkOnlyLast
import ./laws/DechunkStopsAtZero.bend as DechunkStopsAtZero
import ./laws/DechunkTwoChunks.bend as DechunkTwoChunks
import ./laws/DechunkWiki.bend as DechunkWiki
import ./laws/DeleteReqNamesPath.bend as DeleteReqNamesPath
import ./laws/DfltHttps.bend as DfltHttps
import ./laws/DfltPlain.bend as DfltPlain
import ./laws/DigitsReadDecimal.bend as DigitsReadDecimal
import ./laws/DigitsReadRejectsJunk.bend as DigitsReadRejectsJunk
import ./laws/DotSegmentsRemoved.bend as DotSegmentsRemoved
import ./laws/ErrnoNamesAreLinux.bend as ErrnoNamesAreLinux
import ./laws/ExchangeCarriesMethod.bend as ExchangeCarriesMethod
import ./laws/FailedEffectsLoseConnection.bend as FailedEffectsLoseConnection
import ./laws/FailuresReportedByPhase.bend as FailuresReportedByPhase
import ./laws/FirstIsFirstWord.bend as FirstIsFirstWord
import ./laws/FormBodyLayout.bend as FormBodyLayout
import ./laws/FormBoundaryRules.bend as FormBoundaryRules
import ./laws/FormNamesEscaped.bend as FormNamesEscaped
import ./laws/FormPartHeaders.bend as FormPartHeaders
import ./laws/FormRefusesBadRequests.bend as FormRefusesBadRequests
import ./laws/FreshMaxAgeLimit.bend as FreshMaxAgeLimit
import ./laws/FreshMaxAgeOne.bend as FreshMaxAgeOne
import ./laws/FreshMaxAgeOpen.bend as FreshMaxAgeOpen
import ./laws/FreshMaxAgeOverridesExpires.bend as FreshMaxAgeOverridesExpires
import ./laws/FreshMaxAgeZero.bend as FreshMaxAgeZero
import ./laws/FreshNoCache.bend as FreshNoCache
import ./laws/FreshNoCacheAny.bend as FreshNoCacheAny
import ./laws/FreshNoStore.bend as FreshNoStore
import ./laws/FreshNoStoreAny.bend as FreshNoStoreAny
import ./laws/FreshPublicOnly.bend as FreshPublicOnly
import ./laws/GetOmitsContentLength.bend as GetOmitsContentLength
import ./laws/GetReplyKeepsBody.bend as GetReplyKeepsBody
import ./laws/GetReqNamesPath.bend as GetReqNamesPath
import ./laws/HandlerGetsRequestText.bend as HandlerGetsRequestText
import ./laws/HeadAndNoContentHaveNoBody.bend as HeadAndNoContentHaveNoBody
import ./laws/HeadHitIgnoresCase.bend as HeadHitIgnoresCase
import ./laws/HeadLineRejectsContinuation.bend as HeadLineRejectsContinuation
import ./laws/HeadLineRejectsObsFold.bend as HeadLineRejectsObsFold
import ./laws/HeadLineTrims.bend as HeadLineTrims
import ./laws/HeadPlannedBeforeBody.bend as HeadPlannedBeforeBody
import ./laws/HeadReplyDropsBody.bend as HeadReplyDropsBody
import ./laws/HeadReqNamesPath.bend as HeadReqNamesPath
import ./laws/HeadersFindFirst.bend as HeadersFindFirst
import ./laws/HeadersFindIgnoresCase.bend as HeadersFindIgnoresCase
import ./laws/HeadersFindMissing.bend as HeadersFindMissing
import ./laws/HexlenAlpha.bend as HexlenAlpha
import ./laws/HexlenExtensionAndCase.bend as HexlenExtensionAndCase
import ./laws/HexlenIgnoresExtension.bend as HexlenIgnoresExtension
import ./laws/HtmlEscapeCharByChar.bend as HtmlEscapeCharByChar
import ./laws/HtmlEscapeIsSafe.bend as HtmlEscapeIsSafe
import ./laws/HtmlEscapesFiveChars.bend as HtmlEscapesFiveChars
import ./laws/HtmlKeepsOtherChars.bend as HtmlKeepsOtherChars
import ./laws/InterimResponsesSkipped.bend as InterimResponsesSkipped
import ./laws/InterimStatusIs1xx.bend as InterimStatusIs1xx
import ./laws/JoinJoined.bend as JoinJoined
import ./laws/JsonParseRejects.bend as JsonParseRejects
import ./laws/JsonParseString.bend as JsonParseString
import ./laws/JsonStringIsTextBody.bend as JsonStringIsTextBody
import ./laws/LocationResolvedBySort.bend as LocationResolvedBySort
import ./laws/LocationSplitsAtQuery.bend as LocationSplitsAtQuery
import ./laws/MethodIdempotentDelete.bend as MethodIdempotentDelete
import ./laws/MethodIdempotentGet.bend as MethodIdempotentGet
import ./laws/MethodIdempotentHead.bend as MethodIdempotentHead
import ./laws/MethodIdempotentOptions.bend as MethodIdempotentOptions
import ./laws/MethodIdempotentPatch.bend as MethodIdempotentPatch
import ./laws/MethodIdempotentPost.bend as MethodIdempotentPost
import ./laws/MethodIdempotentPut.bend as MethodIdempotentPut
import ./laws/MethodSafeDelete.bend as MethodSafeDelete
import ./laws/MethodSafeGet.bend as MethodSafeGet
import ./laws/MethodSafeGetLower.bend as MethodSafeGetLower
import ./laws/MethodSafeHead.bend as MethodSafeHead
import ./laws/MethodSafeOptions.bend as MethodSafeOptions
import ./laws/MethodSafePost.bend as MethodSafePost
import ./laws/MethodSafePut.bend as MethodSafePut
import ./laws/MethodTokensAreCaseSensitive.bend as MethodTokensAreCaseSensitive
import ./laws/NamedReferencesLongestMatch.bend as NamedReferencesLongestMatch
import ./laws/NumericReferencesDecode.bend as NumericReferencesDecode
import ./laws/OctetBodiesSentUnchanged.bend as OctetBodiesSentUnchanged
import ./laws/OctetsDecodeAsUtf8.bend as OctetsDecodeAsUtf8
import ./laws/OneOctetPerChar.bend as OneOctetPerChar
import ./laws/OnlyGetFollows.bend as OnlyGetFollows
import ./laws/OptionsReqNamesPath.bend as OptionsReqNamesPath
import ./laws/OtherStatusesStopChain.bend as OtherStatusesStopChain
import ./laws/ParseChunkedBody.bend as ParseChunkedBody
import ./laws/ParseChunkedIgnoresCase.bend as ParseChunkedIgnoresCase
import ./laws/ParseClenTakesPrefix.bend as ParseClenTakesPrefix
import ./laws/ParseEqualContentLengths.bend as ParseEqualContentLengths
import ./laws/ParseNeedsBlankLine.bend as ParseNeedsBlankLine
import ./laws/ParseNeedsSlashes.bend as ParseNeedsSlashes
import ./laws/ParseNeedsStatus.bend as ParseNeedsStatus
import ./laws/ParseQuerySplitsPairs.bend as ParseQuerySplitsPairs
import ./laws/ParseRejectsClAndTe.bend as ParseRejectsClAndTe
import ./laws/ParseRejectsDisagreeingCl.bend as ParseRejectsDisagreeingCl
import ./laws/ParseRejectsNonHexChunk.bend as ParseRejectsNonHexChunk
import ./laws/ParseSchemeFirst.bend as ParseSchemeFirst
import ./laws/PathAbsolute.bend as PathAbsolute
import ./laws/PathFormKeepsSlash.bend as PathFormKeepsSlash
import ./laws/PhraseTableLookup.bend as PhraseTableLookup
import ./laws/PostReqNamesPath.bend as PostReqNamesPath
import ./laws/PostWritesContentLength.bend as PostWritesContentLength
import ./laws/PutReqNamesPath.bend as PutReqNamesPath
import ./laws/QueryGetLastWins.bend as QueryGetLastWins
import ./laws/QuoteEscapesUtf8Bytes.bend as QuoteEscapesUtf8Bytes
import ./laws/QuoteKeepsUnreserved.bend as QuoteKeepsUnreserved
import ./laws/QuoteOutputIsFramed.bend as QuoteOutputIsFramed
import ./laws/QuotePlusWritesSpaces.bend as QuotePlusWritesSpaces
import ./laws/ReadStateMatchesWholeText.bend as ReadStateMatchesWholeText
import ./laws/ReadsJudgedByCount.bend as ReadsJudgedByCount
import ./laws/Reason200.bend as Reason200
import ./laws/Reason201.bend as Reason201
import ./laws/Reason204.bend as Reason204
import ./laws/Reason400.bend as Reason400
import ./laws/Reason404.bend as Reason404
import ./laws/Reason405.bend as Reason405
import ./laws/Reason500.bend as Reason500
import ./laws/ReasonPhraseFromFinalHead.bend as ReasonPhraseFromFinalHead
import ./laws/ReasonPhrasesFollowRfc.bend as ReasonPhrasesFollowRfc
import ./laws/ReasonUnknownEmpty.bend as ReasonUnknownEmpty
import ./laws/RedirectsFollowLocation.bend as RedirectsFollowLocation
import ./laws/RelativeLocationsMerge.bend as RelativeLocationsMerge
import ./laws/ReplyHeadFramesBody.bend as ReplyHeadFramesBody
import ./laws/RequestHeaderFieldsOrdered.bend as RequestHeaderFieldsOrdered
import ./laws/RequestLineAndHost.bend as RequestLineAndHost
import ./laws/RequestNamesMethod.bend as RequestNamesMethod
import ./laws/Respond200KeepsBody.bend as Respond200KeepsBody
import ./laws/Respond204DropsBody.bend as Respond204DropsBody
import ./laws/Respond304DropsBody.bend as Respond304DropsBody
import ./laws/RespondOpensWithVersion.bend as RespondOpensWithVersion
import ./laws/ResponseCompleteByFraming.bend as ResponseCompleteByFraming
import ./laws/SecondIsNextWord.bend as SecondIsNextWord
import ./laws/SetCookieFieldsSelected.bend as SetCookieFieldsSelected
import ./laws/SetCookieReadsPair.bend as SetCookieReadsPair
import ./laws/ShowReplyOpensWithStatus.bend as ShowReplyOpensWithStatus
import ./laws/ShowTornIsMarked.bend as ShowTornIsMarked
import ./laws/SplitAtCharacter.bend as SplitAtCharacter
import ./laws/StreamedRepliesAreChunked.bend as StreamedRepliesAreChunked
import ./laws/TimeoutZeroIsOneMs.bend as TimeoutZeroIsOneMs
import ./laws/TimeoutsReadAsTimedOut.bend as TimeoutsReadAsTimedOut
import ./laws/TokenOkNewline.bend as TokenOkNewline
import ./laws/TokenOkPlain.bend as TokenOkPlain
import ./laws/TokenOkSpace.bend as TokenOkSpace
import ./laws/TokenOkTab.bend as TokenOkTab
import ./laws/UnescapeFindsReferences.bend as UnescapeFindsReferences
import ./laws/UnescapeUndoesEscape.bend as UnescapeUndoesEscape
import ./laws/UnframedIsRest.bend as UnframedIsRest
import ./laws/UnquotePlusReadsSpaces.bend as UnquotePlusReadsSpaces
import ./laws/UnquoteReadsEscapes.bend as UnquoteReadsEscapes
import ./laws/UrlBadPortUsesDefault.bend as UrlBadPortUsesDefault
import ./laws/UrlEmptyPath.bend as UrlEmptyPath
import ./laws/UrlFragmentHidesQuery.bend as UrlFragmentHidesQuery
import ./laws/UrlHttpDefaultPort.bend as UrlHttpDefaultPort
import ./laws/UrlHttpsDefaultPort.bend as UrlHttpsDefaultPort
import ./laws/UrlHttpsExplicitPort.bend as UrlHttpsExplicitPort
import ./laws/UrlIpv4Host.bend as UrlIpv4Host
import ./laws/UrlIpv4Port.bend as UrlIpv4Port
import ./laws/UrlQueryDropsFragment.bend as UrlQueryDropsFragment
import ./laws/UrlQueryKeepsQuestion.bend as UrlQueryKeepsQuestion
import ./laws/UrlQueryOnEmptyPath.bend as UrlQueryOnEmptyPath
import ./laws/UrlSchemeLowercased.bend as UrlSchemeLowercased
import ./laws/UrlShowBadIsMarked.bend as UrlShowBadIsMarked
import ./laws/UrlShowOpensWithScheme.bend as UrlShowOpensWithScheme
import ./laws/UrlTrailingSlash.bend as UrlTrailingSlash
import ./laws/UrlUserinfoLastAt.bend as UrlUserinfoLastAt
import ./laws/UrlUserinfoStripped.bend as UrlUserinfoStripped
import ./laws/UrlencodeJoinsPairs.bend as UrlencodeJoinsPairs
import ./laws/Utf8DecodesWithReplacement.bend as Utf8DecodesWithReplacement
import ./laws/Utf8Split.bend as Utf8Split
import ./laws/WithServesGetOctetsAndContext.bend as WithServesGetOctetsAndContext

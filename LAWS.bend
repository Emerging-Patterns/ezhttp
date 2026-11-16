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
# ezhttp's other laws hold internal behavior in place, each a closed equality
# on one input, for URL parsing (RFC 3986), HTTP/1.1 message framing (RFC
# 9112), HTTP semantics (RFC 9110), TLS selection (RFC 2818), Basic and Bearer
# credentials (RFC 7617, RFC 4648, RFC 6750), the cookie jar in
# src/cookie.bend (RFC 6265), caching directives (RFC 9111) and Fetch CORS.
# Each is a file of its own holding one law, named for what the law states,
# with no prose yet (laws/UrlPathIsAbsolute.bend,
# laws/CacheReadsKnownDirectives.bend).
#
# Commits before these files name guarantees by the requirement IDs of
# docs/SPEC.md, the table these files replaced.
import Base
import ./laws/AbsoluteFormTargetRejected.bend as AbsoluteFormTargetRejected
import ./laws/AbsoluteLocationsResolve.bend as AbsoluteLocationsResolve
import ./laws/BadRequestAnswers400.bend as BadRequestAnswers400
import ./laws/BadRequestShowIsMarked.bend as BadRequestShowIsMarked
import ./laws/BareRepliesWriteHeadOnly.bend as BareRepliesWriteHeadOnly
import ./laws/Base64PadsFinalQuantum.bend as Base64PadsFinalQuantum
import ./laws/BasicIsBase64OfUserPassword.bend as BasicIsBase64OfUserPassword
import ./laws/BearerIsAuthorization.bend as BearerIsAuthorization
import ./laws/CacheReadsKnownDirectives.bend as CacheReadsKnownDirectives
import ./laws/CacheRecordsExpires.bend as CacheRecordsExpires
import ./laws/CacheRecordsMaxAge.bend as CacheRecordsMaxAge
import ./laws/ChunkDataUnchanged.bend as ChunkDataUnchanged
import ./laws/ChunkSizeHexIgnoresCase.bend as ChunkSizeHexIgnoresCase
import ./laws/ChunkSizeIgnoresExtension.bend as ChunkSizeIgnoresExtension
import ./laws/ChunkedBodyJoinsChunks.bend as ChunkedBodyJoinsChunks
import ./laws/ChunksStopWithoutFuel.bend as ChunksStopWithoutFuel
import ./laws/ContentLengthFramesBody.bend as ContentLengthFramesBody
import ./laws/ContentLengthReadsDecimal.bend as ContentLengthReadsDecimal
import ./laws/ContentLengthRejectsJunk.bend as ContentLengthRejectsJunk
import ./laws/ContinuationLineRejected.bend as ContinuationLineRejected
import ./laws/CookieAliveUnderMaxAge.bend as CookieAliveUnderMaxAge
import ./laws/CookieAttributesJoinWithSemicolons.bend as CookieAttributesJoinWithSemicolons
import ./laws/CookieDefaultPathFallsBackToRoot.bend as CookieDefaultPathFallsBackToRoot
import ./laws/CookieDefaultPathIsDirectory.bend as CookieDefaultPathIsDirectory
import ./laws/CookieDomainLowercased.bend as CookieDomainLowercased
import ./laws/CookieDomainMatchesDotSuffix.bend as CookieDomainMatchesDotSuffix
import ./laws/CookieHeaderEchoesStore.bend as CookieHeaderEchoesStore
import ./laws/CookieHostOnlyNotSentElsewhere.bend as CookieHostOnlyNotSentElsewhere
import ./laws/CookieHostOnlySentToHost.bend as CookieHostOnlySentToHost
import ./laws/CookieHostOnlyStoresHost.bend as CookieHostOnlyStoresHost
import ./laws/CookieIdenticalPathsMatch.bend as CookieIdenticalPathsMatch
import ./laws/CookieInsecureSentOnCleartext.bend as CookieInsecureSentOnCleartext
import ./laws/CookieIpHostMatchesExactly.bend as CookieIpHostMatchesExactly
import ./laws/CookieIpHostNoSuffixMatch.bend as CookieIpHostNoSuffixMatch
import ./laws/CookieLongerPathFails.bend as CookieLongerPathFails
import ./laws/CookieMaxAgeIgnoresJunk.bend as CookieMaxAgeIgnoresJunk
import ./laws/CookieMaxAgeSetsAge.bend as CookieMaxAgeSetsAge
import ./laws/CookieNameIsNotIpv4.bend as CookieNameIsNotIpv4
import ./laws/CookiePathMatchesSlashPrefix.bend as CookiePathMatchesSlashPrefix
import ./laws/CookiePathNeedsSegmentBoundary.bend as CookiePathNeedsSegmentBoundary
import ./laws/CookieRecognizesIpv4Literal.bend as CookieRecognizesIpv4Literal
import ./laws/CookieRejectsEmptyName.bend as CookieRejectsEmptyName
import ./laws/CookieRequestJoinsPairs.bend as CookieRequestJoinsPairs
import ./laws/CookieSameSiteFoldsCase.bend as CookieSameSiteFoldsCase
import ./laws/CookieSecureNeedsTls.bend as CookieSecureNeedsTls
import ./laws/CookieSlashEndedPathIsPrefix.bend as CookieSlashEndedPathIsPrefix
import ./laws/CorsAllowListReflectsOrigin.bend as CorsAllowListReflectsOrigin
import ./laws/CorsAllowedPreflightIs200.bend as CorsAllowedPreflightIs200
import ./laws/CorsBadPreflightIs400.bend as CorsBadPreflightIs400
import ./laws/CorsCredentialsReflectOrigin.bend as CorsCredentialsReflectOrigin
import ./laws/CorsGetIsNotPreflight.bend as CorsGetIsNotPreflight
import ./laws/CorsNoVaryForStar.bend as CorsNoVaryForStar
import ./laws/CorsNoVaryWhenRefused.bend as CorsNoVaryWhenRefused
import ./laws/CorsOptionsWithMethodIsPreflight.bend as CorsOptionsWithMethodIsPreflight
import ./laws/CorsPreflightHeaderDenied.bend as CorsPreflightHeaderDenied
import ./laws/CorsPreflightHeadersIgnoreCase.bend as CorsPreflightHeadersIgnoreCase
import ./laws/CorsPreflightMethodDenied.bend as CorsPreflightMethodDenied
import ./laws/CorsPreflightOriginDenied.bend as CorsPreflightOriginDenied
import ./laws/CorsReadsOriginHeader.bend as CorsReadsOriginHeader
import ./laws/CorsReadsRequestHeaders.bend as CorsReadsRequestHeaders
import ./laws/CorsReadsRequestMethod.bend as CorsReadsRequestMethod
import ./laws/CorsRefusedLeavesReply.bend as CorsRefusedLeavesReply
import ./laws/CorsRefusesMissingOrigin.bend as CorsRefusesMissingOrigin
import ./laws/CorsSimpleKeepsBody.bend as CorsSimpleKeepsBody
import ./laws/CorsStarStaysStar.bend as CorsStarStaysStar
import ./laws/CorsVaryOnSpecificOrigin.bend as CorsVaryOnSpecificOrigin
import ./laws/CutAtFirstEquals.bend as CutAtFirstEquals
import ./laws/DeadlineIsTimeout.bend as DeadlineIsTimeout
import ./laws/DechunkEmptyIsEmpty.bend as DechunkEmptyIsEmpty
import ./laws/DeleteRequestLine.bend as DeleteRequestLine
import ./laws/DotSegmentsRemoved.bend as DotSegmentsRemoved
import ./laws/ErrnoNamesAreLinux.bend as ErrnoNamesAreLinux
import ./laws/ExactContentLengthBodyKept.bend as ExactContentLengthBodyKept
import ./laws/ExchangeCarriesMethod.bend as ExchangeCarriesMethod
import ./laws/FailedEffectsLoseConnection.bend as FailedEffectsLoseConnection
import ./laws/MaxZeroIsNoLimit.bend as MaxZeroIsNoLimit
import ./laws/FailuresReportedByPhase.bend as FailuresReportedByPhase
import ./laws/FieldLookupFindsFirst.bend as FieldLookupFindsFirst
import ./laws/FieldNamesIgnoreCase.bend as FieldNamesIgnoreCase
import ./laws/FieldValueTrimsWhitespace.bend as FieldValueTrimsWhitespace
import ./laws/FirstIsFirstWord.bend as FirstIsFirstWord
import ./laws/FormBodyLayout.bend as FormBodyLayout
import ./laws/FormBoundaryRules.bend as FormBoundaryRules
import ./laws/FormNamesEscaped.bend as FormNamesEscaped
import ./laws/FormPartHeaders.bend as FormPartHeaders
import ./laws/FormRefusesBadRequests.bend as FormRefusesBadRequests
import ./laws/FreshUnderMaxAge.bend as FreshUnderMaxAge
import ./laws/GetAsteriskTargetRejected.bend as GetAsteriskTargetRejected
import ./laws/GetRequestLine.bend as GetRequestLine
import ./laws/HandlerGetsRequestText.bend as HandlerGetsRequestText
import ./laws/HeadAndNoContentHaveNoBody.bend as HeadAndNoContentHaveNoBody
import ./laws/HeadPlannedBeforeBody.bend as HeadPlannedBeforeBody
import ./laws/HeadRequestLine.bend as HeadRequestLine
import ./laws/HtmlEscapeCharByChar.bend as HtmlEscapeCharByChar
import ./laws/HtmlEscapeIsSafe.bend as HtmlEscapeIsSafe
import ./laws/HtmlEscapesFiveChars.bend as HtmlEscapesFiveChars
import ./laws/HtmlKeepsOtherChars.bend as HtmlKeepsOtherChars
import ./laws/HttpsDefaultsTo443.bend as HttpsDefaultsTo443
import ./laws/InterimResponsesSkipped.bend as InterimResponsesSkipped
import ./laws/InterimStatusIs1xx.bend as InterimStatusIs1xx
import ./laws/JoinedPiecesAreText.bend as JoinedPiecesAreText
import ./laws/JsonStringIsTextBody.bend as JsonStringIsTextBody
import ./laws/LocationResolvedBySort.bend as LocationResolvedBySort
import ./laws/LocationSplitsAtQuery.bend as LocationSplitsAtQuery
import ./laws/MethodTokensAreCaseSensitive.bend as MethodTokensAreCaseSensitive
import ./laws/MissingFieldIsEmpty.bend as MissingFieldIsEmpty
import ./laws/NamedReferencesLongestMatch.bend as NamedReferencesLongestMatch
import ./laws/NoCacheNeverFresh.bend as NoCacheNeverFresh
import ./laws/NoMaxAgeNotFresh.bend as NoMaxAgeNotFresh
import ./laws/NoStoreNeverFresh.bend as NoStoreNeverFresh
import ./laws/NonHexChunkSizeTorn.bend as NonHexChunkSizeTorn
import ./laws/NumericReferencesDecode.bend as NumericReferencesDecode
import ./laws/ObsFoldRejected.bend as ObsFoldRejected
import ./laws/OctetBodiesSentUnchanged.bend as OctetBodiesSentUnchanged
import ./laws/OctetsDecodeAsUtf8.bend as OctetsDecodeAsUtf8
import ./laws/OneOctetPerChar.bend as OneOctetPerChar
import ./laws/OnlyGetFollows.bend as OnlyGetFollows
import ./laws/OptionsAsteriskNamesServer.bend as OptionsAsteriskNamesServer
import ./laws/OptionsRequestLine.bend as OptionsRequestLine
import ./laws/OriginFormKeepsQuery.bend as OriginFormKeepsQuery
import ./laws/OtherSchemesDefaultTo80.bend as OtherSchemesDefaultTo80
import ./laws/OtherStatusesStopChain.bend as OtherStatusesStopChain
import ./laws/ParseQuerySplitsPairs.bend as ParseQuerySplitsPairs
import ./laws/PathFormKeepsSlash.bend as PathFormKeepsSlash
import ./laws/PhraseTableLookup.bend as PhraseTableLookup
import ./laws/PostRequestLine.bend as PostRequestLine
import ./laws/PutRequestLine.bend as PutRequestLine
import ./laws/QueryGetLastWins.bend as QueryGetLastWins
import ./laws/QuoteEscapesUtf8Bytes.bend as QuoteEscapesUtf8Bytes
import ./laws/QuoteKeepsUnreserved.bend as QuoteKeepsUnreserved
import ./laws/QuoteOutputIsFramed.bend as QuoteOutputIsFramed
import ./laws/QuotePlusWritesSpaces.bend as QuotePlusWritesSpaces
import ./laws/ReadStateMatchesWholeText.bend as ReadStateMatchesWholeText
import ./laws/ReadsJudgedByCount.bend as ReadsJudgedByCount
import ./laws/ReasonPhraseFromFinalHead.bend as ReasonPhraseFromFinalHead
import ./laws/ReasonPhrasesFollowRfc.bend as ReasonPhrasesFollowRfc
import ./laws/RedirectsFollowLocation.bend as RedirectsFollowLocation
import ./laws/RelativeLocationsMerge.bend as RelativeLocationsMerge
import ./laws/ReplyHeadFramesBody.bend as ReplyHeadFramesBody
import ./laws/RequestBodyOfContentLengthKept.bend as RequestBodyOfContentLengthKept
import ./laws/RequestDisagreeingContentLengthsRejected.bend as RequestDisagreeingContentLengthsRejected
import ./laws/RequestEqualContentLengthsFrameOneBody.bend as RequestEqualContentLengthsFrameOneBody
import ./laws/RequestHeaderFieldsOrdered.bend as RequestHeaderFieldsOrdered
import ./laws/RequestKeepsFieldNameSpelling.bend as RequestKeepsFieldNameSpelling
import ./laws/RequestLineAndHost.bend as RequestLineAndHost
import ./laws/RequestLineOpensWithMethod.bend as RequestLineOpensWithMethod
import ./laws/RequestNeedsBlankLine.bend as RequestNeedsBlankLine
import ./laws/RequestNeedsRequestLine.bend as RequestNeedsRequestLine
import ./laws/RequestWithBothFramingsRejected.bend as RequestWithBothFramingsRejected
import ./laws/RespondOpensWithVersion.bend as RespondOpensWithVersion
import ./laws/ResponseCompleteByFraming.bend as ResponseCompleteByFraming
import ./laws/ResponseNeedsBlankLine.bend as ResponseNeedsBlankLine
import ./laws/ResponseNeedsStatus.bend as ResponseNeedsStatus
import ./laws/SchemeBeforeFirstColon.bend as SchemeBeforeFirstColon
import ./laws/SecondIsNextWord.bend as SecondIsNextWord
import ./laws/SetCookieFieldsSelected.bend as SetCookieFieldsSelected
import ./laws/SetCookieParsesBack.bend as SetCookieParsesBack
import ./laws/SetCookieReadsPair.bend as SetCookieReadsPair
import ./laws/ShortRequestBodyIsBad.bend as ShortRequestBodyIsBad
import ./laws/ShowReplyOpensWithStatus.bend as ShowReplyOpensWithStatus
import ./laws/ShowTornIsMarked.bend as ShowTornIsMarked
import ./laws/SplitAtCharacter.bend as SplitAtCharacter
import ./laws/StreamedRepliesAreChunked.bend as StreamedRepliesAreChunked
import ./laws/TakeDropSplitAtOneOffset.bend as TakeDropSplitAtOneOffset
import ./laws/TimeoutZeroIsOneMs.bend as TimeoutZeroIsOneMs
import ./laws/TimeoutsReadAsTimedOut.bend as TimeoutsReadAsTimedOut
import ./laws/UnescapeFindsReferences.bend as UnescapeFindsReferences
import ./laws/UnescapeUndoesEscape.bend as UnescapeUndoesEscape
import ./laws/UnframedBodyIsRest.bend as UnframedBodyIsRest
import ./laws/UnquotePlusReadsSpaces.bend as UnquotePlusReadsSpaces
import ./laws/UnquoteReadsEscapes.bend as UnquoteReadsEscapes
import ./laws/UrlBadPortUsesDefault.bend as UrlBadPortUsesDefault
import ./laws/UrlEmptyPath.bend as UrlEmptyPath
import ./laws/UrlFragmentHidesQuery.bend as UrlFragmentHidesQuery
import ./laws/UrlHttpDefaultPort.bend as UrlHttpDefaultPort
import ./laws/UrlHttpsExplicitPort.bend as UrlHttpsExplicitPort
import ./laws/UrlIpv4Host.bend as UrlIpv4Host
import ./laws/UrlNeedsSlashes.bend as UrlNeedsSlashes
import ./laws/UrlPathIsAbsolute.bend as UrlPathIsAbsolute
import ./laws/UrlQueryKeepsQuestion.bend as UrlQueryKeepsQuestion
import ./laws/UrlQueryOnEmptyPath.bend as UrlQueryOnEmptyPath
import ./laws/UrlShowBadIsMarked.bend as UrlShowBadIsMarked
import ./laws/UrlShowOpensWithScheme.bend as UrlShowOpensWithScheme
import ./laws/UrlTrailingSlash.bend as UrlTrailingSlash
import ./laws/UrlUserinfoLastAt.bend as UrlUserinfoLastAt
import ./laws/UrlencodeJoinsPairs.bend as UrlencodeJoinsPairs
import ./laws/Utf8DecodesWithReplacement.bend as Utf8DecodesWithReplacement
import ./laws/WithServesGetOctetsAndContext.bend as WithServesGetOctetsAndContext
import ./laws/Base64EncodesByQuantum.bend as Base64EncodesByQuantum
import ./laws/BearerTokenHasNoWhitespace.bend as BearerTokenHasNoWhitespace
import ./laws/JsonParseIsEzjsonParse.bend as JsonParseIsEzjsonParse
import ./laws/MethodsSafeAndIdempotent.bend as MethodsSafeAndIdempotent

#import <ParseKit/PEGParser.h>

enum {
    GREEDYFAILURENESTED_TOKEN_KIND_COMMA = 14,
    GREEDYFAILURENESTED_TOKEN_KIND_COLON,
    GREEDYFAILURENESTED_TOKEN_KIND_RCURLY,
    GREEDYFAILURENESTED_TOKEN_KIND_LCURLY,
};

@interface GreedyFailureNestedParser : PEGParser

@end

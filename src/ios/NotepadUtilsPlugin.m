#import "NotepadUtilsPlugin.h"
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonKeyDerivation.h>

@implementation NotepadUtilsPlugin {
    NSMutableArray<NSString *> *undoHistory;
    NSInteger currentHistoryPosition;
    NSInteger maxHistorySize;
}

- (void)pluginInitialize {
    [super pluginInitialize];
    undoHistory = [NSMutableArray array];
    currentHistoryPosition = -1;
    maxHistorySize = 100;
}

#pragma mark - Clipboard Operations

- (void)getClipboard:(CDVInvokedUrlCommand *)command {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    NSString *text = pasteboard.string ?: @"";
    result[@"text"] = text;
    result[@"hasContent"] = @(text.length > 0);
    result[@"contentType"] = @"text";
    result[@"timestamp"] = @((NSInteger)([[NSDate date] timeIntervalSince1970] * 1000));

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setClipboard:(CDVInvokedUrlCommand *)command {
    NSDictionary *options = [command.arguments objectAtIndex:0];
    NSString *text = options[@"text"] ?: @"";

    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = text;

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)clearClipboard:(CDVInvokedUrlCommand *)command {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = @"";

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark - Text Statistics

- (void)getTextStats:(CDVInvokedUrlCommand *)command {
    NSString *text = [command.arguments objectAtIndex:0];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    // Character counts
    result[@"characterCount"] = @(text.length);
    NSString *noSpaces = [text stringByReplacingOccurrencesOfString:@" " withString:@""];
    noSpaces = [noSpaces stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    noSpaces = [noSpaces stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    result[@"characterCountNoSpaces"] = @(noSpaces.length);

    // Word count
    NSArray *words = [self wordsFromText:text];
    result[@"wordCount"] = @(words.count);

    // Unique words
    NSSet *uniqueWords = [NSSet setWithArray:[words valueForKey:@"lowercaseString"]];
    result[@"uniqueWordCount"] = @(uniqueWords.count);

    // Sentence count
    NSRegularExpression *sentenceRegex = [NSRegularExpression regularExpressionWithPattern:@"[.!?]+" options:0 error:nil];
    NSArray *sentences = [sentenceRegex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    result[@"sentenceCount"] = @(MAX(sentences.count, text.length > 0 ? 1 : 0));

    // Paragraph count
    NSArray *paragraphs = [text componentsSeparatedByString:@"\n\n"];
    NSInteger paragraphCount = 0;
    for (NSString *p in paragraphs) {
        if ([p stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
            paragraphCount++;
        }
    }
    result[@"paragraphCount"] = @(MAX(paragraphCount, text.length > 0 ? 1 : 0));

    // Line count
    NSArray *lines = [text componentsSeparatedByString:@"\n"];
    result[@"lineCount"] = @(lines.count);

    // Average word length
    double avgLength = 0;
    if (words.count > 0) {
        NSInteger totalChars = 0;
        for (NSString *word in words) {
            totalChars += word.length;
        }
        avgLength = (double)totalChars / words.count;
    }
    result[@"averageWordLength"] = @(round(avgLength * 100) / 100);

    // Reading time (200 words per minute)
    double readingTime = words.count / 200.0;
    result[@"readingTimeMinutes"] = @(round(readingTime * 100) / 100);

    // Speaking time (150 words per minute)
    double speakingTime = words.count / 150.0;
    result[@"speakingTimeMinutes"] = @(round(speakingTime * 100) / 100);

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSArray *)wordsFromText:(NSString *)text {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return @[];

    NSArray *components = [trimmed componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableArray *words = [NSMutableArray array];
    for (NSString *word in components) {
        if (word.length > 0) {
            [words addObject:word];
        }
    }
    return words;
}

#pragma mark - Text Detection

- (void)detectPatterns:(CDVInvokedUrlCommand *)command {
    NSString *text = [command.arguments objectAtIndex:0];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    // URLs
    result[@"urls"] = [self findMatchesWithPattern:@"https?://[\\w\\-._~:/?#\\[\\]@!$&'()*+,;=%]+" inText:text];

    // Emails
    result[@"emails"] = [self findMatchesWithPattern:@"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}" inText:text];

    // Phone numbers
    result[@"phoneNumbers"] = [self findMatchesWithPattern:@"(\\+?\\d{1,3}[-.\\s]?)?(\\(?\\d{2,4}\\)?[-.\\s]?)?\\d{3,4}[-.\\s]?\\d{3,4}" inText:text];

    // Hashtags
    result[@"hashtags"] = [self findMatchesWithPattern:@"#[a-zA-Z0-9_]+" inText:text];

    // Mentions
    result[@"mentions"] = [self findMatchesWithPattern:@"@[a-zA-Z0-9_]+" inText:text];

    // Dates
    result[@"dates"] = [self findMatchesWithPattern:@"\\d{1,2}[/\\-.]\\d{1,2}[/\\-.]\\d{2,4}|\\d{4}[/\\-.]\\d{1,2}[/\\-.]\\d{1,2}" inText:text];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSArray *)findMatchesWithPattern:(NSString *)pattern inText:(NSString *)text {
    NSMutableArray *matches = [NSMutableArray array];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];

    if (regex && !error) {
        NSArray *results = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
        for (NSTextCheckingResult *match in results) {
            [matches addObject:[text substringWithRange:match.range]];
        }
    }
    return matches;
}

#pragma mark - Encryption

- (void)encrypt:(CDVInvokedUrlCommand *)command {
    NSString *text = [command.arguments objectAtIndex:0];
    NSString *password = [command.arguments objectAtIndex:1];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    @try {
        // Generate random salt and IV
        NSMutableData *salt = [NSMutableData dataWithLength:16];
        NSMutableData *iv = [NSMutableData dataWithLength:16];
        SecRandomCopyBytes(kSecRandomDefault, 16, salt.mutableBytes);
        SecRandomCopyBytes(kSecRandomDefault, 16, iv.mutableBytes);

        // Derive key from password
        NSData *keyData = [self deriveKeyFromPassword:password salt:salt];

        // Encrypt
        NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableData *encryptedData = [NSMutableData dataWithLength:textData.length + kCCBlockSizeAES128];
        size_t encryptedLength = 0;

        CCCryptorStatus status = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,
                                          keyData.bytes, kCCKeySizeAES256,
                                          iv.bytes,
                                          textData.bytes, textData.length,
                                          encryptedData.mutableBytes, encryptedData.length,
                                          &encryptedLength);

        if (status == kCCSuccess) {
            encryptedData.length = encryptedLength;
            result[@"encryptedData"] = [encryptedData base64EncodedStringWithOptions:0];
            result[@"iv"] = [iv base64EncodedStringWithOptions:0];
            result[@"salt"] = [salt base64EncodedStringWithOptions:0];
            result[@"success"] = @YES;
        } else {
            result[@"success"] = @NO;
            result[@"error"] = @"Encryption failed";
        }
    } @catch (NSException *exception) {
        result[@"success"] = @NO;
        result[@"error"] = exception.reason;
    }

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)decrypt:(CDVInvokedUrlCommand *)command {
    NSString *encryptedDataStr = [command.arguments objectAtIndex:0];
    NSString *password = [command.arguments objectAtIndex:1];
    NSString *ivStr = [command.arguments objectAtIndex:2];
    NSString *saltStr = [command.arguments objectAtIndex:3];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    @try {
        NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:encryptedDataStr options:0];
        NSData *iv = [[NSData alloc] initWithBase64EncodedString:ivStr options:0];
        NSData *salt = [[NSData alloc] initWithBase64EncodedString:saltStr options:0];

        // Derive key from password
        NSData *keyData = [self deriveKeyFromPassword:password salt:salt];

        // Decrypt
        NSMutableData *decryptedData = [NSMutableData dataWithLength:encryptedData.length + kCCBlockSizeAES128];
        size_t decryptedLength = 0;

        CCCryptorStatus status = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,
                                          keyData.bytes, kCCKeySizeAES256,
                                          iv.bytes,
                                          encryptedData.bytes, encryptedData.length,
                                          decryptedData.mutableBytes, decryptedData.length,
                                          &decryptedLength);

        if (status == kCCSuccess) {
            decryptedData.length = decryptedLength;
            result[@"decryptedText"] = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
            result[@"success"] = @YES;
        } else {
            result[@"success"] = @NO;
            result[@"error"] = @"Decryption failed - wrong password or corrupted data";
        }
    } @catch (NSException *exception) {
        result[@"success"] = @NO;
        result[@"error"] = exception.reason;
    }

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSData *)deriveKeyFromPassword:(NSString *)password salt:(NSData *)salt {
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *derivedKey = [NSMutableData dataWithLength:kCCKeySizeAES256];

    CCKeyDerivationPBKDF(kCCPBKDF2,
                         passwordData.bytes, passwordData.length,
                         salt.bytes, salt.length,
                         kCCPRFHmacAlgSHA256,
                         65536,
                         derivedKey.mutableBytes, derivedKey.length);

    return derivedKey;
}

- (void)hash:(CDVInvokedUrlCommand *)command {
    NSString *text = [command.arguments objectAtIndex:0];
    NSString *algorithm = [command.arguments objectAtIndex:1];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    @try {
        NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableData *hashData;

        if ([algorithm isEqualToString:@"MD5"]) {
            hashData = [NSMutableData dataWithLength:CC_MD5_DIGEST_LENGTH];
            CC_MD5(data.bytes, (CC_LONG)data.length, hashData.mutableBytes);
        } else if ([algorithm isEqualToString:@"SHA-512"]) {
            hashData = [NSMutableData dataWithLength:CC_SHA512_DIGEST_LENGTH];
            CC_SHA512(data.bytes, (CC_LONG)data.length, hashData.mutableBytes);
        } else {
            hashData = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
            CC_SHA256(data.bytes, (CC_LONG)data.length, hashData.mutableBytes);
            algorithm = @"SHA-256";
        }

        NSMutableString *hexString = [NSMutableString string];
        const unsigned char *bytes = hashData.bytes;
        for (NSUInteger i = 0; i < hashData.length; i++) {
            [hexString appendFormat:@"%02x", bytes[i]];
        }

        result[@"hash"] = hexString;
        result[@"algorithm"] = algorithm;
        result[@"success"] = @YES;
    } @catch (NSException *exception) {
        result[@"success"] = @NO;
        result[@"error"] = exception.reason;
    }

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark - Search & Replace

- (void)search:(CDVInvokedUrlCommand *)command {
    NSString *text = [command.arguments objectAtIndex:0];
    NSString *searchTerm = [command.arguments objectAtIndex:1];
    BOOL caseSensitive = [[command.arguments objectAtIndex:2] boolValue];
    BOOL isRegex = [[command.arguments objectAtIndex:3] boolValue];

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSMutableArray *matches = [NSMutableArray array];

    @try {
        NSRegularExpressionOptions options = caseSensitive ? 0 : NSRegularExpressionCaseInsensitive;
        NSString *pattern = isRegex ? searchTerm : [NSRegularExpression escapedPatternForString:searchTerm];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:nil];

        NSArray *lines = [text componentsSeparatedByString:@"\n"];
        NSArray *results = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];

        for (NSTextCheckingResult *match in results) {
            NSMutableDictionary *matchDict = [NSMutableDictionary dictionary];
            matchDict[@"start"] = @(match.range.location);
            matchDict[@"end"] = @(match.range.location + match.range.length);
            matchDict[@"matchedText"] = [text substringWithRange:match.range];

            // Find line number
            NSInteger lineNumber = 1;
            NSInteger charCount = 0;
            for (NSInteger i = 0; i < lines.count; i++) {
                charCount += [lines[i] length] + 1;
                if (charCount > (NSInteger)match.range.location) {
                    lineNumber = i + 1;
                    break;
                }
            }
            matchDict[@"lineNumber"] = @(lineNumber);

            // Context
            NSInteger contextStart = MAX(0, (NSInteger)match.range.location - 30);
            NSInteger contextEnd = MIN((NSInteger)text.length, (NSInteger)(match.range.location + match.range.length + 30));
            matchDict[@"context"] = [text substringWithRange:NSMakeRange(contextStart, contextEnd - contextStart)];

            [matches addObject:matchDict];
        }

        result[@"matches"] = matches;
        result[@"matchCount"] = @(matches.count);
        result[@"searchTerm"] = searchTerm;
        result[@"caseSensitive"] = @(caseSensitive);
        result[@"isRegex"] = @(isRegex);
    } @catch (NSException *exception) {
        result[@"matches"] = @[];
        result[@"matchCount"] = @0;
        result[@"error"] = exception.reason;
    }

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)replace:(CDVInvokedUrlCommand *)command {
    NSString *text = [command.arguments objectAtIndex:0];
    NSString *searchTerm = [command.arguments objectAtIndex:1];
    NSString *replacement = [command.arguments objectAtIndex:2];
    BOOL replaceAll = [[command.arguments objectAtIndex:3] boolValue];
    BOOL caseSensitive = [[command.arguments objectAtIndex:4] boolValue];
    BOOL isRegex = [[command.arguments objectAtIndex:5] boolValue];

    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    @try {
        NSRegularExpressionOptions options = caseSensitive ? 0 : NSRegularExpressionCaseInsensitive;
        NSString *pattern = isRegex ? searchTerm : [NSRegularExpression escapedPatternForString:searchTerm];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:nil];

        NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
        NSInteger count = replaceAll ? matches.count : MIN(1, matches.count);

        NSString *resultText;
        if (replaceAll) {
            resultText = [regex stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:replacement];
        } else if (matches.count > 0) {
            NSTextCheckingResult *firstMatch = matches[0];
            resultText = [text stringByReplacingCharactersInRange:firstMatch.range withString:replacement];
        } else {
            resultText = text;
        }

        result[@"resultText"] = resultText;
        result[@"replacementCount"] = @(count);
        result[@"success"] = @YES;
    } @catch (NSException *exception) {
        result[@"resultText"] = text;
        result[@"replacementCount"] = @0;
        result[@"success"] = @NO;
        result[@"error"] = exception.reason;
    }

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark - Text Formatting

- (void)formatText:(CDVInvokedUrlCommand *)command {
    NSString *text = [command.arguments objectAtIndex:0];
    NSDictionary *options = [command.arguments objectAtIndex:1];

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSMutableArray *changesMade = [NSMutableArray array];
    NSString *formattedText = text;

    @try {
        if ([options[@"trim"] boolValue]) {
            formattedText = [formattedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [changesMade addObject:@"Trimmed whitespace"];
        }

        if ([options[@"removeExtraSpaces"] boolValue]) {
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@" +" options:0 error:nil];
            formattedText = [regex stringByReplacingMatchesInString:formattedText options:0 range:NSMakeRange(0, formattedText.length) withTemplate:@" "];
            [changesMade addObject:@"Removed extra spaces"];
        }

        if ([options[@"removeLineBreaks"] boolValue]) {
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[\\r\\n]+" options:0 error:nil];
            formattedText = [regex stringByReplacingMatchesInString:formattedText options:0 range:NSMakeRange(0, formattedText.length) withTemplate:@" "];
            [changesMade addObject:@"Removed line breaks"];
        }

        if ([options[@"toUpperCase"] boolValue]) {
            formattedText = [formattedText uppercaseString];
            [changesMade addObject:@"Converted to uppercase"];
        } else if ([options[@"toLowerCase"] boolValue]) {
            formattedText = [formattedText lowercaseString];
            [changesMade addObject:@"Converted to lowercase"];
        } else if ([options[@"toTitleCase"] boolValue]) {
            formattedText = [formattedText capitalizedString];
            [changesMade addObject:@"Converted to title case"];
        } else if ([options[@"toSentenceCase"] boolValue]) {
            formattedText = [self toSentenceCase:formattedText];
            [changesMade addObject:@"Converted to sentence case"];
        }

        if ([options[@"sortLines"] boolValue]) {
            NSArray *lines = [formattedText componentsSeparatedByString:@"\n"];
            lines = [lines sortedArrayUsingSelector:@selector(compare:)];
            formattedText = [lines componentsJoinedByString:@"\n"];
            [changesMade addObject:@"Sorted lines"];
        }

        if ([options[@"removeDuplicateLines"] boolValue]) {
            NSArray *lines = [formattedText componentsSeparatedByString:@"\n"];
            NSMutableArray *uniqueLines = [NSMutableArray array];
            NSMutableSet *seen = [NSMutableSet set];
            for (NSString *line in lines) {
                if (![seen containsObject:line]) {
                    [seen addObject:line];
                    [uniqueLines addObject:line];
                }
            }
            formattedText = [uniqueLines componentsJoinedByString:@"\n"];
            [changesMade addObject:@"Removed duplicate lines"];
        }

        if ([options[@"reverse"] boolValue]) {
            NSMutableString *reversed = [NSMutableString string];
            NSInteger length = formattedText.length;
            for (NSInteger i = length - 1; i >= 0; i--) {
                [reversed appendFormat:@"%C", [formattedText characterAtIndex:i]];
            }
            formattedText = reversed;
            [changesMade addObject:@"Reversed text"];
        }

        result[@"formattedText"] = formattedText;
        result[@"success"] = @YES;
        result[@"changesMade"] = changesMade;
    } @catch (NSException *exception) {
        result[@"formattedText"] = text;
        result[@"success"] = @NO;
        result[@"error"] = exception.reason;
    }

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSString *)toSentenceCase:(NSString *)text {
    NSMutableString *result = [NSMutableString string];
    BOOL capitalizeNext = YES;

    for (NSUInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];
        if (c == '.' || c == '!' || c == '?') {
            capitalizeNext = YES;
            [result appendFormat:@"%C", c];
        } else if (capitalizeNext && [[NSCharacterSet letterCharacterSet] characterIsMember:c]) {
            [result appendFormat:@"%C", [[NSString stringWithFormat:@"%C", c] uppercaseString].UTF8String[0]];
            capitalizeNext = NO;
        } else {
            [result appendFormat:@"%C", [[NSString stringWithFormat:@"%C", c] lowercaseString].UTF8String[0]];
        }
    }
    return result;
}

#pragma mark - Undo/Redo

- (void)initUndoRedo:(CDVInvokedUrlCommand *)command {
    NSString *initialText = [command.arguments objectAtIndex:0];
    NSInteger maxHistory = [[command.arguments objectAtIndex:1] integerValue];

    [undoHistory removeAllObjects];
    [undoHistory addObject:initialText];
    currentHistoryPosition = 0;
    maxHistorySize = maxHistory;

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self getUndoRedoStateDict]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)pushState:(CDVInvokedUrlCommand *)command {
    NSString *text = [command.arguments objectAtIndex:0];

    // Remove states after current position
    while (undoHistory.count > currentHistoryPosition + 1) {
        [undoHistory removeLastObject];
    }

    // Add new state
    [undoHistory addObject:text];
    currentHistoryPosition = undoHistory.count - 1;

    // Limit history size
    while (undoHistory.count > maxHistorySize) {
        [undoHistory removeObjectAtIndex:0];
        currentHistoryPosition--;
    }

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self getUndoRedoStateDict]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)undo:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    if (currentHistoryPosition > 0) {
        currentHistoryPosition--;
        result[@"text"] = undoHistory[currentHistoryPosition];
        result[@"success"] = @YES;
    } else {
        result[@"text"] = undoHistory.count > 0 ? undoHistory[0] : @"";
        result[@"success"] = @NO;
    }
    result[@"state"] = [self getUndoRedoStateDict];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)redo:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    if (currentHistoryPosition < (NSInteger)undoHistory.count - 1) {
        currentHistoryPosition++;
        result[@"text"] = undoHistory[currentHistoryPosition];
        result[@"success"] = @YES;
    } else {
        result[@"text"] = undoHistory.count > 0 ? undoHistory[undoHistory.count - 1] : @"";
        result[@"success"] = @NO;
    }
    result[@"state"] = [self getUndoRedoStateDict];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getUndoRedoState:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self getUndoRedoStateDict]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)clearHistory:(CDVInvokedUrlCommand *)command {
    [undoHistory removeAllObjects];
    currentHistoryPosition = -1;

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSDictionary *)getUndoRedoStateDict {
    return @{
        @"canUndo": @(currentHistoryPosition > 0),
        @"canRedo": @(currentHistoryPosition < (NSInteger)undoHistory.count - 1),
        @"currentPosition": @(currentHistoryPosition),
        @"historyLength": @(undoHistory.count)
    };
}

#pragma mark - Share Extension

- (void)getSharedContent:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    result[@"hasContent"] = @NO;
    result[@"text"] = @"";
    result[@"url"] = @"";
    result[@"files"] = @[];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)clearSharedContent:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end

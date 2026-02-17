#import <Cordova/CDV.h>

@interface NotepadUtilsPlugin : CDVPlugin

// Clipboard operations
- (void)getClipboard:(CDVInvokedUrlCommand*)command;
- (void)setClipboard:(CDVInvokedUrlCommand*)command;
- (void)clearClipboard:(CDVInvokedUrlCommand*)command;

// Text statistics
- (void)getTextStats:(CDVInvokedUrlCommand*)command;

// Text detection
- (void)detectPatterns:(CDVInvokedUrlCommand*)command;

// Encryption
- (void)encrypt:(CDVInvokedUrlCommand*)command;
- (void)decrypt:(CDVInvokedUrlCommand*)command;
- (void)hash:(CDVInvokedUrlCommand*)command;

// Search & Replace
- (void)search:(CDVInvokedUrlCommand*)command;
- (void)replace:(CDVInvokedUrlCommand*)command;

// Text formatting
- (void)formatText:(CDVInvokedUrlCommand*)command;

// Undo/Redo
- (void)initUndoRedo:(CDVInvokedUrlCommand*)command;
- (void)pushState:(CDVInvokedUrlCommand*)command;
- (void)undo:(CDVInvokedUrlCommand*)command;
- (void)redo:(CDVInvokedUrlCommand*)command;
- (void)getUndoRedoState:(CDVInvokedUrlCommand*)command;
- (void)clearHistory:(CDVInvokedUrlCommand*)command;

// Share extension
- (void)getSharedContent:(CDVInvokedUrlCommand*)command;
- (void)clearSharedContent:(CDVInvokedUrlCommand*)command;

@end

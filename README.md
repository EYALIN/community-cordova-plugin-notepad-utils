[![NPM version](https://img.shields.io/npm/v/community-cordova-plugin-notepad-utils)](https://www.npmjs.com/package/community-cordova-plugin-notepad-utils)

# community-cordova-plugin-notepad-utils

I dedicate a considerable amount of my free time to developing and maintaining many cordova plugins for the community ([See the list with all my maintained plugins][community_plugins]).
To help ensure this plugin is kept updated,
new features are added and bugfixes are implemented quickly,
please donate a couple of dollars (or a little more if you can stretch) as this will help me to afford to dedicate time to its maintenance.
Please consider donating if you're using this plugin in an app that makes you money,
or if you're asking for new features or priority bug fixes. Thank you!

[![](https://img.shields.io/static/v1?label=Sponsor%20Me&style=for-the-badge&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/eyalin)

---

# Community Cordova Plugin Notepad Utils

## Overview
A comprehensive Cordova plugin providing utilities for notepad/document applications. This plugin offers clipboard management, text statistics, pattern detection, encryption, search & replace, text formatting, and undo/redo functionality for both Android and iOS platforms.

## Installation
```bash
cordova plugin add community-cordova-plugin-notepad-utils
```

## Features

- **Clipboard Operations** - Read, write, and clear clipboard content
- **Text Statistics** - Word count, character count, reading time, and more
- **Pattern Detection** - Detect URLs, emails, phone numbers, hashtags, mentions, and dates
- **Encryption/Decryption** - AES-256 encryption with password-based key derivation
- **Hashing** - SHA-256, SHA-512, and MD5 hashing
- **Search & Replace** - Full regex support with match highlighting
- **Text Formatting** - Case conversion, whitespace handling, line operations
- **Undo/Redo** - Native undo/redo stack management

## Usage

### Clipboard Operations

```javascript
// Get clipboard content
NotepadUtilsPlugin.getClipboard().then(function(result) {
    console.log('Clipboard text:', result.text);
    console.log('Has content:', result.hasContent);
});

// Set clipboard content
NotepadUtilsPlugin.setClipboard({ text: 'Hello World' }).then(function(success) {
    console.log('Copied to clipboard');
});

// Clear clipboard
NotepadUtilsPlugin.clearClipboard().then(function(success) {
    console.log('Clipboard cleared');
});
```

### Text Statistics

```javascript
NotepadUtilsPlugin.getTextStats('Hello world! This is a test.').then(function(stats) {
    console.log('Word count:', stats.wordCount);
    console.log('Character count:', stats.characterCount);
    console.log('Reading time:', stats.readingTimeMinutes, 'minutes');
    console.log('Sentence count:', stats.sentenceCount);
});
```

### Pattern Detection

```javascript
NotepadUtilsPlugin.detectPatterns('Contact us at hello@example.com or visit https://example.com').then(function(patterns) {
    console.log('URLs:', patterns.urls);
    console.log('Emails:', patterns.emails);
    console.log('Phone numbers:', patterns.phoneNumbers);
});
```

### Encryption

```javascript
// Encrypt text
NotepadUtilsPlugin.encrypt('Secret message', 'myPassword').then(function(result) {
    if (result.success) {
        console.log('Encrypted:', result.encryptedData);
        // Store iv and salt for decryption
        const iv = result.iv;
        const salt = result.salt;
    }
});

// Decrypt text
NotepadUtilsPlugin.decrypt(encryptedData, 'myPassword', iv, salt).then(function(result) {
    if (result.success) {
        console.log('Decrypted:', result.decryptedText);
    }
});

// Hash text
NotepadUtilsPlugin.hash('text to hash', 'SHA-256').then(function(result) {
    console.log('Hash:', result.hash);
});
```

### Search & Replace

```javascript
// Search
NotepadUtilsPlugin.search('Hello world, hello universe', 'hello', false, false).then(function(result) {
    console.log('Found', result.matchCount, 'matches');
    result.matches.forEach(function(match) {
        console.log('Match at line', match.lineNumber, ':', match.matchedText);
    });
});

// Replace
NotepadUtilsPlugin.replace('Hello world', 'world', 'universe', true, false, false).then(function(result) {
    console.log('Result:', result.resultText); // "Hello universe"
    console.log('Replacements:', result.replacementCount);
});
```

### Text Formatting

```javascript
NotepadUtilsPlugin.formatText('  hello   world  ', {
    trim: true,
    removeExtraSpaces: true,
    toTitleCase: true
}).then(function(result) {
    console.log('Formatted:', result.formattedText); // "Hello World"
    console.log('Changes:', result.changesMade);
});
```

### Undo/Redo

```javascript
// Initialize undo/redo
NotepadUtilsPlugin.initUndoRedo('Initial text', 100).then(function(state) {
    console.log('Can undo:', state.canUndo);
});

// Push new state
NotepadUtilsPlugin.pushState('Updated text').then(function(state) {
    console.log('History length:', state.historyLength);
});

// Undo
NotepadUtilsPlugin.undo().then(function(result) {
    if (result.success) {
        console.log('Restored text:', result.text);
    }
});

// Redo
NotepadUtilsPlugin.redo().then(function(result) {
    if (result.success) {
        console.log('Redone text:', result.text);
    }
});
```

## API Reference

### Clipboard

| Method | Description |
|--------|-------------|
| `getClipboard()` | Get current clipboard content |
| `setClipboard(options)` | Set clipboard content |
| `clearClipboard()` | Clear clipboard |

### Text Analysis

| Method | Description |
|--------|-------------|
| `getTextStats(text)` | Get comprehensive text statistics |
| `detectPatterns(text)` | Detect URLs, emails, phone numbers, etc. |

### Encryption

| Method | Description |
|--------|-------------|
| `encrypt(text, password)` | Encrypt text with AES-256 |
| `decrypt(data, password, iv, salt)` | Decrypt encrypted data |
| `hash(text, algorithm)` | Hash text (SHA-256, SHA-512, MD5) |

### Search & Replace

| Method | Description |
|--------|-------------|
| `search(text, term, caseSensitive, isRegex)` | Search for text |
| `replace(text, term, replacement, replaceAll, caseSensitive, isRegex)` | Replace text |

### Formatting

| Method | Description |
|--------|-------------|
| `formatText(text, options)` | Apply formatting options |

### Undo/Redo

| Method | Description |
|--------|-------------|
| `initUndoRedo(text, maxHistory)` | Initialize undo/redo stack |
| `pushState(text)` | Push new state to history |
| `undo()` | Undo last change |
| `redo()` | Redo last undone change |
| `getUndoRedoState()` | Get current undo/redo state |
| `clearHistory()` | Clear undo/redo history |

## TypeScript Support

This plugin includes TypeScript definitions. Import the types:

```typescript
import NotepadUtilsManager, {
    IClipboardContent,
    ITextStats,
    ITextDetection,
    IEncryptionResult,
    ISearchResult,
    IFormattingResult,
    IUndoRedoState
} from 'community-cordova-plugin-notepad-utils';
```

## Platform Support

| Platform | Supported |
|----------|-----------|
| Android | Yes |
| iOS | Yes |

## License
MIT

---
[community_plugins]: https://github.com/EYALIN?tab=repositories&q=community&type=&language=&sort=

// ==================== Clipboard Interfaces ====================

export interface IClipboardContent {
    // The text content from clipboard
    text: string;
    // Whether clipboard has content
    hasContent: boolean;
    // Content type (text, html, image, etc.)
    contentType: 'text' | 'html' | 'image' | 'unknown';
    // Timestamp when content was copied (if available)
    timestamp?: number;
}

export interface IClipboardWriteOptions {
    // Text to copy
    text?: string;
    // HTML content to copy
    html?: string;
    // Label for the clipboard entry (Android)
    label?: string;
}

// ==================== Text Statistics Interfaces ====================

export interface ITextStats {
    // Total character count (including spaces)
    characterCount: number;
    // Character count without spaces
    characterCountNoSpaces: number;
    // Word count
    wordCount: number;
    // Sentence count
    sentenceCount: number;
    // Paragraph count
    paragraphCount: number;
    // Line count
    lineCount: number;
    // Estimated reading time in minutes
    readingTimeMinutes: number;
    // Estimated speaking time in minutes
    speakingTimeMinutes: number;
    // Average word length
    averageWordLength: number;
    // Unique word count
    uniqueWordCount: number;
}

// ==================== Text Detection Interfaces ====================

export interface ITextDetection {
    // Detected URLs in the text
    urls: string[];
    // Detected email addresses
    emails: string[];
    // Detected phone numbers
    phoneNumbers: string[];
    // Detected hashtags
    hashtags: string[];
    // Detected mentions (@username)
    mentions: string[];
    // Detected dates (various formats)
    dates: string[];
}

// ==================== Encryption Interfaces ====================

export interface IEncryptionResult {
    // Encrypted data (base64 encoded)
    encryptedData: string;
    // Initialization vector (base64 encoded)
    iv: string;
    // Salt used (base64 encoded)
    salt: string;
    // Whether encryption was successful
    success: boolean;
    // Error message if failed
    error?: string;
}

export interface IDecryptionResult {
    // Decrypted text
    decryptedText: string;
    // Whether decryption was successful
    success: boolean;
    // Error message if failed
    error?: string;
}

export interface IHashResult {
    // The hash value
    hash: string;
    // Algorithm used (SHA-256, SHA-512, MD5)
    algorithm: string;
    // Whether hashing was successful
    success: boolean;
}

// ==================== Search & Replace Interfaces ====================

export interface ISearchResult {
    // Array of match positions
    matches: IMatchPosition[];
    // Total number of matches
    matchCount: number;
    // Search term used
    searchTerm: string;
    // Whether search was case sensitive
    caseSensitive: boolean;
    // Whether regex was used
    isRegex: boolean;
}

export interface IMatchPosition {
    // Start index of match
    start: number;
    // End index of match
    end: number;
    // Line number where match was found
    lineNumber: number;
    // The matched text
    matchedText: string;
    // Context around the match
    context: string;
}

export interface IReplaceResult {
    // The resulting text after replacement
    resultText: string;
    // Number of replacements made
    replacementCount: number;
    // Whether replacement was successful
    success: boolean;
}

// ==================== Text Formatting Interfaces ====================

export interface IFormattingOptions {
    // Convert to uppercase
    toUpperCase?: boolean;
    // Convert to lowercase
    toLowerCase?: boolean;
    // Convert to title case
    toTitleCase?: boolean;
    // Convert to sentence case
    toSentenceCase?: boolean;
    // Trim whitespace
    trim?: boolean;
    // Remove extra spaces
    removeExtraSpaces?: boolean;
    // Remove line breaks
    removeLineBreaks?: boolean;
    // Sort lines
    sortLines?: boolean;
    // Remove duplicate lines
    removeDuplicateLines?: boolean;
    // Reverse text
    reverse?: boolean;
}

export interface IFormattingResult {
    // Formatted text
    formattedText: string;
    // Whether formatting was successful
    success: boolean;
    // Changes made
    changesMade: string[];
}

// ==================== Undo/Redo Interfaces ====================

export interface IUndoRedoState {
    // Whether undo is available
    canUndo: boolean;
    // Whether redo is available
    canRedo: boolean;
    // Current position in history
    currentPosition: number;
    // Total history length
    historyLength: number;
}

export interface IUndoRedoResult {
    // The text after undo/redo
    text: string;
    // Whether operation was successful
    success: boolean;
    // New state after operation
    state: IUndoRedoState;
}

// ==================== Auto-Save Interfaces ====================

export interface IAutoSaveConfig {
    // Enable/disable auto-save
    enabled: boolean;
    // Interval in milliseconds
    intervalMs: number;
    // Maximum number of backups to keep
    maxBackups: number;
    // Save location identifier
    saveLocation: string;
}

export interface IAutoSaveResult {
    // Whether save was successful
    success: boolean;
    // Timestamp of save
    timestamp: number;
    // File path or identifier
    savedTo: string;
    // Size of saved content in bytes
    sizeBytes: number;
}

export interface IBackupInfo {
    // Backup identifier
    id: string;
    // Timestamp of backup
    timestamp: number;
    // Size in bytes
    sizeBytes: number;
    // Preview of content (first 100 chars)
    preview: string;
}

// ==================== Share Extension Interfaces ====================

export interface ISharedContent {
    // Shared text content
    text?: string;
    // Shared URL
    url?: string;
    // Shared file paths
    files?: string[];
    // Source app (if available)
    sourceApp?: string;
    // Whether there is shared content
    hasContent: boolean;
}

// ==================== Main Plugin Manager ====================

export default class NotepadUtilsManager {
    // Clipboard operations
    getClipboard(): Promise<IClipboardContent>;
    setClipboard(options: IClipboardWriteOptions): Promise<boolean>;
    clearClipboard(): Promise<boolean>;

    // Text statistics
    getTextStats(text: string): Promise<ITextStats>;

    // Text detection
    detectPatterns(text: string): Promise<ITextDetection>;

    // Encryption/Decryption
    encrypt(text: string, password: string): Promise<IEncryptionResult>;
    decrypt(encryptedData: string, password: string, iv: string, salt: string): Promise<IDecryptionResult>;
    hash(text: string, algorithm?: 'SHA-256' | 'SHA-512' | 'MD5'): Promise<IHashResult>;

    // Search & Replace
    search(text: string, searchTerm: string, caseSensitive?: boolean, isRegex?: boolean): Promise<ISearchResult>;
    replace(text: string, searchTerm: string, replacement: string, replaceAll?: boolean, caseSensitive?: boolean, isRegex?: boolean): Promise<IReplaceResult>;

    // Text formatting
    formatText(text: string, options: IFormattingOptions): Promise<IFormattingResult>;

    // Undo/Redo management
    initUndoRedo(initialText: string, maxHistory?: number): Promise<IUndoRedoState>;
    pushState(text: string): Promise<IUndoRedoState>;
    undo(): Promise<IUndoRedoResult>;
    redo(): Promise<IUndoRedoResult>;
    getUndoRedoState(): Promise<IUndoRedoState>;
    clearHistory(): Promise<boolean>;

    // Auto-save
    configureAutoSave(config: IAutoSaveConfig): Promise<boolean>;
    saveNow(content: string, identifier: string): Promise<IAutoSaveResult>;
    getBackups(identifier: string): Promise<IBackupInfo[]>;
    restoreBackup(backupId: string): Promise<string>;
    deleteBackup(backupId: string): Promise<boolean>;

    // Share extension
    getSharedContent(): Promise<ISharedContent>;
    clearSharedContent(): Promise<boolean>;
}

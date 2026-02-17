var PLUGIN_NAME = 'NotepadUtilsPlugin';

var NotepadUtilsPlugin = {
    // ==================== Clipboard Operations ====================

    /**
     * Get clipboard content
     * @returns {Promise<Object>} Clipboard content information
     */
    getClipboard: function() {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'getClipboard', []);
        });
    },

    /**
     * Set clipboard content
     * @param {Object} options - { text?, html?, label? }
     * @returns {Promise<boolean>} Success status
     */
    setClipboard: function(options) {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'setClipboard', [options]);
        });
    },

    /**
     * Clear clipboard
     * @returns {Promise<boolean>} Success status
     */
    clearClipboard: function() {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'clearClipboard', []);
        });
    },

    // ==================== Text Statistics ====================

    /**
     * Get text statistics
     * @param {string} text - The text to analyze
     * @returns {Promise<Object>} Text statistics
     */
    getTextStats: function(text) {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'getTextStats', [text]);
        });
    },

    // ==================== Text Detection ====================

    /**
     * Detect patterns in text (URLs, emails, phone numbers, etc.)
     * @param {string} text - The text to analyze
     * @returns {Promise<Object>} Detected patterns
     */
    detectPatterns: function(text) {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'detectPatterns', [text]);
        });
    },

    // ==================== Encryption/Decryption ====================

    /**
     * Encrypt text with password
     * @param {string} text - Text to encrypt
     * @param {string} password - Password for encryption
     * @returns {Promise<Object>} Encryption result
     */
    encrypt: function(text, password) {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'encrypt', [text, password]);
        });
    },

    /**
     * Decrypt text with password
     * @param {string} encryptedData - Encrypted data (base64)
     * @param {string} password - Password for decryption
     * @param {string} iv - Initialization vector (base64)
     * @param {string} salt - Salt (base64)
     * @returns {Promise<Object>} Decryption result
     */
    decrypt: function(encryptedData, password, iv, salt) {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'decrypt', [encryptedData, password, iv, salt]);
        });
    },

    /**
     * Hash text
     * @param {string} text - Text to hash
     * @param {string} algorithm - Hash algorithm (SHA-256, SHA-512, MD5)
     * @returns {Promise<Object>} Hash result
     */
    hash: function(text, algorithm) {
        algorithm = algorithm || 'SHA-256';
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'hash', [text, algorithm]);
        });
    },

    // ==================== Search & Replace ====================

    /**
     * Search for text
     * @param {string} text - Text to search in
     * @param {string} searchTerm - Term to search for
     * @param {boolean} caseSensitive - Case sensitive search
     * @param {boolean} isRegex - Use regex
     * @returns {Promise<Object>} Search results
     */
    search: function(text, searchTerm, caseSensitive, isRegex) {
        caseSensitive = caseSensitive || false;
        isRegex = isRegex || false;
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'search', [text, searchTerm, caseSensitive, isRegex]);
        });
    },

    /**
     * Replace text
     * @param {string} text - Text to search in
     * @param {string} searchTerm - Term to search for
     * @param {string} replacement - Replacement text
     * @param {boolean} replaceAll - Replace all occurrences
     * @param {boolean} caseSensitive - Case sensitive search
     * @param {boolean} isRegex - Use regex
     * @returns {Promise<Object>} Replace result
     */
    replace: function(text, searchTerm, replacement, replaceAll, caseSensitive, isRegex) {
        replaceAll = replaceAll !== false;
        caseSensitive = caseSensitive || false;
        isRegex = isRegex || false;
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'replace', [text, searchTerm, replacement, replaceAll, caseSensitive, isRegex]);
        });
    },

    // ==================== Text Formatting ====================

    /**
     * Format text with various options
     * @param {string} text - Text to format
     * @param {Object} options - Formatting options
     * @returns {Promise<Object>} Formatted text result
     */
    formatText: function(text, options) {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'formatText', [text, options]);
        });
    },

    // ==================== Undo/Redo ====================

    /**
     * Initialize undo/redo with initial text
     * @param {string} initialText - Initial text state
     * @param {number} maxHistory - Maximum history length
     * @returns {Promise<Object>} Undo/redo state
     */
    initUndoRedo: function(initialText, maxHistory) {
        maxHistory = maxHistory || 100;
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'initUndoRedo', [initialText, maxHistory]);
        });
    },

    /**
     * Push new state to history
     * @param {string} text - New text state
     * @returns {Promise<Object>} Undo/redo state
     */
    pushState: function(text) {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'pushState', [text]);
        });
    },

    /**
     * Undo last change
     * @returns {Promise<Object>} Undo result with text and state
     */
    undo: function() {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'undo', []);
        });
    },

    /**
     * Redo last undone change
     * @returns {Promise<Object>} Redo result with text and state
     */
    redo: function() {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'redo', []);
        });
    },

    /**
     * Get current undo/redo state
     * @returns {Promise<Object>} Current state
     */
    getUndoRedoState: function() {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'getUndoRedoState', []);
        });
    },

    /**
     * Clear undo/redo history
     * @returns {Promise<boolean>} Success status
     */
    clearHistory: function() {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'clearHistory', []);
        });
    },

    // ==================== Auto-Save ====================

    /**
     * Configure auto-save settings
     * @param {Object} config - Auto-save configuration
     * @returns {Promise<boolean>} Success status
     */
    configureAutoSave: function(config) {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'configureAutoSave', [config]);
        });
    },

    /**
     * Save content immediately
     * @param {string} content - Content to save
     * @param {string} identifier - Unique identifier for the content
     * @returns {Promise<Object>} Save result
     */
    saveNow: function(content, identifier) {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'saveNow', [content, identifier]);
        });
    },

    /**
     * Get list of backups
     * @param {string} identifier - Identifier to get backups for
     * @returns {Promise<Array>} List of backups
     */
    getBackups: function(identifier) {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'getBackups', [identifier]);
        });
    },

    /**
     * Restore a backup
     * @param {string} backupId - Backup ID to restore
     * @returns {Promise<string>} Restored content
     */
    restoreBackup: function(backupId) {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'restoreBackup', [backupId]);
        });
    },

    /**
     * Delete a backup
     * @param {string} backupId - Backup ID to delete
     * @returns {Promise<boolean>} Success status
     */
    deleteBackup: function(backupId) {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'deleteBackup', [backupId]);
        });
    },

    // ==================== Share Extension ====================

    /**
     * Get content shared from other apps
     * @returns {Promise<Object>} Shared content
     */
    getSharedContent: function() {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'getSharedContent', []);
        });
    },

    /**
     * Clear shared content
     * @returns {Promise<boolean>} Success status
     */
    clearSharedContent: function() {
        return new Promise(function(resolve, reject) {
            cordova.exec(resolve, reject, PLUGIN_NAME, 'clearSharedContent', []);
        });
    }
};

module.exports = NotepadUtilsPlugin;

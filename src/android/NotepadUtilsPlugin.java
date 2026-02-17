package community.plugins.notepadutils;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.util.Base64;
import android.util.Log;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;

public class NotepadUtilsPlugin extends CordovaPlugin {
    private static final String TAG = "NotepadUtilsPlugin";

    // Undo/Redo history
    private List<String> undoHistory = new ArrayList<>();
    private int currentHistoryPosition = -1;
    private int maxHistorySize = 100;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
    }

    private Context getContext() {
        return cordova.getActivity();
    }

    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        try {
            switch (action) {
                // Clipboard operations
                case "getClipboard":
                    return getClipboard(callbackContext);
                case "setClipboard":
                    return setClipboard(args.getJSONObject(0), callbackContext);
                case "clearClipboard":
                    return clearClipboard(callbackContext);

                // Text statistics
                case "getTextStats":
                    return getTextStats(args.getString(0), callbackContext);

                // Text detection
                case "detectPatterns":
                    return detectPatterns(args.getString(0), callbackContext);

                // Encryption
                case "encrypt":
                    return encrypt(args.getString(0), args.getString(1), callbackContext);
                case "decrypt":
                    return decrypt(args.getString(0), args.getString(1), args.getString(2), args.getString(3), callbackContext);
                case "hash":
                    return hash(args.getString(0), args.getString(1), callbackContext);

                // Search & Replace
                case "search":
                    return search(args.getString(0), args.getString(1), args.getBoolean(2), args.getBoolean(3), callbackContext);
                case "replace":
                    return replace(args.getString(0), args.getString(1), args.getString(2), args.getBoolean(3), args.getBoolean(4), args.getBoolean(5), callbackContext);

                // Text formatting
                case "formatText":
                    return formatText(args.getString(0), args.getJSONObject(1), callbackContext);

                // Undo/Redo
                case "initUndoRedo":
                    return initUndoRedo(args.getString(0), args.getInt(1), callbackContext);
                case "pushState":
                    return pushState(args.getString(0), callbackContext);
                case "undo":
                    return undo(callbackContext);
                case "redo":
                    return redo(callbackContext);
                case "getUndoRedoState":
                    return getUndoRedoState(callbackContext);
                case "clearHistory":
                    return clearHistory(callbackContext);

                // Share extension
                case "getSharedContent":
                    return getSharedContent(callbackContext);
                case "clearSharedContent":
                    return clearSharedContent(callbackContext);

                default:
                    callbackContext.error("Unknown action: " + action);
                    return false;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error executing action: " + action, e);
            callbackContext.error(e.getMessage());
            return false;
        }
    }

    // ==================== Clipboard Operations ====================

    private boolean getClipboard(CallbackContext callbackContext) throws JSONException {
        ClipboardManager clipboard = (ClipboardManager) getContext().getSystemService(Context.CLIPBOARD_SERVICE);
        JSONObject result = new JSONObject();

        if (clipboard != null && clipboard.hasPrimaryClip()) {
            ClipData clip = clipboard.getPrimaryClip();
            if (clip != null && clip.getItemCount() > 0) {
                ClipData.Item item = clip.getItemAt(0);
                CharSequence text = item.getText();

                result.put("hasContent", text != null && text.length() > 0);
                result.put("text", text != null ? text.toString() : "");
                result.put("contentType", "text");
                result.put("timestamp", System.currentTimeMillis());
            } else {
                result.put("hasContent", false);
                result.put("text", "");
                result.put("contentType", "unknown");
            }
        } else {
            result.put("hasContent", false);
            result.put("text", "");
            result.put("contentType", "unknown");
        }

        callbackContext.success(result);
        return true;
    }

    private boolean setClipboard(JSONObject options, CallbackContext callbackContext) throws JSONException {
        ClipboardManager clipboard = (ClipboardManager) getContext().getSystemService(Context.CLIPBOARD_SERVICE);

        String text = options.optString("text", "");
        String label = options.optString("label", "Copied Text");

        ClipData clip = ClipData.newPlainText(label, text);
        if (clipboard != null) {
            clipboard.setPrimaryClip(clip);
            callbackContext.success();
        } else {
            callbackContext.error("Clipboard not available");
        }
        return true;
    }

    private boolean clearClipboard(CallbackContext callbackContext) {
        ClipboardManager clipboard = (ClipboardManager) getContext().getSystemService(Context.CLIPBOARD_SERVICE);
        if (clipboard != null) {
            ClipData clip = ClipData.newPlainText("", "");
            clipboard.setPrimaryClip(clip);
            callbackContext.success();
        } else {
            callbackContext.error("Clipboard not available");
        }
        return true;
    }

    // ==================== Text Statistics ====================

    private boolean getTextStats(String text, CallbackContext callbackContext) throws JSONException {
        JSONObject result = new JSONObject();

        // Character counts
        result.put("characterCount", text.length());
        result.put("characterCountNoSpaces", text.replaceAll("\\s", "").length());

        // Word count
        String[] words = text.trim().split("\\s+");
        int wordCount = text.trim().isEmpty() ? 0 : words.length;
        result.put("wordCount", wordCount);

        // Unique words
        Set<String> uniqueWords = new HashSet<>();
        for (String word : words) {
            if (!word.isEmpty()) {
                uniqueWords.add(word.toLowerCase());
            }
        }
        result.put("uniqueWordCount", uniqueWords.size());

        // Sentence count
        String[] sentences = text.split("[.!?]+");
        int sentenceCount = 0;
        for (String s : sentences) {
            if (!s.trim().isEmpty()) sentenceCount++;
        }
        result.put("sentenceCount", sentenceCount);

        // Paragraph count
        String[] paragraphs = text.split("\\n\\s*\\n");
        int paragraphCount = 0;
        for (String p : paragraphs) {
            if (!p.trim().isEmpty()) paragraphCount++;
        }
        result.put("paragraphCount", Math.max(paragraphCount, text.trim().isEmpty() ? 0 : 1));

        // Line count
        String[] lines = text.split("\\n");
        result.put("lineCount", lines.length);

        // Average word length
        double avgWordLength = 0;
        if (wordCount > 0) {
            int totalChars = 0;
            for (String word : words) {
                totalChars += word.replaceAll("[^a-zA-Z0-9]", "").length();
            }
            avgWordLength = (double) totalChars / wordCount;
        }
        result.put("averageWordLength", Math.round(avgWordLength * 100.0) / 100.0);

        // Reading time (avg 200 words per minute)
        double readingTime = wordCount / 200.0;
        result.put("readingTimeMinutes", Math.round(readingTime * 100.0) / 100.0);

        // Speaking time (avg 150 words per minute)
        double speakingTime = wordCount / 150.0;
        result.put("speakingTimeMinutes", Math.round(speakingTime * 100.0) / 100.0);

        callbackContext.success(result);
        return true;
    }

    // ==================== Text Detection ====================

    private boolean detectPatterns(String text, CallbackContext callbackContext) throws JSONException {
        JSONObject result = new JSONObject();

        // URLs
        Pattern urlPattern = Pattern.compile("https?://[\\w\\-._~:/?#\\[\\]@!$&'()*+,;=%]+", Pattern.CASE_INSENSITIVE);
        result.put("urls", findAllMatches(urlPattern, text));

        // Emails
        Pattern emailPattern = Pattern.compile("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}");
        result.put("emails", findAllMatches(emailPattern, text));

        // Phone numbers
        Pattern phonePattern = Pattern.compile("(\\+?\\d{1,3}[-.\\s]?)?(\\(?\\d{2,4}\\)?[-.\\s]?)?\\d{3,4}[-.\\s]?\\d{3,4}");
        result.put("phoneNumbers", findAllMatches(phonePattern, text));

        // Hashtags
        Pattern hashtagPattern = Pattern.compile("#[a-zA-Z0-9_]+");
        result.put("hashtags", findAllMatches(hashtagPattern, text));

        // Mentions
        Pattern mentionPattern = Pattern.compile("@[a-zA-Z0-9_]+");
        result.put("mentions", findAllMatches(mentionPattern, text));

        // Dates (various formats)
        Pattern datePattern = Pattern.compile("\\d{1,2}[/\\-.]\\d{1,2}[/\\-.]\\d{2,4}|\\d{4}[/\\-.]\\d{1,2}[/\\-.]\\d{1,2}");
        result.put("dates", findAllMatches(datePattern, text));

        callbackContext.success(result);
        return true;
    }

    private JSONArray findAllMatches(Pattern pattern, String text) {
        JSONArray matches = new JSONArray();
        Matcher matcher = pattern.matcher(text);
        while (matcher.find()) {
            matches.put(matcher.group());
        }
        return matches;
    }

    // ==================== Encryption ====================

    private boolean encrypt(String text, String password, CallbackContext callbackContext) throws JSONException {
        JSONObject result = new JSONObject();
        try {
            // Generate salt and IV
            SecureRandom random = new SecureRandom();
            byte[] salt = new byte[16];
            byte[] iv = new byte[16];
            random.nextBytes(salt);
            random.nextBytes(iv);

            // Derive key from password
            SecretKeyFactory factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
            PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, 65536, 256);
            SecretKey tmp = factory.generateSecret(spec);
            SecretKeySpec secretKey = new SecretKeySpec(tmp.getEncoded(), "AES");

            // Encrypt
            Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, new IvParameterSpec(iv));
            byte[] encrypted = cipher.doFinal(text.getBytes(StandardCharsets.UTF_8));

            result.put("encryptedData", Base64.encodeToString(encrypted, Base64.NO_WRAP));
            result.put("iv", Base64.encodeToString(iv, Base64.NO_WRAP));
            result.put("salt", Base64.encodeToString(salt, Base64.NO_WRAP));
            result.put("success", true);
        } catch (Exception e) {
            result.put("success", false);
            result.put("error", e.getMessage());
        }
        callbackContext.success(result);
        return true;
    }

    private boolean decrypt(String encryptedData, String password, String ivStr, String saltStr, CallbackContext callbackContext) throws JSONException {
        JSONObject result = new JSONObject();
        try {
            byte[] encrypted = Base64.decode(encryptedData, Base64.NO_WRAP);
            byte[] iv = Base64.decode(ivStr, Base64.NO_WRAP);
            byte[] salt = Base64.decode(saltStr, Base64.NO_WRAP);

            // Derive key from password
            SecretKeyFactory factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
            PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, 65536, 256);
            SecretKey tmp = factory.generateSecret(spec);
            SecretKeySpec secretKey = new SecretKeySpec(tmp.getEncoded(), "AES");

            // Decrypt
            Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            cipher.init(Cipher.DECRYPT_MODE, secretKey, new IvParameterSpec(iv));
            byte[] decrypted = cipher.doFinal(encrypted);

            result.put("decryptedText", new String(decrypted, StandardCharsets.UTF_8));
            result.put("success", true);
        } catch (Exception e) {
            result.put("success", false);
            result.put("error", e.getMessage());
        }
        callbackContext.success(result);
        return true;
    }

    private boolean hash(String text, String algorithm, CallbackContext callbackContext) throws JSONException {
        JSONObject result = new JSONObject();
        try {
            String alg = algorithm;
            if ("MD5".equals(algorithm)) {
                alg = "MD5";
            } else if ("SHA-512".equals(algorithm)) {
                alg = "SHA-512";
            } else {
                alg = "SHA-256";
            }

            MessageDigest digest = MessageDigest.getInstance(alg);
            byte[] hashBytes = digest.digest(text.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hashBytes) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }

            result.put("hash", hexString.toString());
            result.put("algorithm", alg);
            result.put("success", true);
        } catch (Exception e) {
            result.put("success", false);
            result.put("error", e.getMessage());
        }
        callbackContext.success(result);
        return true;
    }

    // ==================== Search & Replace ====================

    private boolean search(String text, String searchTerm, boolean caseSensitive, boolean isRegex, CallbackContext callbackContext) throws JSONException {
        JSONObject result = new JSONObject();
        JSONArray matches = new JSONArray();

        try {
            Pattern pattern;
            if (isRegex) {
                int flags = caseSensitive ? 0 : Pattern.CASE_INSENSITIVE;
                pattern = Pattern.compile(searchTerm, flags);
            } else {
                int flags = caseSensitive ? 0 : Pattern.CASE_INSENSITIVE;
                pattern = Pattern.compile(Pattern.quote(searchTerm), flags);
            }

            Matcher matcher = pattern.matcher(text);
            String[] lines = text.split("\n");

            while (matcher.find()) {
                JSONObject match = new JSONObject();
                match.put("start", matcher.start());
                match.put("end", matcher.end());
                match.put("matchedText", matcher.group());

                // Find line number
                int lineNumber = 1;
                int charCount = 0;
                for (int i = 0; i < lines.length; i++) {
                    charCount += lines[i].length() + 1;
                    if (charCount > matcher.start()) {
                        lineNumber = i + 1;
                        break;
                    }
                }
                match.put("lineNumber", lineNumber);

                // Context (30 chars before and after)
                int contextStart = Math.max(0, matcher.start() - 30);
                int contextEnd = Math.min(text.length(), matcher.end() + 30);
                match.put("context", text.substring(contextStart, contextEnd));

                matches.put(match);
            }

            result.put("matches", matches);
            result.put("matchCount", matches.length());
            result.put("searchTerm", searchTerm);
            result.put("caseSensitive", caseSensitive);
            result.put("isRegex", isRegex);
        } catch (Exception e) {
            result.put("matches", new JSONArray());
            result.put("matchCount", 0);
            result.put("error", e.getMessage());
        }

        callbackContext.success(result);
        return true;
    }

    private boolean replace(String text, String searchTerm, String replacement, boolean replaceAll, boolean caseSensitive, boolean isRegex, CallbackContext callbackContext) throws JSONException {
        JSONObject result = new JSONObject();

        try {
            Pattern pattern;
            if (isRegex) {
                int flags = caseSensitive ? 0 : Pattern.CASE_INSENSITIVE;
                pattern = Pattern.compile(searchTerm, flags);
            } else {
                int flags = caseSensitive ? 0 : Pattern.CASE_INSENSITIVE;
                pattern = Pattern.compile(Pattern.quote(searchTerm), flags);
            }

            Matcher matcher = pattern.matcher(text);
            String resultText;
            int count = 0;

            if (replaceAll) {
                while (matcher.find()) count++;
                matcher.reset();
                resultText = matcher.replaceAll(replacement);
            } else {
                if (matcher.find()) count = 1;
                matcher.reset();
                resultText = matcher.replaceFirst(replacement);
            }

            result.put("resultText", resultText);
            result.put("replacementCount", count);
            result.put("success", true);
        } catch (Exception e) {
            result.put("resultText", text);
            result.put("replacementCount", 0);
            result.put("success", false);
            result.put("error", e.getMessage());
        }

        callbackContext.success(result);
        return true;
    }

    // ==================== Text Formatting ====================

    private boolean formatText(String text, JSONObject options, CallbackContext callbackContext) throws JSONException {
        JSONObject result = new JSONObject();
        JSONArray changesMade = new JSONArray();
        String formattedText = text;

        try {
            if (options.optBoolean("trim", false)) {
                formattedText = formattedText.trim();
                changesMade.put("Trimmed whitespace");
            }

            if (options.optBoolean("removeExtraSpaces", false)) {
                formattedText = formattedText.replaceAll(" +", " ");
                changesMade.put("Removed extra spaces");
            }

            if (options.optBoolean("removeLineBreaks", false)) {
                formattedText = formattedText.replaceAll("[\\r\\n]+", " ");
                changesMade.put("Removed line breaks");
            }

            if (options.optBoolean("toUpperCase", false)) {
                formattedText = formattedText.toUpperCase();
                changesMade.put("Converted to uppercase");
            } else if (options.optBoolean("toLowerCase", false)) {
                formattedText = formattedText.toLowerCase();
                changesMade.put("Converted to lowercase");
            } else if (options.optBoolean("toTitleCase", false)) {
                formattedText = toTitleCase(formattedText);
                changesMade.put("Converted to title case");
            } else if (options.optBoolean("toSentenceCase", false)) {
                formattedText = toSentenceCase(formattedText);
                changesMade.put("Converted to sentence case");
            }

            if (options.optBoolean("sortLines", false)) {
                String[] lines = formattedText.split("\n");
                Arrays.sort(lines);
                formattedText = String.join("\n", lines);
                changesMade.put("Sorted lines");
            }

            if (options.optBoolean("removeDuplicateLines", false)) {
                String[] lines = formattedText.split("\n");
                Set<String> seen = new HashSet<>();
                StringBuilder sb = new StringBuilder();
                for (String line : lines) {
                    if (seen.add(line)) {
                        if (sb.length() > 0) sb.append("\n");
                        sb.append(line);
                    }
                }
                formattedText = sb.toString();
                changesMade.put("Removed duplicate lines");
            }

            if (options.optBoolean("reverse", false)) {
                formattedText = new StringBuilder(formattedText).reverse().toString();
                changesMade.put("Reversed text");
            }

            result.put("formattedText", formattedText);
            result.put("success", true);
            result.put("changesMade", changesMade);
        } catch (Exception e) {
            result.put("formattedText", text);
            result.put("success", false);
            result.put("error", e.getMessage());
        }

        callbackContext.success(result);
        return true;
    }

    private String toTitleCase(String text) {
        StringBuilder result = new StringBuilder();
        boolean capitalizeNext = true;
        for (char c : text.toCharArray()) {
            if (Character.isWhitespace(c)) {
                capitalizeNext = true;
                result.append(c);
            } else if (capitalizeNext) {
                result.append(Character.toUpperCase(c));
                capitalizeNext = false;
            } else {
                result.append(Character.toLowerCase(c));
            }
        }
        return result.toString();
    }

    private String toSentenceCase(String text) {
        StringBuilder result = new StringBuilder();
        boolean capitalizeNext = true;
        for (char c : text.toCharArray()) {
            if (c == '.' || c == '!' || c == '?') {
                capitalizeNext = true;
                result.append(c);
            } else if (capitalizeNext && Character.isLetter(c)) {
                result.append(Character.toUpperCase(c));
                capitalizeNext = false;
            } else {
                result.append(Character.toLowerCase(c));
            }
        }
        return result.toString();
    }

    // ==================== Undo/Redo ====================

    private boolean initUndoRedo(String initialText, int maxHistory, CallbackContext callbackContext) throws JSONException {
        undoHistory.clear();
        undoHistory.add(initialText);
        currentHistoryPosition = 0;
        maxHistorySize = maxHistory;
        callbackContext.success(getUndoRedoStateObject());
        return true;
    }

    private boolean pushState(String text, CallbackContext callbackContext) throws JSONException {
        // Remove any states after current position (for redo)
        while (undoHistory.size() > currentHistoryPosition + 1) {
            undoHistory.remove(undoHistory.size() - 1);
        }

        // Add new state
        undoHistory.add(text);
        currentHistoryPosition = undoHistory.size() - 1;

        // Limit history size
        while (undoHistory.size() > maxHistorySize) {
            undoHistory.remove(0);
            currentHistoryPosition--;
        }

        callbackContext.success(getUndoRedoStateObject());
        return true;
    }

    private boolean undo(CallbackContext callbackContext) throws JSONException {
        JSONObject result = new JSONObject();
        if (currentHistoryPosition > 0) {
            currentHistoryPosition--;
            result.put("text", undoHistory.get(currentHistoryPosition));
            result.put("success", true);
        } else {
            result.put("text", undoHistory.isEmpty() ? "" : undoHistory.get(0));
            result.put("success", false);
        }
        result.put("state", getUndoRedoStateObject());
        callbackContext.success(result);
        return true;
    }

    private boolean redo(CallbackContext callbackContext) throws JSONException {
        JSONObject result = new JSONObject();
        if (currentHistoryPosition < undoHistory.size() - 1) {
            currentHistoryPosition++;
            result.put("text", undoHistory.get(currentHistoryPosition));
            result.put("success", true);
        } else {
            result.put("text", undoHistory.isEmpty() ? "" : undoHistory.get(undoHistory.size() - 1));
            result.put("success", false);
        }
        result.put("state", getUndoRedoStateObject());
        callbackContext.success(result);
        return true;
    }

    private boolean getUndoRedoState(CallbackContext callbackContext) throws JSONException {
        callbackContext.success(getUndoRedoStateObject());
        return true;
    }

    private boolean clearHistory(CallbackContext callbackContext) {
        undoHistory.clear();
        currentHistoryPosition = -1;
        callbackContext.success();
        return true;
    }

    private JSONObject getUndoRedoStateObject() throws JSONException {
        JSONObject state = new JSONObject();
        state.put("canUndo", currentHistoryPosition > 0);
        state.put("canRedo", currentHistoryPosition < undoHistory.size() - 1);
        state.put("currentPosition", currentHistoryPosition);
        state.put("historyLength", undoHistory.size());
        return state;
    }

    // ==================== Share Extension ====================

    private boolean getSharedContent(CallbackContext callbackContext) throws JSONException {
        JSONObject result = new JSONObject();
        // This would typically be populated by the Android share intent handler
        // For now, return empty state
        result.put("hasContent", false);
        result.put("text", "");
        result.put("url", "");
        result.put("files", new JSONArray());
        callbackContext.success(result);
        return true;
    }

    private boolean clearSharedContent(CallbackContext callbackContext) {
        callbackContext.success();
        return true;
    }
}

package com.vortacraftmc.datapackfixer;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParseException;
import com.google.gson.JsonParser;
import java.io.IOException;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

public final class DatapackSyntaxScanner {
    static final long MAX_FILE_SIZE = 2_000_000L;
    static final int MAX_FILES = 20_000;
    static final long MAX_TOTAL_BYTES = 256L * 1024 * 1024;
    static final int MAX_DIAGNOSTICS = 500;
    private static final Pattern LEGACY_RECIPE_INGREDIENT = Pattern.compile("\"(?:item|tag)\"\\s*:\\s*\"[^\"]+\"");

    private final FixerConfig config;
    private final List<MigrationRules.Rule> rules;

    public DatapackSyntaxScanner() {
        this(FixerConfig.MC_1_21_4);
    }

    public DatapackSyntaxScanner(FixerConfig config) {
        this.config = config;
        this.rules = MigrationRules.forConfig(config);
    }

    public List<Diagnostic> scan(Path datapacksDirectory) {
        if (!Files.isDirectory(datapacksDirectory)) return List.of();
        List<Diagnostic> results = new ArrayList<>();
        try {
            for (Path pack : topLevelDirectories(datapacksDirectory)) checkLegacyDirectories(pack, results);
            List<Path> files;
            try (Stream<Path> paths = Files.walk(datapacksDirectory)) {
                files = paths.filter(path -> Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS) && isRelevant(path))
                        .sorted(Comparator.comparing(Path::toString)).toList();
            }
            long totalBytes = 0;
            int scanned = 0;
            for (Path file : files) {
                if (results.size() >= MAX_DIAGNOSTICS) {
                    results.add(new Diagnostic(datapacksDirectory, 1, Diagnostic.Severity.WARNING, "DIAGNOSTIC_LIMIT",
                            "Stopped after " + MAX_DIAGNOSTICS + " diagnostics.", "Fix the reported issues and scan again."));
                    break;
                }
                if (scanned >= MAX_FILES || totalBytes >= MAX_TOTAL_BYTES) {
                    results.add(new Diagnostic(datapacksDirectory, 1, Diagnostic.Severity.WARNING, "SCAN_LIMIT",
                            "Stopped after " + scanned + " text files / " + (totalBytes / 1_048_576) + " MiB to protect server startup time.",
                            "Split unusually large datapack directories or remove unrelated files."));
                    break;
                }
                totalBytes += scanFile(datapacksDirectory, file, results);
                scanned++;
            }
        } catch (IOException exception) {
            results.add(new Diagnostic(datapacksDirectory, 1, Diagnostic.Severity.ERROR, "SCAN_IO",
                    "Could not enumerate datapacks: " + exception.getMessage(), "Check filesystem permissions."));
        }
        return List.copyOf(results);
    }

    private static boolean isRelevant(Path path) {
        String name = path.getFileName().toString().toLowerCase(Locale.ROOT);
        return name.endsWith(".json") || name.endsWith(".mcfunction") || name.equals("pack.mcmeta");
    }

    private static List<Path> topLevelDirectories(Path root) throws IOException {
        try (Stream<Path> stream = Files.list(root)) {
            return stream.filter(path -> Files.isDirectory(path, LinkOption.NOFOLLOW_LINKS))
                    .sorted(Comparator.comparing(Path::toString)).toList();
        }
    }

    /** One diagnostic per legacy directory (the old code emitted one per file, and never saw .nbt-only structures/). */
    private void checkLegacyDirectories(Path pack, List<Diagnostic> results) throws IOException {
        if (!config.atLeast(FixerConfig.FORMAT_1_21)) return;
        Path data = pack.resolve("data");
        if (!Files.isDirectory(data, LinkOption.NOFOLLOW_LINKS)) return;
        for (Path namespace : topLevelDirectories(data)) {
            for (Map.Entry<String, String> entry : LegacyDirectories.ordered()) {
                Path legacy = namespace.resolve(entry.getKey());
                if (!Files.isDirectory(legacy, LinkOption.NOFOLLOW_LINKS)) continue;
                Path modern = namespace.resolve(entry.getValue());
                if (Files.exists(modern, LinkOption.NOFOLLOW_LINKS)) {
                    results.add(new Diagnostic(legacy, 1, Diagnostic.Severity.ERROR, "LEGACY_DIRECTORY_CONFLICT",
                            "Legacy directory '" + entry.getKey() + "' exists next to '" + entry.getValue() + "'; the legacy one is ignored by modern versions.",
                            "Merge the contents into '" + entry.getValue() + "' manually; the fixer will not merge two directories."));
                } else {
                    results.add(new Diagnostic(legacy, 1, Diagnostic.Severity.ERROR, "LEGACY_DIRECTORY",
                            "Legacy datapack directory '" + entry.getKey() + "' is not loaded by modern versions.",
                            "Move it to '" + entry.getValue() + "'."));
                }
            }
        }
    }

    /** @return bytes read, for the total-size budget */
    private long scanFile(Path root, Path file, List<Diagnostic> results) {
        String normalized = root.relativize(file).toString().replace('\\', '/').toLowerCase(Locale.ROOT);
        boolean isJson = normalized.endsWith(".json") || normalized.endsWith("pack.mcmeta");
        boolean isFunction = normalized.endsWith(".mcfunction");
        try {
            long size = Files.size(file);
            if (size > MAX_FILE_SIZE) return 0;
            String content = Files.readString(file, StandardCharsets.UTF_8);
            if (isJson) checkJson(file, content, results);
            if (isPackMetadata(normalized)) checkPackMetadata(file, content, results);
            if (isFunction) checkFunction(file, content, results);
            checkKnownMigrations(file, normalized, content, results);
            return size;
        } catch (CharacterCodingException exception) {
            results.add(new Diagnostic(file, 1, Diagnostic.Severity.ERROR, "READ_ENCODING",
                    "File is not valid UTF-8.", "Re-save the file as UTF-8 without BOM."));
        } catch (IOException exception) {
            results.add(new Diagnostic(file, 1, Diagnostic.Severity.ERROR, "READ_IO",
                    "Could not read file: " + exception.getMessage(), "Check file encoding and permissions."));
        }
        return 0;
    }

    private static boolean isPackMetadata(String normalized) {
        return normalized.equals("pack.mcmeta") || (normalized.endsWith("/pack.mcmeta") && normalized.indexOf('/') == normalized.lastIndexOf('/'));
    }

    private static void checkJson(Path file, String content, List<Diagnostic> results) {
        try {
            JsonParser.parseString(content);
        } catch (JsonParseException exception) {
            results.add(new Diagnostic(file, lineOf(exception.getMessage()), Diagnostic.Severity.ERROR, "JSON_INVALID",
                    "Invalid JSON: " + compact(exception.getMessage()), "Repair JSON punctuation, quoting, or delimiters."));
        }
    }

    private void checkPackMetadata(Path file, String content, List<Diagnostic> results) {
        try {
            JsonElement root = JsonParser.parseString(content);
            if (!root.isJsonObject() || !root.getAsJsonObject().has("pack") || !root.getAsJsonObject().get("pack").isJsonObject()) {
                results.add(new Diagnostic(file, 1, Diagnostic.Severity.ERROR, "PACK_METADATA_MISSING",
                        "pack.mcmeta must contain a top-level 'pack' object.",
                        "Add a valid pack object with a format declaration and description."));
                return;
            }
            JsonObject pack = root.getAsJsonObject().getAsJsonObject("pack");
            if (config.atLeast(FixerConfig.FORMAT_SUPPORTED_OBJECT) && pack.has("supported_formats") && pack.get("supported_formats").isJsonArray()) {
                results.add(new Diagnostic(file, 1, Diagnostic.Severity.ERROR, "PACK_SUPPORTED_FORMATS_ARRAY",
                        "supported_formats as an array is rejected by this pack format.",
                        "Use {\"min_inclusive\":X,\"max_inclusive\":Y} (or min_format/max_format)."));
            }
            if (config.atLeast(FixerConfig.FORMAT_MIN_MAX)) {
                if (!pack.has("pack_format") && !pack.has("min_format")) {
                    results.add(new Diagnostic(file, 1, Diagnostic.Severity.ERROR, "PACK_FORMAT_MISSING",
                            "pack.mcmeta declares neither min_format nor pack_format.",
                            "Add min_format and max_format (pack_format is optional from format " + FixerConfig.FORMAT_MIN_MAX + " on)."));
                }
            } else if (!pack.has("pack_format")) {
                results.add(new Diagnostic(file, 1, Diagnostic.Severity.ERROR, "PACK_FORMAT_MISSING",
                        "pack.mcmeta is missing pack_format.",
                        "Set pack_format to " + config.dataPackFormat() + " for this server version."));
            }
        } catch (JsonParseException ignored) {
            // The JSON parser diagnostic is already reported by checkJson.
        }
    }

    private void checkKnownMigrations(Path file, String normalized, String content, List<Diagnostic> results) {
        if (!isPackMetadata(normalized)) {
            for (MigrationRules.Rule rule : rules) {
                Matcher matcher = rule.pattern().matcher(content);
                if (matcher.find()) {
                    results.add(new Diagnostic(file, lineAt(content, matcher.start()), Diagnostic.Severity.ERROR,
                            rule.code(), rule.message(), rule.suggestion()));
                }
            }
        }
        if (config.atLeast(FixerConfig.FORMAT_1_21_2) && normalized.contains("/recipe/")) {
            Matcher matcher = LEGACY_RECIPE_INGREDIENT.matcher(content);
            if (matcher.find()) {
                results.add(new Diagnostic(file, lineAt(content, matcher.start()), Diagnostic.Severity.WARNING, "RECIPE_INGREDIENT_LEGACY",
                        "Recipe ingredients may use the pre-1.21.2 object form.",
                        "Use an item id string or a #tag string where the recipe schema accepts an ingredient."));
            }
        }
    }

    private static void checkFunction(Path file, String content, List<Diagnostic> results) {
        for (McFunctionLinter.Issue issue : McFunctionLinter.lint(content)) {
            results.add(new Diagnostic(file, issue.line(), Diagnostic.Severity.ERROR, "FUNCTION_DELIMITER",
                    issue.message(), "Balance quotes, brackets, and braces on the affected command."));
        }
    }

    private static int lineAt(String content, int offset) {
        int line = 1;
        for (int i = 0; i < offset && i < content.length(); i++) if (content.charAt(i) == '\n') line++;
        return line;
    }

    private static int lineOf(String message) {
        if (message == null) return 1;
        Matcher matcher = Pattern.compile("line (\\d+)").matcher(message);
        return matcher.find() ? Integer.parseInt(matcher.group(1)) : 1;
    }

    private static String compact(String message) {
        return message == null ? "unknown parser error" : message.replaceAll("\\s+", " ");
    }
}

package com.vortacraftmc.datapackfixer;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParseException;
import com.google.gson.JsonParser;
import java.io.IOException;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.StandardCharsets;
import java.nio.file.AtomicMoveNotSupportedException;
import java.nio.file.FileAlreadyExistsException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Stream;

public final class DatapackFixerEngine {
    // HTML escaping off: the default would turn '&', '<', '=' in a pack description into \\uXXXX escapes.
    private static final Gson JSON = new GsonBuilder().setPrettyPrinting().disableHtmlEscaping().create();

    private final FixerConfig config;
    private final List<MigrationRules.Rule> rules;

    public DatapackFixerEngine() {
        this(FixerConfig.MC_1_21_4);
    }

    public DatapackFixerEngine(FixerConfig config) {
        this.config = config;
        this.rules = MigrationRules.forConfig(config);
    }

    /** Applies repairs. Only packs that actually change are backed up; a failing pack is rolled back from its backup. */
    public FixResult fix(Path datapacksDirectory, Path backupRoot) throws IOException {
        return run(datapacksDirectory, backupRoot, false);
    }

    /** Dry run: reports what {@link #fix} would change without touching the disk. */
    public FixResult plan(Path datapacksDirectory) throws IOException {
        return run(datapacksDirectory, null, true);
    }

    private FixResult run(Path datapacks, Path backupRoot, boolean dryRun) throws IOException {
        if (!Files.isDirectory(datapacks)) return new FixResult(0, 0, 0, List.of("Datapacks directory does not exist."));
        List<Path> packs;
        try (Stream<Path> stream = Files.list(datapacks)) {
            packs = stream.filter(path -> Files.isDirectory(path, LinkOption.NOFOLLOW_LINKS))
                    .sorted(Comparator.comparing(Path::toString)).toList();
        }
        List<String> audit = new ArrayList<>();
        Path backup = null;
        int backedUp = 0, skipped = 0, changes = 0;
        for (Path pack : packs) {
            List<String> packAudit = new ArrayList<>();
            int planned = process(pack, false, packAudit);
            if (planned == 0) { audit.addAll(packAudit.stream().filter(line -> line.startsWith("SKIPPED_")).toList()); continue; }
            if (dryRun) {
                audit.add("WOULD_CHANGE " + pack.getFileName() + " (" + planned + " change(s))");
                audit.addAll(packAudit);
                changes += planned;
                continue;
            }
            if (!isWritableTree(pack)) {
                audit.add("SKIPPED_NOT_WRITABLE " + pack.getFileName() + " (locked? run /datapackblocker unlock first)");
                skipped++;
                continue;
            }
            if (backup == null) backup = createBackupDirectory(backupRoot);
            Path packBackup = backup.resolve(pack.getFileName());
            copyTree(pack, packBackup);
            backedUp++;
            List<String> applied = new ArrayList<>();
            try {
                changes += process(pack, true, applied);
                audit.addAll(applied);
            } catch (IOException | RuntimeException exception) {
                try {
                    deleteTree(pack);
                    copyTree(packBackup, pack);
                    audit.add("FAILED_ROLLED_BACK " + pack.getFileName() + ": " + exception.getMessage());
                } catch (IOException rollbackFailure) {
                    audit.add("FAILED_ROLLBACK_INCOMPLETE " + pack.getFileName() + ": restore manually from " + packBackup);
                }
                skipped++;
            }
        }
        if (backup != null) Files.writeString(backup.resolve("audit.txt"), String.join(System.lineSeparator(), audit), StandardCharsets.UTF_8);
        return new FixResult(backedUp, skipped, changes, List.copyOf(audit));
    }

    /** Renames legacy directories and transforms files. With {@code write == false} nothing on disk is touched. */
    private int process(Path pack, boolean write, List<String> audit) throws IOException {
        int changes = renameLegacyDirectories(pack, write, audit);
        List<Path> files;
        try (Stream<Path> stream = Files.walk(pack)) {
            files = stream.filter(path -> Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS))
                    .sorted(Comparator.comparing(Path::toString)).toList();
        }
        for (Path file : files) {
            String fixed = transform(pack, file, audit);
            if (fixed == null) continue;
            if (write) writeAtomically(file, fixed);
            audit.add((write ? "UPDATED_FILE " : "WOULD_UPDATE_FILE ") + pack.relativize(file));
            changes++;
        }
        return changes;
    }

    private int renameLegacyDirectories(Path pack, boolean write, List<String> audit) throws IOException {
        if (!config.atLeast(FixerConfig.FORMAT_1_21)) return 0;
        Path data = pack.resolve("data");
        if (!Files.isDirectory(data, LinkOption.NOFOLLOW_LINKS)) return 0;
        int changes = 0;
        List<Path> namespaces;
        try (Stream<Path> stream = Files.list(data)) {
            namespaces = stream.filter(path -> Files.isDirectory(path, LinkOption.NOFOLLOW_LINKS)).sorted(Comparator.comparing(Path::toString)).toList();
        }
        for (Path namespace : namespaces) {
            for (Map.Entry<String, String> entry : LegacyDirectories.ordered()) {
                Path legacy = namespace.resolve(entry.getKey());
                Path replacement = namespace.resolve(entry.getValue());
                if (!Files.isDirectory(legacy, LinkOption.NOFOLLOW_LINKS)) continue;
                if (Files.exists(replacement, LinkOption.NOFOLLOW_LINKS)) {
                    audit.add("SKIPPED_DIRECTORY_CONFLICT " + pack.relativize(legacy) + " (target already exists; merge manually)");
                    continue;
                }
                if (write) {
                    Files.createDirectories(replacement.getParent());
                    Files.move(legacy, replacement);
                }
                audit.add((write ? "RENAMED_DIRECTORY " : "WOULD_RENAME_DIRECTORY ") + pack.relativize(legacy) + " -> " + pack.relativize(replacement));
                changes++;
            }
        }
        return changes;
    }

    /** @return the new content, or null when the file needs no change (or must not be touched). */
    private String transform(Path pack, Path file, List<String> audit) throws IOException {
        String name = file.getFileName().toString().toLowerCase(Locale.ROOT);
        boolean packMeta = name.equals("pack.mcmeta") && pack.equals(file.getParent());
        boolean json = name.endsWith(".json");
        boolean function = name.endsWith(".mcfunction");
        if (!(packMeta || json || function)) return null;
        if (Files.size(file) > DatapackSyntaxScanner.MAX_FILE_SIZE) return null;
        String original;
        try {
            original = Files.readString(file, StandardCharsets.UTF_8);
        } catch (CharacterCodingException exception) {
            audit.add("SKIPPED_NOT_UTF8 " + pack.relativize(file));
            return null;
        }
        String fixed = original;
        if (packMeta) {
            fixed = addMissingPackFormat(fixed);
        } else {
            for (MigrationRules.Rule rule : rules) fixed = rule.apply(fixed);
        }
        if (fixed.equals(original)) return null;
        // A repair must never turn valid JSON into invalid JSON.
        if ((json || packMeta) && parses(original) && !parses(fixed)) {
            audit.add("SKIPPED_UNSAFE_REPAIR " + pack.relativize(file));
            return null;
        }
        return fixed;
    }

    private String addMissingPackFormat(String source) {
        // From FORMAT_MIN_MAX on, which range to declare is the pack author's decision.
        if (config.atLeast(FixerConfig.FORMAT_MIN_MAX)) return source;
        try {
            JsonElement root = JsonParser.parseString(source);
            if (!root.isJsonObject()) return source;
            JsonObject top = root.getAsJsonObject();
            if (!top.has("pack") || !top.get("pack").isJsonObject()) return source;
            JsonObject pack = top.getAsJsonObject("pack");
            if (pack.has("pack_format") || pack.has("min_format") || pack.has("max_format")) return source;
            pack.addProperty("pack_format", config.dataPackFormat());
            return JSON.toJson(top) + System.lineSeparator();
        } catch (RuntimeException ignored) {
            return source;
        }
    }

    private static boolean parses(String source) {
        try {
            JsonParser.parseString(source);
            return true;
        } catch (JsonParseException exception) {
            return false;
        }
    }

    private static void writeAtomically(Path file, String content) throws IOException {
        Path temporary = file.resolveSibling(file.getFileName() + ".dpfixer.tmp");
        Files.writeString(temporary, content, StandardCharsets.UTF_8);
        try {
            Files.move(temporary, file, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);
        } catch (AtomicMoveNotSupportedException exception) {
            Files.move(temporary, file, StandardCopyOption.REPLACE_EXISTING);
        }
    }

    private static boolean isWritableTree(Path pack) throws IOException {
        try (Stream<Path> stream = Files.walk(pack)) {
            return stream.allMatch(path -> Files.isSymbolicLink(path) || Files.isWritable(path));
        }
    }

    private static Path createBackupDirectory(Path backupRoot) throws IOException {
        Files.createDirectories(backupRoot);
        String stamp = Instant.now().toString().replace(':', '-');
        for (int attempt = 0; ; attempt++) {
            Path candidate = backupRoot.resolve(attempt == 0 ? stamp : stamp + "-" + attempt);
            try {
                return Files.createDirectory(candidate);
            } catch (FileAlreadyExistsException exception) {
                if (attempt > 100) throw exception;
            }
        }
    }

    private static void copyTree(Path source, Path destination) throws IOException {
        try (Stream<Path> paths = Files.walk(source)) {
            for (Path path : paths.toList()) {
                Path target = destination.resolve(source.relativize(path).toString());
                if (Files.isDirectory(path, LinkOption.NOFOLLOW_LINKS)) Files.createDirectories(target);
                else Files.copy(path, target, LinkOption.NOFOLLOW_LINKS, StandardCopyOption.COPY_ATTRIBUTES);
            }
        }
    }

    private static void deleteTree(Path root) throws IOException {
        try (Stream<Path> paths = Files.walk(root)) {
            for (Path path : paths.sorted(Comparator.reverseOrder()).toList()) Files.delete(path);
        }
    }

    public record FixResult(int packsBackedUp, int packsSkipped, int changes, List<String> audit) { }
}

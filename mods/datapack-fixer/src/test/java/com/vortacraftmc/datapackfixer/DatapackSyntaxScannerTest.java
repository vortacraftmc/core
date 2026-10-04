package com.vortacraftmc.datapackfixer;

import static org.junit.jupiter.api.Assertions.*;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class DatapackSyntaxScannerTest {
    private static final FixerConfig F26_2 = new FixerConfig(FixerConfig.FORMAT_26_2);

    private static Path write(Path root, String relative, String content) throws Exception {
        Path file = root.resolve(relative);
        Files.createDirectories(file.getParent());
        Files.writeString(file, content);
        return file;
    }

    private static boolean has(java.util.List<Diagnostic> diagnostics, String code) {
        return diagnostics.stream().anyMatch(d -> d.code().equals(code));
    }

    @Test void reportsInvalidJsonWithoutWritingFiles() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        Path file = write(root, "sample/data/example/recipe/broken.json", "{ \"type\": ");
        assertTrue(has(new DatapackSyntaxScanner().scan(root), "JSON_INVALID"));
        assertEquals("{ \"type\": ", Files.readString(file));
    }

    @Test void legacyDirectoryIsReportedOncePerDirectoryEvenForNbtOnlyStructures() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        write(root, "sample/data/example/predicates/a.json", "{}");
        write(root, "sample/data/example/predicates/b.json", "{}");
        Files.createDirectories(root.resolve("sample/data/example/structures"));
        Files.write(root.resolve("sample/data/example/structures/house.nbt"), new byte[] {1, 2, 3});
        var diagnostics = new DatapackSyntaxScanner().scan(root);
        assertEquals(2, diagnostics.stream().filter(d -> d.code().equals("LEGACY_DIRECTORY")).count());
    }

    @Test void legacyAndModernDirectoryTogetherIsAConflictNotASilentMove() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        write(root, "sample/data/example/functions/a.mcfunction", "say a");
        write(root, "sample/data/example/function/b.mcfunction", "say b");
        assertTrue(has(new DatapackSyntaxScanner().scan(root), "LEGACY_DIRECTORY_CONFLICT"));
    }

    @Test void slimeRenameOnlyAppliesFrom26_2() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        write(root, "sample/data/example/predicate/slime.json", "{\"type\":\"minecraft:type_specific/slime\"}");
        assertFalse(has(new DatapackSyntaxScanner().scan(root), "TYPE_SPECIFIC_SLIME"), "1.21.4 must keep 'slime'");
        assertTrue(has(new DatapackSyntaxScanner(F26_2).scan(root), "TYPE_SPECIFIC_SLIME"));
    }

    @Test void alternativeRenameIsWhitespaceInsensitive() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        write(root, "sample/data/example/predicate/a.json", "{\"condition\":\"minecraft:alternative\"}");
        write(root, "sample/data/example/predicate/b.json", "{\"condition\" :   \"alternative\"}");
        assertEquals(2, new DatapackSyntaxScanner().scan(root).stream().filter(d -> d.code().equals("ALTERNATIVE_RENAMED")).count());
    }

    @Test void packMetadataRulesDependOnFormat() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        write(root, "sample/pack.mcmeta", "{\"pack\": {\"description\": \"x\"}}");
        assertTrue(has(new DatapackSyntaxScanner().scan(root), "PACK_FORMAT_MISSING"));
        write(root, "ranged/pack.mcmeta", "{\"pack\": {\"description\": \"x\", \"min_format\": 107, \"max_format\": 107}}");
        var modern = new DatapackSyntaxScanner(F26_2).scan(root);
        assertEquals(1, modern.stream().filter(d -> d.code().equals("PACK_FORMAT_MISSING")).count(), "only the pack without any format");
        write(root, "array/pack.mcmeta", "{\"pack\": {\"description\": \"x\", \"pack_format\": 94, \"supported_formats\": [88, 94]}}");
        assertTrue(has(new DatapackSyntaxScanner(F26_2).scan(root), "PACK_SUPPORTED_FORMATS_ARRAY"));
    }

    @Test void ignoresBinaryFilesAndSkipsZip() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        Files.createDirectories(root.resolve("sample"));
        Files.write(root.resolve("sample/pack.png"), new byte[] {(byte) 0x89, 0x50, 0x4e, 0x47});
        Files.write(root.resolve("packed-datapack.zip"), new byte[] {0x50, 0x4b, 0x03, 0x04, (byte) 0xff});
        assertTrue(new DatapackSyntaxScanner().scan(root).isEmpty());
    }

    @Test void reportsNonUtf8AsEncodingNotIoError() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        Files.createDirectories(root.resolve("sample/data/e/function"));
        Files.write(root.resolve("sample/data/e/function/x.mcfunction"), new byte[] {'s', 'a', 'y', ' ', (byte) 0xff, (byte) 0xfe});
        assertTrue(has(new DatapackSyntaxScanner().scan(root), "READ_ENCODING"));
    }

    @Test void functionLinterFindsRealProblemsOnTheRightLine() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        write(root, "sample/data/e/function/load.mcfunction",
                "say ok\n\ngive @s minecraft:stone[custom_name='broken'\nsay after\n");
        var d = new DatapackSyntaxScanner().scan(root).stream().filter(x -> x.code().equals("FUNCTION_DELIMITER")).toList();
        assertEquals(1, d.size());
        assertEquals(3, d.get(0).line());
    }

    @Test void functionLinterHasNoFalsePositivesOnCommentsFreeTextAndContinuations() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        write(root, "sample/data/e/function/ok.mcfunction",
                "# comment with [ unbalanced \" stuff {\n"
                        + "say don't [panic\n"
                        + "execute as @a run say it's [fine\n"
                        + "tellraw @a {\"text\":\"a ] b\"}\n"
                        + "give @s stick[custom_name='{\"text\":\"x [y\"}']\n"
                        + "data merge storage a:b {list:[1,2,\n"
                        + "title @a title don't\n"
                        + "$data modify storage a:b x set value {v:\"$(v)\"}\n");
        var diagnostics = new DatapackSyntaxScanner().scan(root);
        // the multi-line SNBT (line 6) is a real unclosed list; everything else must be clean
        var d = diagnostics.stream().filter(x -> x.code().equals("FUNCTION_DELIMITER")).toList();
        assertEquals(1, d.size(), diagnostics.toString());
        assertEquals(6, d.get(0).line());
    }

    @Test void backslashContinuationJoinsLines() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        write(root, "sample/data/e/function/c.mcfunction", "data merge storage a:b {\\\n  x:1\\\n}\n");
        assertTrue(new DatapackSyntaxScanner().scan(root).isEmpty());
    }

    @Test void mismatchedBracketsAreReported() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        write(root, "sample/data/e/function/m.mcfunction", "give @s stone[a={b:1]}\n");
        assertTrue(has(new DatapackSyntaxScanner().scan(root), "FUNCTION_DELIMITER"));
    }

    @Test void scanNeverFollowsSymlinks() throws Exception {
        Path outside = Files.createTempDirectory("dfx-outside");
        write(outside, "evil.json", "{ broken");
        Path root = Files.createTempDirectory("dfx");
        Files.createDirectories(root.resolve("sample"));
        try {
            Files.createSymbolicLink(root.resolve("sample/link"), outside);
        } catch (UnsupportedOperationException | java.io.IOException skip) {
            return;
        }
        assertFalse(has(new DatapackSyntaxScanner().scan(root), "JSON_INVALID"));
    }
}

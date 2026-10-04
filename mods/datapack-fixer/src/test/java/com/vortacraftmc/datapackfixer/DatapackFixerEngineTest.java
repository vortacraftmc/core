package com.vortacraftmc.datapackfixer;

import static org.junit.jupiter.api.Assertions.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.PosixFilePermissions;
import org.junit.jupiter.api.Test;

class DatapackFixerEngineTest {
    private static final FixerConfig F26_2 = new FixerConfig(FixerConfig.FORMAT_26_2);

    private static Path write(Path root, String relative, String content) throws Exception {
        Path file = root.resolve(relative);
        Files.createDirectories(file.getParent());
        Files.writeString(file, content);
        return file;
    }

    @Test void createsBackupAndAppliesOnlyAllowlistedRepairsOn1_21_4() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        Path pack = root.resolve("legacy-pack");
        write(pack, "data/example/functions/load.mcfunction", "execute if predicate minecraft:type_specific/slime run say ready");
        write(pack, "pack.mcmeta", "{\"pack\":{\"description\":\"A & B <test>\"}}");
        Path backups = Files.createTempDirectory("dfx-backups");

        var result = new DatapackFixerEngine().fix(root, backups);

        assertEquals(1, result.packsBackedUp());
        assertEquals(2, result.changes(), "directory rename + pack_format; slime must stay on 1.21.4");
        Path fixed = pack.resolve("data/example/function/load.mcfunction");
        assertTrue(Files.readString(fixed).contains("minecraft:type_specific/slime"));
        String mcmeta = Files.readString(pack.resolve("pack.mcmeta"));
        assertTrue(mcmeta.contains("\"pack_format\": 61"));
        assertTrue(mcmeta.contains("A & B <test>"), "no \\u0026 HTML escaping: " + mcmeta);
        try (var dirs = Files.list(backups)) {
            Path backup = dirs.findFirst().orElseThrow();
            assertTrue(Files.exists(backup.resolve("legacy-pack/data/example/functions/load.mcfunction")));
            assertTrue(Files.exists(backup.resolve("audit.txt")));
        }
    }

    @Test void appliesSlimeRenameOnlyFor26_2AndDoesNotInventPackFormat() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        Path pack = root.resolve("p");
        write(pack, "data/example/predicate/s.json", "{\"type\":\"minecraft:type_specific/slime\"}");
        write(pack, "pack.mcmeta", "{\"pack\":{\"description\":\"x\"}}");
        var result = new DatapackFixerEngine(F26_2).fix(root, Files.createTempDirectory("dfx-backups"));
        assertEquals(1, result.changes());
        assertTrue(Files.readString(pack.resolve("data/example/predicate/s.json")).contains("type_specific/cube_mob"));
        assertFalse(Files.readString(pack.resolve("pack.mcmeta")).contains("pack_format"), "format range is the author's choice on 26.x");
    }

    @Test void alternativeRepairKeepsFormattingAndNamespaceChoice() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        Path file = write(root, "p/data/e/predicate/a.json", "{\"condition\":  \"minecraft:alternative\", \"x\": 1}");
        write(root, "p/data/e/predicate/b.json", "{\"condition\":\"alternative\"}");
        new DatapackFixerEngine().fix(root, Files.createTempDirectory("dfx-backups"));
        assertEquals("{\"condition\":  \"minecraft:any_of\", \"x\": 1}", Files.readString(file));
        assertEquals("{\"condition\":\"any_of\"}", Files.readString(root.resolve("p/data/e/predicate/b.json")));
    }

    @Test void onlyChangedPacksAreBackedUp() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        write(root, "clean/data/e/function/a.mcfunction", "say hi");
        write(root, "clean/pack.mcmeta", "{\"pack\":{\"pack_format\":61,\"description\":\"x\"}}");
        write(root, "dirty/data/e/functions/a.mcfunction", "say hi");
        Path backups = Files.createTempDirectory("dfx-backups");
        var result = new DatapackFixerEngine().fix(root, backups);
        assertEquals(1, result.packsBackedUp());
        try (var dirs = Files.list(backups)) {
            Path backup = dirs.findFirst().orElseThrow();
            assertFalse(Files.exists(backup.resolve("clean")));
            assertTrue(Files.exists(backup.resolve("dirty")));
        }
    }

    @Test void secondRunIsANoOpAndCreatesNoBackup() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        write(root, "p/data/e/functions/a.mcfunction", "say hi");
        Path backups = Files.createTempDirectory("dfx-backups");
        new DatapackFixerEngine().fix(root, backups);
        var again = new DatapackFixerEngine().fix(root, Files.createTempDirectory("dfx-backups2"));
        assertEquals(0, again.changes());
        assertEquals(0, again.packsBackedUp());
    }

    @Test void planWritesNothing() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        Path legacy = write(root, "p/data/e/functions/a.mcfunction", "say hi");
        var plan = new DatapackFixerEngine().plan(root);
        assertTrue(plan.changes() >= 1);
        assertTrue(Files.exists(legacy), "dry run must not rename");
    }

    @Test void directoryConflictIsLeftAloneAndReported() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        write(root, "p/data/e/functions/a.mcfunction", "say a");
        write(root, "p/data/e/function/b.mcfunction", "say b");
        var result = new DatapackFixerEngine().fix(root, Files.createTempDirectory("dfx-backups"));
        assertEquals(0, result.changes());
        assertTrue(Files.exists(root.resolve("p/data/e/functions/a.mcfunction")));
        assertTrue(result.audit().stream().anyMatch(l -> l.startsWith("SKIPPED_DIRECTORY_CONFLICT")));
    }

    @Test void neverWritesThroughSymlinks() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        Path outside = write(Files.createTempDirectory("dfx-outside"), "target.json", "{\"condition\":\"minecraft:alternative\"}");
        write(root, "p/data/e/predicate/a.json", "{\"condition\":\"minecraft:alternative\"}");
        try {
            Files.createSymbolicLink(root.resolve("p/data/e/predicate/link.json"), outside);
        } catch (UnsupportedOperationException | java.io.IOException skip) {
            return;
        }
        new DatapackFixerEngine().fix(root, Files.createTempDirectory("dfx-backups"));
        assertEquals("{\"condition\":\"minecraft:alternative\"}", Files.readString(outside), "file outside the datapacks folder was modified");
    }

    @Test void lockedPackIsSkippedInsteadOfHalfRepaired() throws Exception {
        Path root = Files.createTempDirectory("dfx");
        Path pack = root.resolve("p");
        write(pack, "data/e/functions/a.mcfunction", "say hi");
        try {
            Files.setPosixFilePermissions(pack.resolve("data/e/functions"), PosixFilePermissions.fromString("r-xr-xr-x"));
            Files.setPosixFilePermissions(pack.resolve("data/e"), PosixFilePermissions.fromString("r-xr-xr-x"));
        } catch (UnsupportedOperationException skip) {
            return;
        }
        if (Files.isWritable(pack.resolve("data/e"))) return; // running as root: permission bits are not enforced
        try {
            var result = new DatapackFixerEngine().fix(root, Files.createTempDirectory("dfx-backups"));
            assertEquals(1, result.packsSkipped());
            assertTrue(result.audit().stream().anyMatch(l -> l.startsWith("SKIPPED_NOT_WRITABLE")));
            assertTrue(Files.exists(pack.resolve("data/e/functions/a.mcfunction")));
        } finally {
            Files.setPosixFilePermissions(pack.resolve("data/e"), PosixFilePermissions.fromString("rwxr-xr-x"));
            Files.setPosixFilePermissions(pack.resolve("data/e/functions"), PosixFilePermissions.fromString("rwxr-xr-x"));
        }
    }
}

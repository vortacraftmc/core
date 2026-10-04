package com.vortacraftmc.datapackfixer;

import com.mojang.brigadier.Command;
import java.nio.file.Path;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerLifecycleEvents;
import net.minecraft.server.command.CommandManager;
import net.minecraft.text.Text;
import net.minecraft.util.WorldSavePath;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class DatapackFixerMod implements ModInitializer {
    private static final Logger LOGGER = LoggerFactory.getLogger("datapack-fixer");
    private static final int MAX_LOGGED_DIAGNOSTICS = 100;
    private static final int MAX_CHAT_LINES = 8;

    @Override
    public void onInitialize() {
        // The data pack format this build targets; override with -Ddatapackfixer.format=<n> (see FixerConfig).
        FixerConfig config = FixerConfig.fromSystemProperties(FixerConfig.MC_1_21_4);
        LOGGER.info("Datapack Fixer targets data pack format {}.", config.dataPackFormat());

        // Scan off the main thread so a large datapacks folder cannot delay server startup.
        ServerLifecycleEvents.SERVER_STARTED.register(server -> {
            Path datapacks = server.getSavePath(WorldSavePath.DATAPACKS);
            CompletableFuture.runAsync(() -> scanAndLog(datapacks, config));
        });

        CommandRegistrationCallback.EVENT.register((dispatcher, registryAccess, environment) -> dispatcher.register(
                CommandManager.literal("datapackfixer").requires(source -> source.hasPermissionLevel(4))
                        .then(CommandManager.literal("scan").executes(context -> {
                            Path datapacks = context.getSource().getServer().getSavePath(WorldSavePath.DATAPACKS);
                            List<Diagnostic> diagnostics = scanAndLog(datapacks, config);
                            long errors = diagnostics.stream().filter(d -> d.severity() == Diagnostic.Severity.ERROR).count();
                            context.getSource().sendFeedback(() -> Text.literal("Datapack Fixer scan: " + diagnostics.size()
                                    + " issue(s), " + errors + " error(s). Full list in the server log."), false);
                            diagnostics.stream().limit(MAX_CHAT_LINES).forEach(d -> context.getSource().sendFeedback(
                                    () -> Text.literal("[" + d.code() + "] " + display(datapacks, d.file()) + ":" + d.line()), false));
                            return Command.SINGLE_SUCCESS;
                        }))
                        .then(CommandManager.literal("plan").executes(context -> {
                            var server = context.getSource().getServer();
                            try {
                                var result = new DatapackFixerEngine(config).plan(server.getSavePath(WorldSavePath.DATAPACKS));
                                context.getSource().sendFeedback(() -> Text.literal("Datapack Fixer plan: " + result.changes()
                                        + " change(s) would be applied. Nothing was written."), false);
                                result.audit().stream().limit(MAX_CHAT_LINES).forEach(line -> context.getSource().sendFeedback(() -> Text.literal(line), false));
                                result.audit().forEach(line -> LOGGER.info("[plan] {}", line));
                                return Command.SINGLE_SUCCESS;
                            } catch (Exception exception) {
                                context.getSource().sendError(Text.literal("Datapack Fixer could not build a plan: " + exception.getMessage()));
                                return 0;
                            }
                        }))
                        .then(CommandManager.literal("fix").executes(context -> {
                            var server = context.getSource().getServer();
                            try {
                                var result = new DatapackFixerEngine(config).fix(server.getSavePath(WorldSavePath.DATAPACKS),
                                        server.getSavePath(WorldSavePath.ROOT).resolve("datapack_fixer_backups"));
                                context.getSource().sendFeedback(() -> Text.literal("Datapack Fixer backed up " + result.packsBackedUp()
                                        + " pack(s), applied " + result.changes() + " change(s), skipped " + result.packsSkipped()
                                        + " pack(s). Run /reload to load the repaired packs."), true);
                                result.audit().stream().filter(line -> line.startsWith("SKIPPED_") || line.startsWith("FAILED_"))
                                        .limit(MAX_CHAT_LINES).forEach(line -> context.getSource().sendFeedback(() -> Text.literal(line), false));
                                result.audit().forEach(line -> LOGGER.info("[fix] {}", line));
                                return Command.SINGLE_SUCCESS;
                            } catch (Exception exception) {
                                context.getSource().sendError(Text.literal("Datapack Fixer could not complete repair: " + exception.getMessage()));
                                return 0;
                            }
                        }))));
    }

    private static List<Diagnostic> scanAndLog(Path datapacks, FixerConfig config) {
        List<Diagnostic> diagnostics = new DatapackSyntaxScanner(config).scan(datapacks);
        if (diagnostics.isEmpty()) {
            LOGGER.info("Datapack Fixer found no supported syntax issues.");
            return diagnostics;
        }
        LOGGER.warn("Datapack Fixer found {} issue(s). /datapackfixer plan previews repairs; /datapackfixer fix backs up and applies them.", diagnostics.size());
        diagnostics.stream().limit(MAX_LOGGED_DIAGNOSTICS).forEach(d ->
                LOGGER.warn("[{}] {}:{} {} -> {}", d.code(), display(datapacks, d.file()), d.line(), d.message(), d.suggestion()));
        if (diagnostics.size() > MAX_LOGGED_DIAGNOSTICS) {
            LOGGER.warn("... {} more issue(s) not shown; run /datapackfixer scan after fixing the first ones.", diagnostics.size() - MAX_LOGGED_DIAGNOSTICS);
        }
        return diagnostics;
    }

    private static String display(Path root, Path file) {
        return file.startsWith(root) ? root.relativize(file).toString() : file.toString();
    }
}

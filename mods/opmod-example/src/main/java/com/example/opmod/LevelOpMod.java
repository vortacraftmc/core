package com.example.opmod;

import com.mojang.brigadier.arguments.IntegerArgumentType;
import com.mojang.brigadier.context.CommandContext;
import com.mojang.brigadier.exceptions.CommandSyntaxException;

import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback;

import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.commands.arguments.GameProfileArgument;
import net.minecraft.network.chat.Component;

import net.minecraft.server.level.ServerPlayer;
import net.minecraft.server.permissions.LevelBasedPermissionSet;
import net.minecraft.server.permissions.PermissionLevel;
import net.minecraft.server.players.NameAndId;
import net.minecraft.server.players.PlayerList;

import java.util.Collection;
import java.util.Optional;

public final class LevelOpMod implements ModInitializer {

    @Override
    public void onInitialize() {
        CommandRegistrationCallback.EVENT.register((dispatcher, registryAccess, environment) -> {
            dispatcher.register(
                Commands.literal("op")
                    .requires(LevelOpMod::canUseCommand)
                    .then(
                        Commands.argument(
                                "targets",
                                GameProfileArgument.gameProfile()
                            )
                            .then(
                                Commands.argument(
                                        "level",
                                        IntegerArgumentType.integer(1, 4)
                                    )
                                    .executes(LevelOpMod::opWithLevel)
                            )
                    )
            );
        });
    }

    private static boolean canUseCommand(CommandSourceStack source) {
        return source.permissions().hasPermission(
            LevelBasedPermissionSet.OWNER
        );
    }

    private static int opWithLevel(
        CommandContext<CommandSourceStack> context
    ) {
        Collection<NameAndId> targets;

        try {
            targets = GameProfileArgument.getGameProfiles(
                context,
                "targets"
            );
        } catch (CommandSyntaxException e) {
            context.getSource().sendFailure(
                Component.literal(
                    e.getMessage() != null
                        ? e.getMessage()
                        : "Invalid player target."
                )
            );

            return 0;
        }

        int level = IntegerArgumentType.getInteger(
            context,
            "level"
        );

        LevelBasedPermissionSet permissionSet =
            permissionSetForLevel(level);

        CommandSourceStack source = context.getSource();
        PlayerList playerList = source.getServer().getPlayerList();

        int affected = 0;

        for (NameAndId target : targets) {
            playerList.op(
                target,
                Optional.of(permissionSet),
                Optional.empty()
            );

            affected++;

            ServerPlayer player = playerList.getPlayer(target.id());

            if (player != null) {
                player.sendSystemMessage(
                    Component.translatable(
                        "commands.op.message",
                        level
                    )
                );
            }
        }

        if (affected == 0) {
            source.sendFailure(
                Component.translatable("commands.op.failed")
            );

            return 0;
        }

        String names = targets.stream()
            .map(NameAndId::name)
            .reduce((a, b) -> a + ", " + b)
            .orElse("");

        source.sendSuccess(
            () -> Component.translatable(
                "commands.op.success",
                names
            ),
            true
        );

        return affected;
    }

    private static LevelBasedPermissionSet permissionSetForLevel(int level) {
        return switch (PermissionLevel.byId(level)) {
            case ALL -> LevelBasedPermissionSet.ALL;
            case GAMEMASTER -> LevelBasedPermissionSet.GAMEMASTER;
            case ADMINS -> LevelBasedPermissionSet.ADMINS;
            case OWNERS -> LevelBasedPermissionSet.OWNER;
        };
    }
}

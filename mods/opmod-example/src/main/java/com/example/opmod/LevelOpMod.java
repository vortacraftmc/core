package com.example.opmod;

import com.mojang.brigadier.arguments.IntegerArgumentType;
import com.mojang.brigadier.context.CommandContext;
import com.mojang.brigadier.exceptions.SimpleCommandExceptionType;

import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback;
import net.minecraft.command.argument.GameProfileArgumentType;
import net.minecraft.server.PlayerManager;
import net.minecraft.server.command.CommandManager;
import net.minecraft.server.command.ServerCommandSource;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.text.Text;

import java.util.Collection;

import com.mojang.authlib.GameProfile;

/**
 * Adds a "level" argument to the vanilla /op command:
 *
 *   /op <targets>          -> vanilla behaviour, unchanged
 *                              (grants op at the server's op-permission-level)
 *   /op <targets> <level>  -> new behaviour added by this mod
 *                              (grants op at the given level, 1-4)
 */
public final class LevelOpMod implements ModInitializer {

	private static final SimpleCommandExceptionType ERROR_ALREADY_OP =
			new SimpleCommandExceptionType(Text.translatable("commands.op.failed"));

	@Override
	public void onInitialize() {
		CommandRegistrationCallback.EVENT.register((dispatcher, registryAccess, environment) -> {
			// Extend the existing "op" node with an extra literal path:
			// op <targets> <level: 1..4>
			dispatcher.register(CommandManager.literal("op")
					.requires(source -> source.hasPermissionLevel(3))
					.then(CommandManager.argument("targets", GameProfileArgumentType.gameProfile())
							.then(CommandManager.argument("level", IntegerArgumentType.integer(1, 4))
									.executes(LevelOpMod::opWithLevel))));
		});
	}

	private static int opWithLevel(CommandContext<ServerCommandSource> context) {
		Collection<GameProfile> targets;
		try {
			targets = GameProfileArgumentType.getProfileArgument(context, "targets");
		} catch (com.mojang.brigadier.exceptions.CommandSyntaxException e) {
			context.getSource().sendError(Text.literal(e.getMessage()));
			return 0;
		}

		int level = IntegerArgumentType.getInteger(context, "level");
		ServerCommandSource source = context.getSource();
		PlayerManager playerManager = source.getServer().getPlayerManager();

		int affected = 0;
		for (GameProfile profile : targets) {
			if (playerManager.getOpList().get(profile) != null
					&& playerManager.getOpList().get(profile).getPermissionLevel() == level) {
				continue;
			}

			playerManager.addToOperators(profile);

			// addToOperators() always writes the server-wide default level
			// (op-permission-level in server.properties). Overwrite the
			// entry we just wrote with the level the command caller asked for.
			OpLevelHelper.setOpLevel(playerManager, profile, level);

			affected++;

			ServerPlayerEntity player = source.getServer().getPlayerManager().getPlayer(profile.getId());
			if (player != null) {
				player.sendMessage(Text.translatable("commands.op.message", level), false);
			}
		}

		if (affected == 0) {
			source.sendError(Text.translatable("commands.op.failed"));
			return 0;
		}

		final int finalAffected = affected;
		source.sendFeedback(() -> Text.translatable("commands.op.success",
				targets.stream().map(GameProfile::getName)
						.reduce((a, b) -> a + ", " + b).orElse("")), true);
		return finalAffected;
	}
}

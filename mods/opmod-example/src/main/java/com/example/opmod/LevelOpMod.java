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
import net.minecraft.server.players.NameAndId;
import net.minecraft.server.players.PlayerList;
import net.minecraft.server.permissions.LevelBasedPermissionSet;

import java.util.Collection;
import java.util.Optional;

/**
 * Extends /op with an optional explicit permission level:
 *
 *   /op <targets>
 *   /op <targets> <level>
 *
 * The second form grants the target the requested permission level.
 *
 * This implementation targets Minecraft 26.3 Mojang mappings, where
 * operator permissions use LevelBasedPermissionSet rather than the old
 * Optional<Integer> permission-level API.
 */
public final class LevelOpMod implements ModInitializer {

	@Override
	public void onInitialize() {
		CommandRegistrationCallback.EVENT.register(
				(dispatcher, registryAccess, environment) -> {

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
				}
		);
	}

	/**
	 * Only server administrators may use the extended /op command.
	 */
	private static boolean canUseCommand(CommandSourceStack source) {
		return source.permissions().hasPermission(
				LevelBasedPermissionSet.ADMINS
		);
	}

	/**
	 * Converts the old numeric operator level (1-4) to the
	 * corresponding Minecraft 26.3 permission set.
	 */
	private static LevelBasedPermissionSet permissionSetForLevel(int level) {
		return switch (level) {
			case 1 -> LevelBasedPermissionSet.GAMEMASTER;
			case 2 -> LevelBasedPermissionSet.GAMEMASTER;
			case 3 -> LevelBasedPermissionSet.ADMINS;
			case 4 -> LevelBasedPermissionSet.OWNERS;
			default -> throw new IllegalArgumentException(
					"Operator permission level must be between 1 and 4"
			);
		};
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
									: "Unable to resolve target."
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

			ServerPlayer player =
					playerList.getPlayer(target.id());

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

		String targetNames = targets.stream()
				.map(NameAndId::name)
				.reduce(
						(a, b) -> a + ", " + b
				)
				.orElse("");

		source.sendSuccess(
				() -> Component.translatable(
						"commands.op.success",
						targetNames
				),
				true
		);

		return affected;
	}
}

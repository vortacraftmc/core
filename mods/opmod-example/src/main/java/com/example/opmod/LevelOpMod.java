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

import java.util.Collection;
import java.util.Optional;

/**
 * Adds a "level" argument to the vanilla /op command:
 *
 *   /op <targets>          -> vanilla behaviour, unchanged
 *                              (grants op at the server's op-permission-level)
 *   /op <targets> <level>  -> new behaviour added by this mod
 *                              (grants op at the given level, 1-4)
 *
 * IMPORTANT -- read before building, see README "Mappings risk" section:
 * Minecraft 26.3 ships unobfuscated (Mojang's own names are the only names;
 * there is no Yarn layer to remap through), so this file is written directly
 * against Mojang mappings (CommandSourceStack, PlayerList, NameAndId, etc.)
 * rather than Yarn names (ServerCommandSource, PlayerManager, GameProfile)
 * used in older Fabric mods and in this mod's own first draft.
 *
 * Two specific things could NOT be confirmed against a real 26.3 build and
 * need verifying against the actual 26.3 Minecraft jar / javadoc before this
 * compiles cleanly -- see the inline notes at each usage below:
 *   1. Whether CommandSourceStack#hasPermission(int) still exists as-is in
 *      26.3, given Mojang introduced a new PermissionSet/PermissionLevel
 *      system starting at 1.21.11 (the version immediately before 26.x).
 *   2. Whether PlayerList#op(NameAndId, Optional<Integer>, Optional<Boolean>)
 *      -- confirmed present as of 1.21.9-1.21.11 -- is still the right
 *      overload in 26.3, or whether it has itself moved to the
 *      PermissionLevel-based system by then.
 */
public final class LevelOpMod implements ModInitializer {

	@Override
	public void onInitialize() {
		CommandRegistrationCallback.EVENT.register((dispatcher, registryAccess, environment) -> {
			// Extend the existing "op" node with an extra literal path:
			// op <targets> <level: 1..4>
			dispatcher.register(Commands.literal("op")
					// NOTE (see point 1 above): hasPermission(int) is the
					// Mojang-mapped ExecutionCommandSource method that Yarn
					// called hasPermissionLevel(int), confirmed present
					// through 1.21.11. If 26.3 has replaced permission-level
					// checks with a PermissionLevel-based API, this line is
					// the first thing to fix -- likely something like
					// .requires(source -> source.hasPermission(PermissionLevel.ADMINS))
					.requires(source -> source.hasPermission(3))
					.then(Commands.argument("targets", GameProfileArgument.gameProfile())
							.then(Commands.argument("level", IntegerArgumentType.integer(1, 4))
									.executes(LevelOpMod::opWithLevel))));
		});
	}

	private static int opWithLevel(CommandContext<CommandSourceStack> context) {
		Collection<NameAndId> targets;
		try {
			targets = GameProfileArgument.getGameProfiles(context, "targets");
		} catch (CommandSyntaxException e) {
			context.getSource().sendFailure(Component.literal(e.getMessage()));
			return 0;
		}

		int level = IntegerArgumentType.getInteger(context, "level");
		CommandSourceStack source = context.getSource();
		PlayerList playerList = source.getServer().getPlayerList();

		int affected = 0;
		for (NameAndId target : targets) {
			// NOTE (see point 2 above): PlayerList#op(NameAndId,
			// Optional<Integer>, Optional<Boolean>) grants op directly at
			// the given level -- unlike the plain op(NameAndId) overload
			// vanilla /op uses, which always falls back to the server's
			// op-permission-level default. Confirmed present in Mojang
			// mappings through 1.21.11 (the version immediately preceding
			// 26.x); re-verify the overload still takes a plain Integer
			// (rather than a PermissionLevel enum value) in the actual
			// 26.3 PlayerList class before relying on this compiling as-is.
			playerList.op(target, Optional.of(level), Optional.empty());
			affected++;

			ServerPlayer player = playerList.getPlayer(target.id());
			if (player != null) {
				player.sendSystemMessage(Component.translatable("commands.op.message", level));
			}
		}

		if (affected == 0) {
			source.sendFailure(Component.translatable("commands.op.failed"));
			return 0;
		}

		final int finalAffected = affected;
		source.sendSuccess(() -> Component.translatable("commands.op.success",
				targets.stream().map(NameAndId::name)
						.reduce((a, b) -> a + ", " + b).orElse("")), true);
		return finalAffected;
	}
}

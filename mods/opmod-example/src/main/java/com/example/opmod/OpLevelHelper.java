package com.example.opmod;

import com.mojang.authlib.GameProfile;
import net.minecraft.server.OperatorEntry;
import net.minecraft.server.PlayerManager;

import java.lang.reflect.Field;

/**
 * PlayerManager#addToOperators(GameProfile) always grants the level configured
 * by op-permission-level in server.properties; there is no vanilla API to pass
 * a specific level directly. This helper re-inserts the ops list entry with
 * the level the mod's /op <targets> <level> command was actually given.
 *
 * NOTE: OperatorEntry's field/constructor names come from Yarn mappings and
 * can shift between Minecraft versions. If this mod fails to compile against
 * a newer/older 26.x drop, check the OperatorEntry (net.minecraft.server)
 * class for its current constructor signature -- it takes
 * (GameProfile, int permissionLevel, boolean bypassesPlayerLimit).
 */
final class OpLevelHelper {

	private OpLevelHelper() {
	}

	static void setOpLevel(PlayerManager playerManager, GameProfile profile, int level) {
		boolean bypassesPlayerLimit = false;
		OperatorEntry existing = playerManager.getOpList().get(profile);
		if (existing != null) {
			bypassesPlayerLimit = readBypassesPlayerLimit(existing);
		}

		OperatorEntry entry = new OperatorEntry(profile, level, bypassesPlayerLimit);
		playerManager.getOpList().add(entry);
		playerManager.getOpList().save();
	}

	/**
	 * bypassesPlayerLimit has no public getter on OperatorEntry, so it's read
	 * via reflection to preserve whatever value was already on the existing
	 * entry rather than silently resetting it to false.
	 */
	private static boolean readBypassesPlayerLimit(OperatorEntry entry) {
		try {
			Field field = OperatorEntry.class.getDeclaredField("bypassesPlayerLimit");
			field.setAccessible(true);
			return field.getBoolean(entry);
		} catch (ReflectiveOperationException e) {
			return false;
		}
	}
}

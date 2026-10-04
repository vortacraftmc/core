package com.vortacraftmc.datapackfixer;

/**
 * The data pack format the running server expects. Every migration rule is gated on this value so a rule that was
 * introduced in a newer Minecraft version is never applied to a pack that targets an older one (for example the
 * 26.2 {@code slime} -> {@code cube_mob} rename must not touch a 1.21.4 pack, where {@code slime} is the valid id).
 */
public record FixerConfig(int dataPackFormat) {
    public static final int FORMAT_1_21 = 48;
    public static final int FORMAT_1_21_2 = 57;
    public static final int FORMAT_1_21_4 = 61;
    /** From here on pack.mcmeta uses min_format/max_format and pack_format becomes optional. */
    public static final int FORMAT_MIN_MAX = 82;
    /** From here on supported_formats must be an object, never an array. */
    public static final int FORMAT_SUPPORTED_OBJECT = 88;
    public static final int FORMAT_26_2 = 107;

    public static final String PROPERTY = "datapackfixer.format";
    public static final FixerConfig MC_1_21_4 = new FixerConfig(FORMAT_1_21_4);

    public boolean atLeast(int format) {
        return dataPackFormat >= format;
    }

    /** Reads {@code -Ddatapackfixer.format=<int>}; falls back to the build's own target on a missing/invalid value. */
    public static FixerConfig fromSystemProperties(FixerConfig fallback) {
        String raw = System.getProperty(PROPERTY);
        if (raw == null || raw.isBlank()) return fallback;
        try {
            int parsed = Integer.parseInt(raw.strip());
            return parsed > 0 ? new FixerConfig(parsed) : fallback;
        } catch (NumberFormatException exception) {
            return fallback;
        }
    }
}

package com.vortacraftmc.datapackfixer;

import java.util.List;
import java.util.regex.Pattern;

/**
 * Text-level migration rules shared by the scanner (reports) and the engine (repairs) so the two can never drift.
 * Each rule only fires when {@link FixerConfig#atLeast(int)} holds for its introduction format.
 */
final class MigrationRules {
    record Rule(String code, int sinceFormat, Pattern pattern, String replacement, String message, String suggestion) {
        String apply(String source) {
            return pattern.matcher(source).replaceAll(replacement);
        }
    }

    private static final List<Rule> ALL = List.of(
            new Rule("TYPE_SPECIFIC_SLIME", FixerConfig.FORMAT_26_2,
                    Pattern.compile("minecraft:type_specific/slime(?![\\w/.\\-])"),
                    "minecraft:type_specific/cube_mob",
                    "26.2 renamed the slime entity sub-predicate.",
                    "Replace minecraft:type_specific/slime with minecraft:type_specific/cube_mob."),
            // Tolerates any whitespace around ':' and an omitted "minecraft:" namespace.
            new Rule("ALTERNATIVE_RENAMED", FixerConfig.FORMAT_1_21_2,
                    Pattern.compile("(\"condition\"\\s*:\\s*\")(minecraft:)?alternative(\")"),
                    "$1$2any_of$3",
                    "The alternative loot condition was renamed.",
                    "Replace minecraft:alternative with minecraft:any_of."));

    static List<Rule> forConfig(FixerConfig config) {
        return ALL.stream().filter(rule -> config.atLeast(rule.sinceFormat())).toList();
    }

    private MigrationRules() { }
}

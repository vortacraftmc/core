package com.vortacraftmc.datapackfixer;

import java.util.LinkedHashMap;
import java.util.Map;

/** Single source of truth for the 1.21 plural -> singular data directory renames (used by scanner AND engine). */
final class LegacyDirectories {
    static final Map<String, String> RENAMES;

    static {
        Map<String, String> map = new LinkedHashMap<>();
        map.put("advancements", "advancement");
        map.put("functions", "function");
        map.put("item_modifiers", "item_modifier");
        map.put("loot_tables", "loot_table");
        map.put("predicates", "predicate");
        map.put("recipes", "recipe");
        map.put("structures", "structure");
        map.put("tags/blocks", "tags/block");
        map.put("tags/entity_types", "tags/entity_type");
        map.put("tags/fluids", "tags/fluid");
        map.put("tags/functions", "tags/function");
        map.put("tags/game_events", "tags/game_event");
        map.put("tags/items", "tags/item");
        RENAMES = Map.copyOf(map);
    }

    /** Deterministic iteration order for audit output. */
    static Iterable<Map.Entry<String, String>> ordered() {
        return RENAMES.entrySet().stream().sorted(Map.Entry.comparingByKey()).toList();
    }

    private LegacyDirectories() { }
}

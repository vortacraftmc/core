package com.vortacraftmc.datapackfixer;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;
import java.util.Set;

/**
 * Per-command delimiter check for .mcfunction files.
 *
 * <p>The previous implementation scanned the whole file as one character stream: a quote or bracket inside a
 * {@code #} comment, or an apostrophe in a {@code say} message, flipped the state for every following line, and the
 * reported line was always the last one. This version works on logical commands (blank lines and comments skipped,
 * trailing-backslash continuations joined) and reports the line where the command starts.
 *
 * <p>Quotes are only tracked as strings when they are inside {@code [...]}/{@code {...}}; an unterminated quote
 * outside any bracket is not reported (free text such as {@code title @a title don't} is legal). Free-text commands
 * ({@code say}, {@code me}, {@code msg}, ...) are not checked at all.
 */
final class McFunctionLinter {
    record Issue(int line, String message) { }

    private static final int MAX_ISSUES = 20;
    private static final Set<String> FREE_TEXT = Set.of("say", "me", "msg", "tell", "w", "teammsg", "tm");

    static List<Issue> lint(String content) {
        List<Issue> issues = new ArrayList<>();
        String[] lines = content.split("\r?\n", -1);
        int index = 0;
        while (index < lines.length && issues.size() < MAX_ISSUES) {
            int startLine = index + 1;
            String first = lines[index].stripLeading();
            if (first.isEmpty() || first.startsWith("#")) { index++; continue; }
            StringBuilder command = new StringBuilder(first);
            while (command.charAt(command.length() - 1) == '\\' && index + 1 < lines.length) {
                command.setLength(command.length() - 1);
                index++;
                command.append(lines[index].stripLeading());
            }
            index++;
            checkCommand(command.toString(), startLine, issues);
        }
        return issues;
    }

    private static void checkCommand(String raw, int line, List<Issue> issues) {
        String command = raw.startsWith("$") ? raw.substring(1).stripLeading() : raw;
        String effective = command;
        if (command.startsWith("execute")) {
            int run = command.lastIndexOf(" run ");
            if (run >= 0) effective = command.substring(run + 5).stripLeading();
        }
        int space = effective.indexOf(' ');
        String word = space < 0 ? effective : effective.substring(0, space);
        if (FREE_TEXT.contains(word)) return;

        Deque<Character> stack = new ArrayDeque<>();
        char quote = 0;
        boolean quoteInsideBrackets = false;
        boolean escape = false;
        for (int i = 0; i < command.length(); i++) {
            char c = command.charAt(i);
            if (quote != 0) {
                if (escape) escape = false;
                else if (c == '\\') escape = true;
                else if (c == quote) quote = 0;
                continue;
            }
            if (c == '"' || c == '\'') {
                quote = c;
                quoteInsideBrackets = !stack.isEmpty();
            } else if (c == '[' || c == '{') {
                stack.push(c);
            } else if (c == ']' || c == '}') {
                char expected = c == ']' ? '[' : '{';
                if (stack.isEmpty()) {
                    issues.add(new Issue(line, "Unexpected closing '" + c + "'."));
                    return;
                }
                char opened = stack.pop();
                if (opened != expected) {
                    issues.add(new Issue(line, "Mismatched delimiters: '" + opened + "' closed by '" + c + "'."));
                    return;
                }
            }
        }
        if (quote != 0 && quoteInsideBrackets) {
            issues.add(new Issue(line, "Unterminated " + (quote == '"' ? "double" : "single") + " quote inside SNBT/selector."));
        } else if (!stack.isEmpty()) {
            issues.add(new Issue(line, "Unclosed '" + stack.peek() + "'."));
        }
    }

    private McFunctionLinter() { }
}

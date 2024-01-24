const std = @import("std");
const expect = std.testing.expect;

fn strchr(s: []const u8, ch: u8) !usize {
    for (s, 0..) |c, i| {
        if (c == ch) {
            return i;
        }
    }
    return error.NotFound;
}

pub fn getLine(s: []const u8, line: usize) ![]const u8 {
    var cur = s[0..];
    var next = strchr(cur, '\n') catch s.len;
    for (0..s.len) |i| {
        if (i == line) {
            return cur[0..next];
        }
        cur = cur[next..];
        next = strchr(cur, '\n') catch break;
    }
    return error.TooFewLines;
}

pub fn numLines(s: []const u8) usize {
    var cur = s;
    var ret: usize = 1;
    var prev: usize = 0;
    for (0..s.len) |_| {
        cur = cur[prev..];
        prev = strchr(cur, '\n') catch break;
        prev += 1; // jump over it
        ret += 1;
    }
    return ret;
}

test "multiline" {
    const s = "abc\nd\nf";
    std.debug.print("{}\n", .{numLines(s)});
    try expect(numLines(s) == 3);
}

test "singleline" {
    const s = "a";
    try expect(numLines(s) == 1);
}
const std = @import("std");
const assert = std.debug.assert;
const string_helper = @import("string_helper.zig");
const expect = std.testing.expect;

pub const ParseError = error{
    FoundWrongToken,
    GotEarlyEndOfEOF,
};

pub const Lexer = struct {
    buffname: []const u8, // filename or whatever we're using
    source: []const u8, // code
    i: usize,
    linenum: usize,
    last_line_start: usize,
    cur: TokenWContext,
    peek: ?TokenWContext,

    // move over token
    pub fn next(l: *Lexer) void {
        if (l.peek) |t| {
            l.cur = t;
            l.peek = null;
        } else {
            l.cur = l.scan();
        }
    }

    pub fn lex_error(l: *Lexer, err: ParseError, line: usize, tok: TokenWContext, expected: Token) void {
        switch (err) {
            ParseError.FoundWrongToken => {
                const errnum = @intFromError(err);
                std.debug.print("{s}:{}:{}\n", .{l.buffname, line, tok.startchar});
                std.debug.print("\x1b[35merror[E{s}{}]\x1b[39m From {s} on line {} got \x1b[31m`{s}`\x1b[39m but we expected `{s}`\n", .{ prefix_error(errnum), errnum, l.buffname, line, tok.tok.str(), expected.str() });
                std.debug.print("\n", .{});
                const line_content = string_helper.getLine(l.source, line) catch unreachable;
                std.debug.print("{}|{s}\x1b[31m{s}\x1b[39m{s}\n", .{ line, line_content[0..tok.startchar], line_content[tok.startchar..tok.endchar], line_content[tok.endchar..] });
                std.debug.print("\n", .{});
            },
            ParseError.GotEarlyEndOfEOF => {
                const errnum = @intFromError(err);
                std.debug.print("{s}:{}:{}\n", .{l.buffname, line, tok.startchar});
                std.debug.print("\x1b[35merror[E{s}{}]\x1b[39m From {s} on line {} got to end of file but we expected `{s}`\n", .{ prefix_error(errnum), errnum, l.buffname, line, expected.str() });
                std.debug.print("\n", .{});
            },
        }
    }

    pub fn lookahead(l: *Lexer) void {
        assert(l.peek == null);
        l.peek = l.scan();
    }

    // advances i and returns next token
    fn scan(l: *Lexer) TokenWContext {
        if (l.i >= l.source.len) {
            const ch = l.source.len - l.last_line_start;
            return TokenWContext{.tok = .eof, .line = l.linenum, .startchar = ch, .endchar = ch};
        }

        if (l.source[l.i] == '(') {
            const save_ch = l.i;
            l.i += 1;
            devour_whitespace(l);
            return TokenWContext{.tok = .lparen, .line = l.linenum, .startchar = save_ch, .endchar = save_ch+1};
        } else if (l.source[l.i] == ')') {
            const save_ch = l.i;
            l.i += 1;
            devour_whitespace(l);
            return TokenWContext{.tok = .rparen, .line = l.linenum, .startchar = save_ch, .endchar = save_ch+1};
        } else if (l.source[l.i] == '+') {
            const save_ch = l.i;
            l.i += 1;
            devour_whitespace(l);
            return TokenWContext{.tok = .plus, .line = l.linenum, .startchar = save_ch, .endchar = save_ch+1};
        } else {
            const save_ch = l.i;
            // assume it's a num
            const zero = 0x30;
            const nine = 0x39;
            var val: f64 = 0;
            while ((l.i < l.source.len) and (l.source[l.i] >= zero) and (l.source[l.i] <= nine)) {
                val *= 10.0;
                const digit = l.source[l.i] - zero;
                val += @as(f64, @floatFromInt(digit));
                l.i += 1;
            }
            const save_end = l.i;
            devour_whitespace(l);
            return TokenWContext{.tok = Token{ .num = val }, .line = l.linenum, .startchar = save_ch, .endchar = save_end};
        }
    }

    pub fn consume(l: *Lexer, texpected: Token) !void {
        if (!tokenEqual(l.cur.tok, texpected)) {
            const err = ParseError.FoundWrongToken;
            l.lex_error(err, l.linenum, l.cur, texpected);
            return err;
        } else {
            l.next();
        }
    }

    pub fn debug(l: Lexer) void {
        std.debug.print("================\n", .{});
        std.debug.print("state of lexer:\n", .{});
        std.debug.print("source: \"{s}\"\n", .{l.source});

        std.debug.print("         ", .{});
        for (0..l.source.len) |i| {
            std.debug.print("{}", .{i % 10});
        }
        std.debug.print("\n", .{});

        std.debug.print("i: {}\n", .{l.i});
        std.debug.print("peek: {?}\n", .{l.peek});
        std.debug.print("cur: {}\n", .{l.cur});
        std.debug.print("linenum: {}\n", .{l.linenum});
        std.debug.print("================\n", .{});
    }
};

// Function to check equality of two Token instances
pub fn tokenEqual(a: Token, b: Token) bool {
    return switch (a) {
        TokenType.rparen => switch (b) {
            TokenType.rparen => true,
            else => false,
        },
        TokenType.lparen => switch (b) {
            TokenType.lparen => true,
            else => false,
        },
        TokenType.plus => switch (b) {
            TokenType.plus => true,
            else => false,
        },
        TokenType.num => switch (b) {
            TokenType.num => a.num == b.num,
            else => false,
        },
        TokenType.eof => switch (b) {
            TokenType.eof => true,
            else => false,
        },
    };
}

const TokenType = enum {
    eof,
    rparen,
    lparen,
    plus,
    num,
};

pub const TokenWContext = struct {
    line: usize,
    startchar: usize,
    endchar: usize,
    tok: Token,
};

pub const Token = union(TokenType) {
    eof: void,
    rparen: void,
    lparen: void,
    plus: void,
    num: f64,

    fn str(t: Token) []const u8 {
        return switch (t) {
            TokenType.rparen => ")",
            TokenType.lparen => "(",
            TokenType.plus => "+",
            TokenType.num => "<literal number>",
            TokenType.eof => "<end of file>",
        };
    }
};

fn devour_whitespace(t: *Lexer) void {
    while (t.i < t.source.len) {
        var ch = t.source[t.i];
        if (ch == ' ') {
            t.i += 1;
        } else if (ch == '\n') {
            t.linenum += 1;
            t.i += 1;
            t.last_line_start = t.i;
        } else if (ch == '\r') {
            t.i += 1;
        } else {
            break;
        }
    }
}

pub fn new_tokenizer(s: []const u8) Lexer {
    var tok = Lexer{
        .buffname = "<stdin>",
        .cur = TokenWContext{ .line = 0, .startchar = 0, .endchar = 0, .tok = .eof },
        .peek = null,
        .i = 0,
        .source = s,
        .linenum = 0,
        .last_line_start = 0,
    };
    devour_whitespace(&tok);
    return tok;
}

fn prefix_error(n: usize) []const u8 {
    var offset: usize = 0;
    var div: usize = 10;
    for (0..3) |_| {
        if ((n / div) == 0) {
            offset += 1;
        }
        div *= 10;
    }
    return "0000"[0..offset];
}

test "prefix" {
    try expect(std.mem.eql(u8, prefix_error(9), "000"));
    try expect(std.mem.eql(u8, prefix_error(0), "000"));
    try expect(std.mem.eql(u8, prefix_error(10), "00"));
    try expect(std.mem.eql(u8, prefix_error(11), "00"));
    try expect(std.mem.eql(u8, prefix_error(119), "0"));
}
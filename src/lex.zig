const std = @import("std");
const assert = std.debug.assert;

const ParseError = error{
    FoundWrongToken,
    GotEarlyEndOfText,
};

pub const Lexer = struct {
    source: []const u8,
    i: usize,
    linenum: usize,
    cur: Token,
    peek: ?Token,

    // move over token
    pub fn next(l: *Lexer) void {
        if (l.peek) |t| {
            l.cur = t;
            l.peek = null;
        } else {
            l.cur = l.scan();
        }
    }

    pub fn lookahead(l: *Lexer) void {
        assert(l.peek == null);
        l.peek = l.scan();
    }

    // advances i and returns next token
    fn scan(l: *Lexer) Token {
        if (l.i >= l.source.len) {
            return .eof;
        }

        if (l.source[l.i] == '(') {
            l.i += 1;
            devour_whitespace(l);
            return .lparen;
        } else if (l.source[l.i] == ')') {
            l.i += 1;
            devour_whitespace(l);
            return .rparen;
        } else if (l.source[l.i] == '+') {
            l.i += 1;
            devour_whitespace(l);
            return .plus;
        } else {
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
            devour_whitespace(l);
            return Token{ .num = val };
        }
    }

    pub fn consume(l: *Lexer, texpected: Token) !void {
        if (!tokenEqual(l.cur, texpected)) {
            std.log.err("got {}, but I expected {}", .{ l.cur, texpected });
            return ParseError.FoundWrongToken;
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

pub const Token = union(TokenType) {
    eof: void,
    rparen: void,
    lparen: void,
    plus: void,
    num: f64,
};

fn devour_whitespace(t: *Lexer) void {
    while (t.i < t.source.len) {
        var ch = t.source[t.i];
        if (ch == ' ') {
            t.i += 1;
        } else if (ch == '\n') {
            t.linenum += 1;
            t.i += 1;
        } else if (ch == '\r') {
            t.i += 1;
        } else {
            break;
        }
    }
}

pub fn new_tokenizer(s: []const u8) Lexer {
    var tok = Lexer{
        .cur = .eof,
        .peek = null,
        .i = 0,
        .source = s,
        .linenum = 0,
    };
    devour_whitespace(&tok);
    return tok;
}

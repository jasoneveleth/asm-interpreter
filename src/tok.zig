pub const Tokenizer = struct {
    source: []const u8,
    index: usize,

    pub fn next(t: *Tokenizer) ?Token {
        if (t.index < t.source.len) {
            return t.next_unchecked();
        } else {
            return null;
        }
    }

    fn next_unchecked(t: *Tokenizer) Token {
        var i = t.index;
        if (t.source[i] == '(') {
            t.index = i + 1;
            devour_whitespace(t);
            return .lparen;
        } else if (t.source[i] == ')') {
            t.index = i + 1;
            devour_whitespace(t);
            return .rparen;
        } else if (t.source[i] == '+') {
            t.index = i + 1;
            devour_whitespace(t);
            return .plus;
        } else {
            // assume it's a num
            const zero = 0x30;
            const nine = 0x39;
            var val: f64 = 0;
            while ((t.index < t.source.len) and (t.source[t.index] >= zero) and (t.source[t.index] <= nine)) {
                val *= 10.0;
                const digit = t.source[t.index] - zero;
                val += @as(f64, @floatFromInt(digit));
                t.index = t.index + 1;
            }
            devour_whitespace(t);
            return Token{ .num = val };
        }
    }
};

const TokenType = enum {
    rparen,
    lparen,
    plus,
    num,
};

pub const Token = union(TokenType) {
    rparen: void,
    lparen: void,
    plus: void,
    num: f64,
};

fn devour_whitespace(t: *Tokenizer) void {
    while (t.index < t.source.len) {
        var i = t.index;
        var ch = t.source[i];
        if (ch == ' ') {
            t.index += 1;
        } else if (ch == '\n') {
            t.index += 1;
        } else if (ch == '\r') {
            t.index += 1;
        } else {
            break;
        }
    }
}

pub fn new_tokenizer(s: []const u8) Tokenizer {
    var tok = Tokenizer{ .index = 0, .source = s };
    devour_whitespace(&tok);
    return tok;
}

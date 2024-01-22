const lex = @import("lex.zig");

const CompileError = error{
    FoundEOFEarly,
};

// interpreter value
pub const Value = f64;

// byte code
// 1 byte fields
// | C | B | A | op |
// |   D   | A | op |
// MSB             LSB
pub const ByteCode = union {
    bits: u32,
    ad: packed struct {
        op: u8,
        a: u8,
        d: u16,
    },
    abc: packed struct {
        op: u8,
        a: u8,
        c: u8,
        b: u8,
    },
};

pub fn compile_expr(l: *lex.Lexer, bytecode: []ByteCode, constants: []Value) !void {
    l.next();
    const token = l.cur;

    const fslot = 2;
    const cslot = 1;

    switch (token) {
        .eof => return CompileError.FoundEOFEarly,
        .rparen => return CompileError.FoundEOFEarly,
        .lparen => return CompileError.FoundEOFEarly,
        .plus => return CompileError.FoundEOFEarly,
        .num => |val| constants[cslot] = val,
    }

    var load = ByteCode{ .ad = .{ .d = cslot, .a = fslot, .op = 1 } };
    var halt = ByteCode{ .ad = .{ .d = 0xdddd, .a = fslot, .op = 0 } };

    // const load_2f_to_0 = 0x00010001;
    // const load_5f_to_1 = 0x00020101;
    // const add_0_1_to_2 = 0x00010202;
    // const halt         = 0xdddd0200;
    // const bytecode = [_]u32{ load_2f_to_0, load_5f_to_1, add_0_1_to_2, halt };

    bytecode[0] = load;
    bytecode[1] = halt;
}

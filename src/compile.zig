const lex = @import("lex.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;

const CompileError = error{
    FoundEOFEarly,
};

// interpreter value, if this is quiet NaN it's a wrapped value
pub const Value = f64;

pub const OpCode = enum(u8) {
    halt,
    kdouble,
    add,
};

// byte code
// 1 byte fields
// | C | B | A | op |
// |   D   | A | op |
// MSB             LSB
pub const ByteCode = u32;

// constructor for ByteCode
inline fn ad(op: OpCode, a: u8, d: u16) ByteCode {
    return (@as(u32, d) << 16) | (@as(u32, a) << 8) | @intFromEnum(op);
}

// constructor for ByteCode
inline fn abc(op: OpCode, a: u8, b: u8, c: u8) ByteCode {
    return (@as(u32, c) << 24) | (@as(u32, b) << 16) | (@as(u32, a) << 8) | @intFromEnum(op);
}

const Compiler = struct {
    bc: []ByteCode, // bytecode
    ks: []Value, // constants array
    freereg: usize, // lowest free register
    frame: []Value, // call frame (ie array of args and registers)
};

fn compile_expr(c: *Compiler, l: *lex.Lexer) !void {
    l.next();
    const token = l.cur;

    const fslot = 2;
    const cslot = 1;

    switch (token) {
        .eof => return CompileError.FoundEOFEarly,
        .rparen => return CompileError.FoundEOFEarly,
        .lparen => return CompileError.FoundEOFEarly,
        .plus => return CompileError.FoundEOFEarly,
        .num => |val| c.ks[cslot] = val,
    }

    var load = ad(.kdouble, fslot, cslot);
    var halt = ad(.halt, fslot, 0xdddd);

    // const load_2f_to_0 = 0x00010001;
    // const load_5f_to_1 = 0x00020101;
    // const add_0_1_to_2 = 0x00010202;
    // const halt         = 0xdddd0200;
    // const bytecode = [_]u32{ load_2f_to_0, load_5f_to_1, add_0_1_to_2, halt };

    c.bc[0] = load;
    c.bc[1] = halt;
    debug(c.*);
}

pub fn new_compiler(allocator: Allocator) !Compiler {
    var bytecode = try allocator.alloc(ByteCode, 4);
    var constants = try allocator.alloc(Value, 5);
    var call_frame = try allocator.alloc(Value, 4);

    return Compiler{
        .bc = bytecode,
        .ks = constants,
        .freereg = 0,
        .frame = call_frame,
    };
}

pub fn compile(l: *lex.Lexer, c: *Compiler) !void {
    try compile_expr(c, l);
}

// takes a u32 and returns string of leading 0s
fn prefix(n: u32) []const u8 {
    var offset: usize = 0;
    var shf: u5 = 0;
    for (0..8) |_| {
        if ((n >> (shf * 4)) == 0) {
            offset += 1;
        }
        shf += 1;
    }
    return "00000000"[0..offset];
}

pub fn debug(com: Compiler) void {
    std.debug.print("bytecode:\n", .{});
    for (com.bc) |bytecode| {
        const op = bytecode & 0xFF;
        const a = (bytecode >> 8) & 0xFF;

        const d = bytecode >> 16;
        const b = (bytecode >> 16) & 0xFF;
        const c = (bytecode >> 24) & 0xFF;
        if (op == @intFromEnum(OpCode.halt)) {
            std.debug.print("0x{s}{x} halt {}\n", .{ prefix(bytecode), bytecode, a });
        } else if (op == @intFromEnum(OpCode.kdouble)) {
            std.debug.print("0x{s}{x} load {} <- {}\n", .{ prefix(bytecode), bytecode, a, d });
        } else if (op == @intFromEnum(OpCode.add)) {
            std.debug.print("0x{s}{x} add {} {} {}\n", .{ prefix(bytecode), bytecode, a, b, c });
        } else {
            std.debug.print("  und\n", .{});
        }
    }

    std.debug.print("constants:\n", .{});
    for (com.ks, 0..) |constant, i| {
        std.debug.print("  {} -> {}\n", .{ i, constant });
    }
}

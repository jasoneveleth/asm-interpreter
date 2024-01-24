const lex = @import("lex.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const CompileError = error{
    FoundEOFEarly,
    NotEnoughSpace,
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
inline fn new_ad(op: OpCode, a: u8, d: u16) ByteCode {
    return (@as(u32, d) << 16) | (@as(u32, a) << 8) | @intFromEnum(op);
}

// constructor for ByteCode
inline fn new_abc(op: OpCode, a: u8, b: u8, c: u8) ByteCode {
    return (@as(u32, c) << 24) | (@as(u32, b) << 16) | (@as(u32, a) << 8) | @intFromEnum(op);
}

const Compiler = struct {
    bc: []ByteCode, // bytecode
    bci: usize, // next free bytecode slot

    ks: []Value, // constants array
    numconsts: u16, // number of constants

    frame: []Value, // call frame (ie array of args and registers)
    freeregs: []u1, // bits array

    fn push_const(c: *Compiler, v: Value) u16 {
        const n = c.numconsts;
        c.ks[n] = v;
        c.numconsts += 1;
        return n;
    }

    fn next_free_reg(c: Compiler) u8 {
        for (0..c.freeregs.len) |i| {
            if (c.freeregs[i] == 1) {
                c.freeregs[i] = 0;
                const ret: u8 = @truncate(i);
                assert(@as(usize, ret) == i);
                return ret;
            }
        }
        unreachable;
    }

    fn free_reg(c: Compiler, i: usize) void {
        c.freeregs[i] = 1;
    }

    fn push_ins(c: *Compiler, b: ByteCode) !void {
        if (c.bci == c.bc.len) {
            std.log.err("overflowed max bytecode length: {}", .{c.bc.len});
            return CompileError.NotEnoughSpace;
        }

        const n = c.bci;
        c.bc[n] = b;
        c.bci += 1;
    }

    pub fn debug(com: Compiler) void {
        std.debug.print("\x1b[1mbytecode:\x1b[0m\n", .{});
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

        std.debug.print("\n", .{});
        std.debug.print("constants:\n", .{});
        std.debug.print("num constants: {}\n", .{com.numconsts});
        if (@as(usize, com.numconsts) > com.ks.len) {
            std.debug.print("ahh fuck either we're overflowing compiler.ks\n", .{});
        }
        for (com.ks, 0..) |constant, i| {
            std.debug.print("  {} -> {}\n", .{ i, constant });
        }
    }
};

// tells you which register it went into
fn compile_expr(c: *Compiler, l: *lex.Lexer) !u8 {
    const token = l.cur;
    switch (token) {
        .eof => return CompileError.FoundEOFEarly,
        .lparen => {
            l.next();
            try l.consume(.plus);
            const r1 = try compile_expr(c, l);
            const r2 = try compile_expr(c, l);
            try l.consume(.rparen);
            try c.push_ins(new_abc(.add, r1, r2, r1));
            c.free_reg(r2);
            return r1;
        },
        .rparen => return CompileError.FoundEOFEarly,
        .plus => return CompileError.FoundEOFEarly,
        .num => |val| {
            l.next();
            const fr = c.next_free_reg();
            try c.push_ins(new_ad(.kdouble, fr, c.push_const(val)));
            return fr;
        },
    }
}

pub fn new_compiler(allocator: Allocator) !Compiler {
    var bytecode = try allocator.alloc(ByteCode, 10);
    var constants = try allocator.alloc(Value, 5);

    const nfr = 256;
    assert(nfr <= 256);
    var call_frame = try allocator.alloc(Value, nfr);
    var freeregs = try allocator.alloc(u1, nfr);
    @memset(freeregs, 1);

    return Compiler{
        .bc = bytecode,
        .bci = 0,
        .ks = constants,
        .numconsts = 0,
        .frame = call_frame,
        .freeregs = freeregs,
    };
}

pub fn compile(l: *lex.Lexer, c: *Compiler) !void {
    l.next();
    const reg = try compile_expr(c, l);
    try c.push_ins(new_ad(.halt, reg, 0xdddd));
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

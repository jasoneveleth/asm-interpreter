const std = @import("std");
const lex = @import("lex.zig");
const compile = @import("compile.zig");

const ArgsError = error{
    NotEnough,
};

extern fn startvm(*u32, *f64, *f64) compile.Value;

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();
    var source = args.next() orelse return ArgsError.NotEnough;

    var l = lex.new_tokenizer(source[0..source.len]);

    const alloc = std.heap.page_allocator;
    var c = try compile.new_compiler(alloc);

    try compile.compile(&l, &c);

    const val = startvm(@ptrCast(c.bc), @ptrCast(c.ks), @ptrCast(c.frame));
    std.debug.print("Return from asm is {}\n", .{val});

    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();
    // try stdout.print("Run `zig build test` to run the tests.\n", .{});
    // try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

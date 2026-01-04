const std = @import("std");
const array = @import("dynamic_array.zig");

test "Dynamic Array Grow and Shrink" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const darray = try array.DynamicArray(i32).init(allocator);
    defer darray.deinit();

    darray.print(&std.debug);
    for (0..10) |_| {
        try darray.grow();
        darray.print(&std.debug);
    }

    for (0..10) |_| {
        try darray.shrink();
        darray.print(&std.debug);
    }
}

test "Dynamic Array Locate" {
    const IntArray = array.DynamicArray(i32);
    const test_data = [_]struct { usize, struct { usize, usize } }{
        .{ 0, .{ 0, 0 } },
        .{ 1, .{ 1, 0 } },
        .{ 2, .{ 1, 1 } },
        .{ 3, .{ 2, 0 } },
        .{ 4, .{ 2, 1 } },
        .{ 5, .{ 3, 0 } },
        .{ 6, .{ 3, 1 } },
        .{ 7, .{ 4, 0 } },
        .{ 8, .{ 4, 1 } },
        .{ 9, .{ 4, 2 } },
        .{ 10, .{ 4, 3 } },
        .{ 11, .{ 5, 0 } },
        .{ 12, .{ 5, 1 } },
        .{ 13, .{ 5, 2 } },
        .{ 14, .{ 5, 3 } },
        .{ 15, .{ 6, 0 } },
        .{ 16, .{ 6, 1 } },
        .{ 17, .{ 6, 2 } },
        .{ 18, .{ 6, 3 } },
        .{ 35, .{ 10, 4 } },
        .{ 70, .{ 14, 7 } },
    };

    for (test_data) |data| {
        const i, const xlocation = data;
        const idx, const offset = IntArray.locate(i);
        const xidx, const xoffest = xlocation;

        std.debug.print("[i: {d}, expected_index: {d}, expected_element: {d}, calculated_index: {d}, calculated_element: {d}]\n", .{
            i,
            xidx,
            xoffest,
            idx,
            offset,
        });
        try std.testing.expect(xidx == idx and xoffest == offset);
    }
}

test "Dynamic Array Set and Get" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const darray = try array.DynamicArray(i32).init(allocator);
    defer darray.deinit();

    const array_size = 1000;

    for (0..array_size) |_| {
        try darray.grow();
    }

    // set
    for (0..array_size) |i| {
        try darray.set(i, @intCast(i + 10));
    }

    // get
    for (0..array_size) |i| {
        const v = try darray.get(i);
        const xv = i + 10;
        std.debug.print("array[{d}] = {d}, expected: {d}\n", .{
            i,
            v,
            xv,
        });
        try std.testing.expect(v == xv);
    }

    darray.print(&std.debug);

    for (0..array_size) |_| {
        try darray.shrink();
    }
}

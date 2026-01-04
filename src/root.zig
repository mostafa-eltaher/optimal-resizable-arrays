//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const array = @import("arrays/dynamic_array.zig");

const array_test = @import("arrays/dynamic_array_test.zig");

test {
    @import("std").testing.refAllDecls(array_test);
}

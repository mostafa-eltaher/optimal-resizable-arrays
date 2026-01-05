// Singly Resizable Array
// A. Brodnik, S. Carlsson, E. D. Demaine, J. I. Munro, and R. Sedgewick,
// “Resizable arrays in optimal time and space,”
// Tech. Rep. CS-99-09, School of Computer Science,
// University of Waterloo, Waterloo, ON, Canada, 1999. [Online].
// Available: https://cs.uwaterloo.ca/research/tr/1999/09/CS-99-09.pdf

const std = @import("std");

pub fn DynamicArray(comptime T: type) type {
    return struct {
        const Self = @This();
        allocator: std.mem.Allocator,
        index: [][]T, // fat pointer (slice) to an array of fat pointers of T
        n: usize = 0, // the number of elements
        s: usize = 0, // the number of superblocks
        d: usize = 0, // the number of data blocks
        s_block_max_count: usize = 0, // the maximum number of data blocks that can be in the s-1 superblock
        s_block_capacity: usize = 0, // the size of each data block in the s-1 superblock
        s_block_occupancy: usize = 0, // the number of the data blocks that already allocated in the s-1 superblock
        d_block_occupancy: usize = 0, // the number of elements in the last d-1 data block

        pub fn init(allocator: std.mem.Allocator) !*Self {
            const index = try allocator.alloc([]T, 16);
            const this = try allocator.create(Self);
            this.* = Self{
                .allocator = allocator,
                .index = index,
                .s = 1,
                .s_block_max_count = 1,
                .s_block_capacity = 1,
            };

            return this;
        }

        pub fn deinit(self: *Self) void {
            for (self.index[0..self.d]) |data_block| {
                self.allocator.free(data_block);
            }
            self.allocator.free(self.index);
            self.allocator.destroy(self);
        }

        pub fn get(self: *Self, i: usize) error{IndexOutOfBounds}!T {
            if (self.n <= i) return error.IndexOutOfBounds;
            const d, const e = locate(i);
            return self.index[d][e];
        }

        pub fn set(self: *Self, i: usize, v: T) error{IndexOutOfBounds}!void {
            if (self.n <= i) return error.IndexOutOfBounds;
            const d, const e = locate(i);
            self.index[d][e] = v;
        }

        pub fn grow(self: *Self) !void {
            const isLastDataBlockFull = self.d == 0 or self.index[self.d - 1].len == self.d_block_occupancy;
            const isLastSuperblockFull = self.s_block_max_count == self.s_block_occupancy;
            const isIndexBlockFull = self.d == self.index.len;
            if (isLastDataBlockFull) {
                if (isLastSuperblockFull) {
                    self.s += 1;
                    // if s-1 is odd (i.e. s is even), double the size of the data block, otherwise double the count of the data blocks
                    if (self.s & 1 == 0) self.s_block_capacity <<= 1 else self.s_block_max_count <<= 1;
                    self.s_block_occupancy = 0; // will be incremented to 1 below.
                }
                if (isIndexBlockFull) {
                    try self.resizeIndex(true);
                }
                // create new data block and set the counters accordingly.
                const new_data_block = try self.allocator.alloc(T, self.s_block_capacity);
                self.index[self.d] = new_data_block;
                self.d += 1;
                self.d_block_occupancy = 0; // will be incremented to 1 below.
                self.s_block_occupancy += 1;
            }
            self.n += 1;
            self.d_block_occupancy += 1;
        }

        pub fn shrink(self: *Self) !void {
            if (self.n == 0) return;
            self.n -= 1;
            self.d_block_occupancy -= 1;

            const isLastDataBlockEmpty = self.d_block_occupancy == 0;
            if (isLastDataBlockEmpty) {
                //free the last data block and set the counters accordingly
                self.allocator.free(self.index[self.d - 1]);
                self.d -= 1;
                self.d_block_occupancy = if (self.d >= 1) self.index[self.d - 1].len else 0;
                self.s_block_occupancy -= 1;

                const isLastSuperblockEmpty = self.s_block_occupancy == 0;
                if (isLastSuperblockEmpty and self.s > 1) {
                    self.s -= 1;
                    // if s-1 is odd (i.e. s is even), half the number of the data blocks, otherwise half the size of the data blocks
                    if (self.s & 1 == 0) self.s_block_max_count >>= 1 else self.s_block_capacity >>= 1;
                    self.s_block_occupancy = self.s_block_max_count;
                }

                const isIndexBlockQuaterFull = self.d <= (self.index.len >> 2);
                if (isIndexBlockQuaterFull) {
                    try self.resizeIndex(false);
                }
            }
        }

        // returns: {index, offset}
        //   index: is the index of the data block in the index block.
        //   offset: is the offset within the data block
        // use:
        //   const idx, const offset = self.locate(i);
        // Note: There is a mistake in the paper on how to calculate this, in the particular the p value.
        pub fn locate(i: usize) struct { usize, usize } {
            if (i == 0) return .{ 0, 0 };
            const usize1: usize = 1; // for zig compiler: 1 in usize to be used as LHS of shift and have the output in usize

            const r = i + 1;
            const r_bit_size: u6 = @intCast(@bitSizeOf(usize) - @clz(r));
            const r_after_msb: usize = r ^ (usize1 << (r_bit_size - 1)); // flip the leading 1-bit to 0

            const k = r_bit_size - 1; // k is the index of super block
            const khf = k >> 1; // convenience: floor(k/2)
            const khc = (k + 1) >> 1; // convenience: ciel(k/2)
            const two_power_khf = (usize1 << khf); //convenience: 2^(floor(k/2))

            const b = r_after_msb >> khc; // the first floor(k/2) bits of r after the leading 1-bit
            const e_mask = (usize1 << khc) - 1; // the last ciel(k/2) bits, of r after the leading 1-bit, set to 1
            const e = r_after_msb & e_mask; // the last ciel(k/2) bits of r after the leading 1-bit

            // This was mistakenly caculated in the paper as p = (2^k) -1
            // the correct formula should be p = 2(2^(floor(k/2)) - 1) +  (k mod 2)2^(floor(k/2))
            const p = ((two_power_khf - 1) << 1) + (k & 1) * two_power_khf;
            return .{ p + b, e };
        }

        //TODO: consider using enum insead of boolean
        fn resizeIndex(self: *Self, up: bool) !void {
            // if up is true, double the size, otherwise, half the size
            const new_index_size = if (up) self.index.len << 1 else self.index.len >> 1;
            const new_index = try self.allocator.alloc([]T, new_index_size);
            for (0..self.d) |i| {
                new_index[i] = self.index[i];
            }
            self.allocator.free(self.index);
            self.index = new_index;
        }

        pub fn print(self: *Self, writer: anytype) void {
            writer.print("[n: {d}, s: {d}, d: {d}, index.len: {d}, s_block_max_count: {d},s_block_capacity: {d},s_block_occupancy: {d},d_block_occupancy: {d}]\n", .{
                self.n,
                self.s,
                self.d,
                self.index.len,
                self.s_block_max_count,
                self.s_block_capacity,
                self.s_block_occupancy,
                self.d_block_occupancy,
            });
        }
    };
}

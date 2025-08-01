//! This library provides implementations for finding the Longest Common Subsequence (LCS)
//! and the Longest Increasing Subsequence (LIS) of slices.
//!
//! It is structured into modules for each algorithm, with this root file
//! exporting the primary functions for easy access.

const std = @import("std");
const lis = @import("lis.zig");
const lcs = @import("lcs.zig");

/// See `lcs.zig` for documentation.
pub const longestCommonSubsequence = lcs.longestCommonSubsequence;
pub const LongestCommonSubsequenceError = lcs.LongestCommonSubsequenceError;

/// See `lis.zig` for documentation.
pub const longestIncreasingSubsequence = lis.longestIncreasingSubsequence;
pub const LongestIncreasingSubsequenceError = lis.LongestIncreasingSubsequenceError;

test {
    std.testing.refAllDecls(lis);
    std.testing.refAllDecls(lcs);
}

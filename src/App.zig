const std = @import("std");
const glfw = @import("zglfw");
const zgpu = @import("zgpu");
const wgpu = zgpu.wgpu;

const App = @This();

const render = @import("render.zig");

/// App state
allocator: std.mem.Allocator,

window: *glfw.Window,
gctx: *zgpu.GraphicsContext,

depth_tex: zgpu.TextureHandle,
depth_texv: zgpu.TextureViewHandle,

pub fn init(allocator: std.mem.Allocator, window: *glfw.Window) !*App {
    //
    // Create app data
    //
    const gctx = try zgpu.GraphicsContext.create(
        allocator,
        .{
            .window = window,
            .fn_getTime = @ptrCast(&glfw.getTime),
            .fn_getFramebufferSize = @ptrCast(&glfw.Window.getFramebufferSize),
            .fn_getWin32Window = @ptrCast(&glfw.getWin32Window),
            .fn_getX11Display = @ptrCast(&glfw.getX11Display),
            .fn_getX11Window = @ptrCast(&glfw.getX11Window),
            .fn_getWaylandDisplay = @ptrCast(&glfw.getWaylandDisplay),
            .fn_getWaylandSurface = @ptrCast(&glfw.getWaylandWindow),
            .fn_getCocoaWindow = @ptrCast(&glfw.getCocoaWindow),
        },
        .{},
    );
    errdefer gctx.destroy(allocator);

    //
    // Create textures.
    //
    const depth = render.texture.createDepthTexture(gctx);

    //
    // Create app state
    //
    const state = try allocator.create(App);
    state.* = .{ .allocator = allocator, .window = window, .gctx = gctx, .depth_tex = depth.tex, .depth_texv = depth.texv };

    return state;
}

pub fn deinit(state: *App, allocator: std.mem.Allocator) void {
    state.gctx.destroy(allocator);
    allocator.destroy(state);
}

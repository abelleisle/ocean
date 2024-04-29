const std = @import("std");
const glfw = @import("zglfw");
const zgui = @import("zgui");
const zopengl = @import("zopengl");
const zgpu = @import("zgpu");
const wgpu = zgpu.wgpu;
const zstbi = @import("zstbi");

const App = @import("App.zig");

const render = @import("render.zig");

const content_dir = @import("build_options").content_dir;
const window_title = "ziggy: glfw [hyprfloat]";

fn update(state: *App) void {
    zgui.backend.newFrame(
        state.gctx.swapchain_descriptor.width,
        state.gctx.swapchain_descriptor.height,
    );

    // Set the starting window position and size to custom values
    zgui.setNextWindowPos(.{ .x = 20.0, .y = 20.0, .cond = .first_use_ever });
    zgui.setNextWindowSize(.{ .w = -1.0, .h = -1.0, .cond = .first_use_ever });

    if (zgui.begin("My window", .{})) {
        if (zgui.button("Press me!", .{ .w = 200.0 })) {
            std.debug.print("Button pressed\n", .{});
        }
    }
    zgui.end();

    if (zgui.begin("Another window", .{})) {
        if (zgui.button("HEMLO", .{ .w = 100.0 })) {
            std.debug.print("NOPE\n", .{});
        }
    }
    zgui.end();
}

fn draw(state: *App) void {
    const gctx = state.gctx;

    // const fb_w = gctx.swapchain_descriptor.width;
    // const fb_h = gctx.swapchain_descriptor.height;

    const back_buffer_view = state.gctx.swapchain.getCurrentTextureView();
    defer back_buffer_view.release();

    const commands = commands: {
        const encoder = state.gctx.device.createCommandEncoder(null);
        defer encoder.release();

        // Gui pass.
        {
            const color_attachments = [_]wgpu.RenderPassColorAttachment{.{
                .view = back_buffer_view,
                .load_op = .load,
                .store_op = .store,
            }};
            const render_pass_info = wgpu.RenderPassDescriptor{
                .color_attachment_count = color_attachments.len,
                .color_attachments = &color_attachments,
            };
            const pass = encoder.beginRenderPass(render_pass_info);
            defer {
                pass.end();
                pass.release();
            }
            zgui.backend.draw(pass);
        }

        break :commands encoder.finish(null);
    };
    defer commands.release();

    state.gctx.submit(&.{commands});

    if (gctx.present() == .swap_chain_resized) {
        // Release old depth texture.
        gctx.releaseResource(state.depth_texv);
        gctx.destroyResource(state.depth_tex);

        // Create a new depth texture to match the new window size.
        const depth = render.texture.createDepthTexture(gctx);
        state.depth_tex = depth.tex;
        state.depth_texv = depth.texv;
    }
}

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    // Change current working directory to where the executable is located.
    {
        var buffer: [1024]u8 = undefined;
        const path = std.fs.selfExeDirPath(buffer[0..]) catch ".";
        std.posix.chdir(path) catch {};
        std.log.info("pwd: {s}", .{path});
    }
    std.log.info("content: {s}", .{content_dir});

    glfw.windowHintTyped(.client_api, .no_api);

    const window = try glfw.Window.create(800, 500, window_title, null);
    defer window.destroy();

    window.setSizeLimits(400, 400, -1, -1);

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_state.deinit();

    const gpa = gpa_state.allocator();

    zstbi.init(gpa);
    defer zstbi.deinit();

    const app = try App.init(gpa, window);
    defer app.deinit(gpa);

    const scale_factor = scale_factor: {
        const scale = window.getContentScale();
        break :scale_factor @max(scale[0], scale[1]);
    };

    zgui.init(gpa);
    defer zgui.deinit();

    _ = zgui.io.addFontFromFile(
        content_dir ++ "Roboto-Medium.ttf",
        std.math.floor(16.0 * scale_factor),
    );

    zgui.backend.init(
        window,
        app.gctx.device,
        @intFromEnum(zgpu.GraphicsContext.swapchain_format),
        @intFromEnum(zgpu.wgpu.TextureFormat.undef),
    );
    defer zgui.backend.deinit();

    zgui.getStyle().scaleAllSizes(scale_factor);

    while (!window.shouldClose() and window.getKey(.escape) != .press) {
        glfw.pollEvents();

        update(app);
        draw(app);
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

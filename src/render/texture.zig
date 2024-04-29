const zgpu = @import("zgpu");
const wgpu = zgpu.wgpu;

/// Create a new depth texture
pub fn createDepthTexture(gctx: *zgpu.GraphicsContext) struct {
    tex: zgpu.TextureHandle,
    texv: zgpu.TextureViewHandle,
} {
    const tex = gctx.createTexture(.{
        .usage = .{ .render_attachment = true },
        .dimension = .tdim_2d,
        .size = .{
            .width = gctx.swapchain_descriptor.width,
            .height = gctx.swapchain_descriptor.height,
            .depth_or_array_layers = 1,
        },
        .format = .depth32_float,
        .mip_level_count = 1,
        .sample_count = 1,
    });
    const texv = gctx.createTextureView(tex, .{});
    return .{ .tex = tex, .texv = texv };
}

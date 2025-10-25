//up练习shader的作品,一个shader描边
uniform vec4 outline_color;
uniform float outline_width;

vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords ){
    vec2 uv = texture_coords;
    vec2 PIXEL_SIZE = 1.0 / love_PixelCoord;
    
    vec2 uv_up = uv + vec2(0, PIXEL_SIZE.y) * outline_width;
    vec2 uv_down = uv + vec2(0, -PIXEL_SIZE.y) * outline_width;
    vec2 uv_left = uv + vec2(PIXEL_SIZE.x, 0) * outline_width;
    vec2 uv_right = uv + vec2(-PIXEL_SIZE.x, 0) * outline_width;
    
    vec4 color_up = Texel(tex, uv_up);
    vec4 color_down = Texel(tex, uv_down);
    vec4 color_left = Texel(tex, uv_left);
    vec4 color_right = Texel(tex, uv_right);
    
    vec4 outline = color_up + color_down + color_left + color_right;
    outline.rgb = outline_color.rgb;
    outline.a = min(outline.a, 1.0);
    
    vec4 original_color = Texel(tex, texture_coords);
    
    return mix(outline, original_color, original_color.a);
}
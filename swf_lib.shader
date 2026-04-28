//this is meant to be included in shaders to shrink up how much copy-pasted code is needed for shaders that add effects to the default swf rendering techniques
#include "std_in.shader"
uniform sampler2D gradient_atlas;
uniform sampler2DArray bitmap_atlas;
uniform samplerBuffer bitmap_atlas_info;
uniform float mip_max;
const float depth_bias_scale = .001;

struct vertex {
    vec4 color;
    vec4 texcoord;
    
    mat2x4 color_xform;
    float depth_bias;
};

#if COMPILING_VERTEX_PROGRAM
    out vertex v;
    
    void defaultvertfunc() {
        v.color = color;
        v.texcoord = texcoord;
        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);
        
        v.color_xform = color_xform;
        v.depth_bias = depth_bias;

        if(v.texcoord.z >= 0 && abs(v.texcoord.w) > .5){
            int index_base = int(v.texcoord.z) * 5;
            v.color.r = texelFetch(bitmap_atlas_info, index_base + 0).r;
            v.color.g = texelFetch(bitmap_atlas_info, index_base + 1).r;
            v.color.b = texelFetch(bitmap_atlas_info, index_base + 2).r;
            v.color.a = texelFetch(bitmap_atlas_info, index_base + 3).r;
            v.texcoord.z = texelFetch(bitmap_atlas_info, index_base + 4).r;
        }
    }

#elif COMPILING_FRAGMENT_PROGRAM
    in vertex v;
    out vec4 frag_color;
    
    float mip_level(in vec2 texcoord, in vec2 texsize) {
        //vec2 ddx = dFdx(texcoord*texsize);
        //vec2 ddy = dFdy(texcoord*texsize);
        //float miplevel = 0.5 * log2(max(dot(ddx, ddx), dot(ddy, ddy))) - 0.5; //-.5 is the mipmap bias
        //return clamp(miplevel, 0, mip_max);
	return 0.0; //risky
    }

    vec2 clamp_to_nearest(in vec2 texcoord, in vec2 texsize, in vec2 orig_texcoord) {
        vec2 uv_texspace = texcoord*texsize;
        vec2 seam = floor(uv_texspace+.5);
        uv_texspace = (uv_texspace-seam)/fwidth(orig_texcoord*texsize)+seam;
        uv_texspace = clamp(uv_texspace, seam-.5, seam+.5);
        return uv_texspace/texsize;
    }
    
    vec4 compute_color_full(in vertex v){
        vec2 coord;
        vec2 bitcoord = vec2(0.0,0.0);
        float bitmap_fill_toggle = 0;
        float bitmap_miplevel = 0.0;
        if(v.texcoord.z >= 0){ //linear gradient
            coord = vec2((v.texcoord.x + 1.0) / 2.0, (v.texcoord.z * 2.0 + 1.0) / textureSize(gradient_atlas, 0).y);

            if(v.texcoord.w > .5){ //repeating
                vec2 texsize = textureSize(bitmap_atlas, 0).xy;
                bitmap_miplevel = mip_level(mix(v.color.xy, v.color.zw, v.texcoord.xy), texsize);

                bitmap_fill_toggle = 1;
                bitcoord = mod(v.texcoord.xy, 1.0);
                bitcoord = mix(v.color.xy, v.color.zw, bitcoord);
                if(v.texcoord.w > 1.5){ //nearest
                    bitmap_miplevel = 0;
                    bitcoord = clamp_to_nearest(bitcoord, texsize, mix(v.color.xy, v.color.zw, v.texcoord.xy));
                }
            } else if(v.texcoord.w < -.5) { //clamped
                vec2 texsize = textureSize(bitmap_atlas, 0).xy;
                vec2 mtexsize = (v.color.zw-v.color.xy)*texsize;
                bitmap_miplevel = mip_level(mix(v.color.xy, v.color.zw, v.texcoord.xy), texsize);

                bitmap_fill_toggle = 1;
                bitcoord = clamp(v.texcoord.xy, 0.0+.5/mtexsize, 1.0-.5/mtexsize);
                bitcoord = mix(v.color.xy, v.color.zw, bitcoord);
                if(v.texcoord.w < -1.5){ //nearest
                    bitmap_miplevel = 0;
                    bitcoord = clamp_to_nearest(bitcoord, texsize, /*mix(v.color.xy, v.color.zw, v.texcoord.xy)*/bitcoord);
                    //bitcoord = clamp(bitcoord, v.color.xy+.5/texsize, v.color.zw-.5/texsize); //WHY DONT I NEED THIS
                }
            }
        } else { //radial gradient - commented out sorry
            float f = v.texcoord.w;
            vec2 a = vec2(f, 0) - v.texcoord.xy;
            float l = length(a);
            a /= l;
            coord = vec2(1.0/max(1.0, sqrt(1.0- f*f*a.y*a.y)/l+f*a.x/l), (-v.texcoord.z * 2.0 + 1.0) / textureSize(gradient_atlas, 0).y);
        }
        vec4 gradient_color = textureLod(gradient_atlas, coord, 0.0); //no mipmap whatevers on gradient lookups
        vec4 bitmap_color = textureLod(bitmap_atlas, vec3(bitcoord.xy, v.texcoord.z), bitmap_miplevel);

        //unpremultiply the bitmap
        bitmap_color.rgb /= max(bitmap_color.a, .001);

        return mix(gradient_color*v.color, bitmap_color, bitmap_fill_toggle);
    }

    /*vec4 apply_color_transform(vec4 c) {
        //return c * v.color_xform[0] + v.color_xform[1] (non pre-multiplied version)

        float a = c.a*v.color_xform[0].a + v.color_xform[1].a;
        vec3 mul_rgb = v.color_xform[0].rgb;
        vec3 add_rgb = v.color_xform[1].rgb;
        float mul_a = v.color_xform[0].a;
        float add_a = v.color_xform[1].a;

        vec3 rgb = c.rgb*(mul_rgb*mul_a + add_a/max(c.a, .001)) + add_rgb*mul_a*c.a + add_a;
        return vec4(rgb, a);
    }*/
    
    void bias_depth(){
        gl_FragDepth = gl_FragCoord.z - v.depth_bias * depth_bias_scale;
    }
    
    void defaultfragfunc(){
        frag_color = compute_color_full(v) * v.color_xform[0] + v.color_xform[1];
        bias_depth();
    }
    
    
#endif
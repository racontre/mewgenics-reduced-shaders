#version 150
#include "std_in.shader"

uniform sampler2D noise;
uniform float timer;

struct vertex {
    vec4 color;
    vec4 texcoord;
};


#if COMPILING_VERTEX_PROGRAM
    out vertex v;

    void vert(){
        v.color = color;
        v.texcoord = texcoord;

        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);
    } 

#elif COMPILING_FRAGMENT_PROGRAM
    in vertex v;
    out vec4 frag_color;


    //bicubic sampling from https://stackoverflow.com/a/42179924/997193
    vec4 cubic(float v) {
        vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
        vec4 s = n * n * n;
        float x = s.x;
        float y = s.y - 4.0 * s.x;
        float z = s.z - 4.0 * s.y + 6.0 * s.x;
        float w = 6.0 - x - y - z;
        return vec4(x, y, z, w) * (1.0/6.0);
    }

    vec4 textureBicubic(sampler2D sampler, vec2 texCoords) {

        vec2 texSize = textureSize(sampler, 0);
        vec2 invTexSize = 1.0 / texSize;

        texCoords = texCoords * texSize - 0.5;


        vec2 fxy = fract(texCoords);
        texCoords -= fxy;

        vec4 xcubic = cubic(fxy.x);
        vec4 ycubic = cubic(fxy.y);

        vec4 c = texCoords.xxyy + vec2(-0.5, +1.5).xyxy;

        vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
        vec4 offset = c + vec4(xcubic.yw, ycubic.yw) / s;

        offset *= invTexSize.xxyy;

        vec4 sample0 = texture(sampler, offset.xz);
        vec4 sample1 = texture(sampler, offset.yz);
        vec4 sample2 = texture(sampler, offset.xw);
        vec4 sample3 = texture(sampler, offset.yw);

        float sx = s.x / (s.x + s.y);
        float sy = s.z / (s.z + s.w);

        return mix(
            mix(sample3, sample2, sx), mix(sample1, sample0, sx)
            , sy);
    }

    vec3 hsv_to_rgb(vec3 hsv) {
        float C = hsv.z*hsv.y;
        float X = C*(1.-abs(mod(hsv.x/60.,2.)-1.));
        float m = hsv.z-C;
    
        vec3 rgb = vec3(C,X,0.);
        if (hsv.x <= 120. && hsv.x >= 60.) {
            rgb = vec3(X,C,0.);
        } else if (hsv.x <= 180. && hsv.x >= 120.) {
            rgb = vec3(0.,C,X);
        } else if (hsv.x <= 240. && hsv.x >= 180.) {
            rgb = vec3(0.,X,C);
        } else if (hsv.x <= 300. && hsv.x >= 240.) {
            rgb = vec3(X,0.,C);
        } else if (hsv.x <= 360. && hsv.x >= 300.) {
            rgb = vec3(C,0.,X);
        }
        rgb += m;
    
        return rgb;
    }


    void frag(){
	return; //check changes
        vec2 center_vector = (v.texcoord.xy - vec2(.5,.5))*vec2(1.0, 1.0);
        float center_distance = length(center_vector)*2; //0 at center, 1 at edge, sqrt(2) at corner
        float vignetting = 1.5-center_distance;
        vignetting = mix(1, vignetting, 1);
        vignetting = clamp(vignetting, 0, 1);


        const float shim_speed = .001;
        const float shim_scale = .1;
        float shim = textureBicubic(noise, v.texcoord.xy * shim_scale + vec2(-1, -1)*timer*shim_speed).r + textureBicubic(noise, v.texcoord.xy * shim_scale + vec2(1, 1)*timer*shim_speed).r;
        shim = (sin(shim * 120) + 1) * .5;

        vec3 base = hsv_to_rgb(vec3(shim*360, .2, 1));

        frag_color = vec4(base.rgb, shim * (1.0 - vignetting));
    }

#endif

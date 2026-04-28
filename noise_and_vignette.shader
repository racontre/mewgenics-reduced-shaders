#version 150
#include "std_in.shader"

uniform sampler2D framebuf;
uniform sampler2D noise;
uniform sampler2D dust;
uniform vec2 timer;
uniform float vignette_strength_relative;
uniform float hair_toggle;
uniform float dust_toggle;
uniform float noise_toggle;

struct vertex {
    vec4 color;
    vec4 texcoord;
};


#if COMPILING_VERTEX_PROGRAM
    out vertex v;
    out vec2 noise_offset;
    out vec2 dust_offset;
    out float vignette_strength;
    out float show_hair;

    float rand(float x){
        return fract(sin(x)*100000.0);
    }

    void vert(){
        v.color = color;
        v.texcoord = texcoord;

        float tx = floor(timer.x*24)/24;
        noise_offset = vec2(sin(tx)*1000, sin(tx*.74824)*1000);

        dust_offset = vec2(sin(tx)*1000, sin(tx*.74824)*1000);

        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);

        vignette_strength = (1.0-vignette_strength_relative) * .8;

        show_hair = step(rand(tx), .25);
    } 

#elif COMPILING_FRAGMENT_PROGRAM
    in vertex v;
    in vec2 noise_offset;
    in vec2 dust_offset;
    in float vignette_strength;
    in float show_hair;
    out vec4 frag_color;
    

    vec3 blendSoftLight(vec3 base, vec3 blend) {
        return mix(
            sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend), 
            2.0 * base * blend + base * base * (1.0 - 2.0 * blend), 
            step(base, vec3(0.5))
        );
    }

    vec3 SoftLight(vec3 base, vec3 blend, float alpha) {
        return mix(base, blendSoftLight(base, blend), alpha);
    }

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

    void frag(){
	return; //check changes
        vec2 center_vector = (v.texcoord.xy - vec2(.5,.5))*vec2(1.0, 1.0);
        float center_distance = length(center_vector)*2; //0 at center, 1 at edge, sqrt(2) at corner
        float vignetting = 1.5-center_distance;
        vignetting = mix(1, vignetting, vignette_strength);
        vignetting = clamp(vignetting, 0, 1);

        if(noise_toggle > 0){
            vec3 noise = textureBicubic(noise, v.texcoord.xy * vec2(16.0/9.0, 1.0) * .5 + noise_offset).rgb;
            vec3 dust = textureBicubic(dust, v.texcoord.xy * vec2(16.0/9.0, 1.0) * .25 + dust_offset).rgb;

            dust = dust.rrr*dust_toggle+mix(vec3(0.0), dust.ggg, show_hair * hair_toggle);

            float blurstrx = noise.r*.6;
            float blurstry = noise.g*.6;

            vec3 base1 = texture(framebuf, v.texcoord.xy).rgb;
            vec3 base2 = texture(framebuf, v.texcoord.xy+vec2(blurstrx, 0)/512).rgb;
            vec3 base3 = texture(framebuf, v.texcoord.xy+vec2(-blurstrx, 0)/512).rgb;
            vec3 base4 = texture(framebuf, v.texcoord.xy+vec2(0, blurstry)/512).rgb;
            vec3 base5 = texture(framebuf, v.texcoord.xy+vec2(0, -blurstry)/512).rgb;

            vec3 base = (base1+(base2+base3+base4+base5)*.5)/3;

            frag_color = vec4((SoftLight(base*vignetting, noise, .2*noise_toggle)-dust*.05) , 1);
        } else {
            vec3 dust = textureBicubic(dust, v.texcoord.xy * vec2(16.0/9.0, 1.0) * .25 + dust_offset).rgb;
            dust = dust.rrr*dust_toggle+mix(vec3(0.0), dust.ggg, show_hair * hair_toggle);


            vec3 base = texture(framebuf, v.texcoord.xy).rgb;


            frag_color = vec4(base*vignetting-dust*.05, 1);
        }
    }

#endif

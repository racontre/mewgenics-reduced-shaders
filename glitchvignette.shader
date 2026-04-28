#version 150
#include "std_in.shader"

uniform sampler2D framebuf;
uniform sampler2D noise;
uniform vec4 timers;

struct vertex {
    vec4 color;
    vec4 texcoord;
};


#if COMPILING_VERTEX_PROGRAM
    out vertex v;
    out float vignette_strength;
    flat out ivec2 noise_offsets[4];

    float rand(float x){
        return fract(sin(x)*100000.0);
    }

    //from https://www.shadertoy.com/view/4djSRW
    vec2 hash21(float p) {
	    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
	    p3 += dot(p3, p3.yzx + 33.33);
        return fract((p3.xx+p3.yz)*p3.zy);
    }

    void vert(){
        v.color = color;
        v.texcoord = texcoord;

        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);
        noise_offsets[0] = ivec2(hash21(timers.x)*1024);
        noise_offsets[1] = ivec2(hash21(timers.y)*1024);
        noise_offsets[2] = ivec2(hash21(timers.z)*1024);
        noise_offsets[3] = ivec2(hash21(timers.w)*1024);
        vignette_strength = 1;
    } 

#elif COMPILING_FRAGMENT_PROGRAM
    in vertex v;
    in float vignette_strength;
    flat in ivec2 noise_offsets[4];
    out vec4 frag_color;

    //from https://www.shadertoy.com/view/4djSRW
    float hash12(vec2 p) {
	    vec3 p3  = fract(vec3(p.xyx) * .1031);
        p3 += dot(p3, p3.yzx + 33.33);
        return fract((p3.x + p3.y) * p3.z);
    }

    vec3 hash31(float p) {
       vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
       p3 += dot(p3, p3.yzx+33.33);
       return fract((p3.xxy+p3.yzz)*p3.zyx); 
    }
    vec3 hash32(vec2 p) {
	    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
        p3 += dot(p3, p3.yxz+33.33);
        return fract((p3.xxy+p3.yzz)*p3.zyx);
    }

    vec4 hash41(float p){
	    vec4 p4 = fract(vec4(p) * vec4(.1031, .1030, .0973, .1099));
        p4 += dot(p4, p4.wzxy+33.33);
        return fract((p4.xxyz+p4.yzzw)*p4.zywx);
    }

    vec4 hash42(vec2 p) {
	    vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
        p4 += dot(p4, p4.wzxy+33.33);
        return fract((p4.xxyz+p4.yzzw)*p4.zywx);
    }

    void frag(){
	return; //check changes
        ivec2 noisesize = textureSize(noise, 0);
        vec2 gscale =  textureSize(noise, 0) / vec2(9, 16) / 4;
        ivec2 vsnap = ivec2(v.texcoord.xy * gscale);

        int vsnapval = int(hash12(vec2(vsnap))*4);
        ivec2 offset = noise_offsets[vsnapval];

        vec2 vUnSnap = vec2(vsnap) / gscale;

        vec2 center_vector = (vUnSnap - vec2(.5,.5))*vec2(1.0, 1.0);
        float center_distance = length(center_vector)*2; //0 at center, 1 at edge, sqrt(2) at corner
        float vignetting = 1.5-center_distance;
        vignetting = mix(1, vignetting, vignette_strength);
        vignetting = clamp(vignetting, 0, 1);

        vec3 noisev = texelFetch(noise, (ivec2(v.texcoord.xy * gscale)+offset)%noisesize, 0).rgb;
        float shuffledist = step(vignetting, noisev.b*noisev.b);
        vec2 shuffledist_uv = ivec2((noisev.rg - .5) * 3.0) / gscale;


        
        vec3 base1 = texture(framebuf, v.texcoord.xy /*+ shuffledist_uv*shuffledist*/).rgb;

        /*vec3 columns = normalize(hash32(vsnap));
        mat3 color_shift = mat3((hash31(columns.x)), (hash31(columns.y)), (hash31(columns.z)));
        //color_shift = (color_shift - .5) * 2.0;
        //color_shift = color_shift / abs(determinant(color_shift));
        vec3 base2 = base1*color_shift ;*/

        vec3 base2 = 1.0-base1;

        vec3 base = mix(base1, base2, shuffledist);

        frag_color = vec4(base.rgb, 1);
    }

#endif

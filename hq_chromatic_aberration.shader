#version 150
#include "std_in.shader"

uniform sampler2D framebuf;

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

    //adapted from https://www.shadertoy.com/view/ltcyRf
    vec4 sca(sampler2D tex, vec2 uv, vec2 direction, float distance){
        vec3 acc = vec3(0);

        const float delta = 0.1;
        const float range = acos(-1.0);
        const float spec = 2.0 * range / 3.0;

        for(float i = -1.0; i <= 1.0; i += delta) {
            vec3 mask = 0.5 + 0.5 * cos(range * i + vec3(-spec, 0, spec));
            acc += mask * texture(tex, uv - direction*distance*i).rgb;
        }

        return vec4(delta * acc, 1);
    }

    vec2 rotate(vec2 v, float a) {
        float s = sin(a);
        float c = cos(a);
        mat2 m = mat2(c, -s, s, c);
        return m * v;
    }

    void frag(){
        vec2 center_vector = v.texcoord.xy - vec2(.5,.5);
        float center_distance = length(center_vector)*2; //0 at center, 1 at edge, sqrt(2) at corner
        float vignetting = clamp(1.5-center_distance, 0, 1);

        vec2 buf_size = vec2(1280, 720);
        float aberration_scale = max(1, center_distance * 2 * 2);
        vec2 aberration_dir = vec2(1,0);
        //vec2 aberration_dir = normalize(vec2(center_vector.y, -center_vector.x));
        //vec2 aberration_dir = normalize(vec2(center_vector.x, center_vector.y));
       // aberration_dir = rotate(aberration_dir, timer);

        vec4 frag = sca(framebuf, v.texcoord.xy, aberration_dir, aberration_scale/buf_size.x);

        vec3 combined = vec3(frag) * vignetting;

        frag_color = vec4(combined.rgb,1);
    }

#endif

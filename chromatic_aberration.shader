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

    void frag(){
	return; //check changes
        vec2 center_vector = v.texcoord.xy - vec2(.5,.5);
        float center_distance = length(center_vector)*2; //0 at center, 1 at edge, sqrt(2) at corner
        float vignetting = clamp(1.5-center_distance, 0, 1);

        vec2 buf_size = vec2(1280, 720);
        float aberration_scale = max(1, center_distance * 2);
        vec2 aberration_dir = vec2(1,0);//normalize(vec2(center_vector.y, -center_vector.x));


        float frag_r1 = texture(framebuf, v.texcoord.xy + 1*aberration_dir*aberration_scale/buf_size).r;
        float frag_r2 = texture(framebuf, v.texcoord.xy + 2*aberration_dir*aberration_scale/buf_size).r;

        float frag_g = texture(framebuf, v.texcoord.xy + 0*aberration_dir*aberration_scale/buf_size).g;

        float frag_b1 = texture(framebuf, v.texcoord.xy + -1*aberration_dir*aberration_scale/buf_size).b;
        float frag_b2 = texture(framebuf, v.texcoord.xy + -2*aberration_dir*aberration_scale/buf_size).b;

        vec3 combined = vec3(frag_r1*.75+frag_r2*.25,frag_g,frag_b1*.75+frag_b2*.25) * vignetting;

        frag_color = vec4(combined.rgb,1);
    }

#endif

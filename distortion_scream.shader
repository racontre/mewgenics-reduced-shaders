#version 150
#include "swf_lib.shader"

uniform vec4 scream_info;
uniform sampler2D noise;

#if COMPILING_VERTEX_PROGRAM

    void vert(){
        v.color = color;
        v.texcoord = texcoord;
        v.color_xform = color_xform;
        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);
    }
    
#elif COMPILING_FRAGMENT_PROGRAM

    void frag(){
        float fadeout_radius = scream_info.x;
		float fadeout_width = scream_info.y;
		float strength = scream_info.z;
        float time = scream_info.w;
        float abberation = 1.0;

        vec2 vec = v.texcoord.xy;
        float angle = atan(vec.y, vec.x) / (2.0*3.1415926535897932384626433832795 / 4.0);
        float l = length(vec);

        vec = normalize(vec) * l * strength;
        float fadeout = clamp(1.0-(l-fadeout_radius)/fadeout_width, 0.0, 1.0);
        vec *= fadeout;
        float angle_tex = texture(noise, vec2(angle, (l*.2-time)*1.0)).x - .5;
        vec *= angle_tex;

        frag_color = vec4(vec.x, vec.y, abberation, 1.0) * v.color * v.color_xform[0] + v.color_xform[1];
    }
    
#endif

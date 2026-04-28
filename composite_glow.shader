#version 150
#include "std_in.shader"
uniform sampler2D framebuf;
uniform float glow_strength;
uniform vec4 glow_color;

struct vertex {
    vec4 color;
    vec4 texcoord;
    vec2 screencoord;
};


#if COMPILING_VERTEX_PROGRAM
    out vertex v;

    void vert(){
        v.color = color;
        v.texcoord = texcoord;
        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);
        //v.screencoord = (gl_Position.xy+vec2(1, 1))*.5; //sample calculation if using odd shapes or ignoring texture coordinates
    } 
#elif COMPILING_FRAGMENT_PROGRAM
    in vertex v;
    out vec4 frag_color;

    void frag(){
	frag_color = vec4(1.0, 0.5, 0.0, 1.0);
	return;
        vec4 outline = texture(framebuf, v.texcoord.xy);

        float outline_power = outline.r;
        outline_power *= glow_strength;
        float cutout_color = outline.g;

        frag_color = vec4(glow_color.rgb, clamp((1-cutout_color) * clamp(outline_power, 0, 1), 0, 1) * glow_color.a);
    }
#endif

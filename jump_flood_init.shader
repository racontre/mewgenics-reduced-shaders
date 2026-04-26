#version 150
#include "std_in.shader"

uniform sampler2D framebuf;
uniform vec2 axis;
uniform float radius;
uniform float alpha_cutoff;

struct vertex
{
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


    vec2 encode_distance_2ch_relative(ivec2 srccoord, ivec2 dstcoord){
        ivec2 dist = (dstcoord - srccoord) + ivec2(127, 127);
        dist = clamp(dist, 0, 255);
        return vec2(dist / 255.0);
    }
    ivec2 decode_distance_2ch_relative(ivec2 srccoord, vec2 encoded){
	    ivec2 ioffset = ivec2(encoded * 255) - ivec2(127, 127);
        return srccoord + ioffset;
    }

    void frag(){
		vec4 tex = texture(framebuf, v.texcoord.xy);
        ivec2 coord = ivec2(v.texcoord.xy*textureSize(framebuf, 0));

		if(tex.r < alpha_cutoff){
            frag_color = vec4(1, 1, tex.r, tex.a);
        } else {
		    frag_color = vec4(encode_distance_2ch_relative(coord, coord), tex.ra);
        }
    }

#endif

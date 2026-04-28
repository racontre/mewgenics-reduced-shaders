#version 150
#include "std_in.shader"
uniform sampler2D framebuf;
uniform float radius;
uniform vec4 outline_color;

// This is the outline for units and intractable objects.

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
	//frag_color = vec4(1, 1, 0.8, 1.0);
	//return;
        vec2 texsize = textureSize(framebuf, 0);
        ivec2 coord = ivec2(v.texcoord.xy*texsize);
        vec4 tex = texelFetch(framebuf, coord, 0);

        ivec2 decoded_position = decode_distance_2ch_relative(coord, tex.rg);
        ivec2 v = decoded_position - coord;

        float dist = sqrt(dot(v, v));
        float c = 0;//1.0 - dist / 64;

        c = clamp(radius - dist + 1.0, 0.0, 1.0);//smoothstep(radius+1, radius, dist);

        frag_color = vec4(1, 1, 1, (1-tex.b)*c) * outline_color;
        //rag_color = vec4(tex.rg, 0, 1);


    }
#endif

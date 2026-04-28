#version 150
#include "std_in.shader"
uniform sampler2D framebuf;

// This shader covers the entire screen

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
	//frag_color = vec4(0.0, 1.0, 0.0, 1.0);
	return;
        vec2 texSize = textureSize(framebuf, 0);
        vec2 invTexSize = 1.0 / texSize;


        //TODO: take advantage of bilinear filtering here to do it in 4 samples instead

        frag_color =   texture(framebuf, v.texcoord.xy)                         * 4

                     + texture(framebuf, v.texcoord.xy+vec2( 1,  0)*invTexSize) * 2
                     + texture(framebuf, v.texcoord.xy+vec2(-1,  0)*invTexSize) * 2
                     + texture(framebuf, v.texcoord.xy+vec2( 0,  1)*invTexSize) * 2
                     + texture(framebuf, v.texcoord.xy+vec2( 0, -1)*invTexSize) * 2

                     + texture(framebuf, v.texcoord.xy+vec2( 1,  1)*invTexSize) * 1
                     + texture(framebuf, v.texcoord.xy+vec2(-1,  1)*invTexSize) * 1
                     + texture(framebuf, v.texcoord.xy+vec2( 1, -1)*invTexSize) * 1
                     + texture(framebuf, v.texcoord.xy+vec2(-1, -1)*invTexSize) * 1;

        frag_color /= 16;
    }                
#endif

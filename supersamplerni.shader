#version 150
#include "std_in.shader"
uniform sampler2D framebuf;
uniform int scale;

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
return; // check results
        ivec2 pxcoord = (scale%2==1) ?
                            ivec2(floor(v.texcoord.xy * textureSize(framebuf, 0)))
                        :   ivec2(round(v.texcoord.xy * textureSize(framebuf, 0)));

        pxcoord -= ivec2(scale/2, scale/2);

        vec3 accum = vec3(0);
        for(int x = 0; x < scale; x++) {
            for(int y = 0; y < scale; y++) {
                accum += texelFetch(framebuf, pxcoord + ivec2(x, y), 0).rgb;
            }
        }

        frag_color = vec4(accum / float(scale*scale), 1);
    }
#endif

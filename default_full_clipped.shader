#version 150
#include "swf_lib.shader"
uniform sampler2D cliptexture;

#if COMPILING_VERTEX_PROGRAM

    out vec2 screencoord;

    void vert(){
        defaultvertfunc();
        screencoord = (gl_Position.xy+vec2(1, 1))*.5;
    }
    
#elif COMPILING_FRAGMENT_PROGRAM

    in vec2 screencoord;

    void frag(){
        ivec2 size = textureSize(cliptexture, 0);
        ivec2 clipcoord = ivec2(size*screencoord);
        vec4 clipper_color = texelFetch(cliptexture, clipcoord, 0);

        float neighbor_alpha = max(max(texelFetch(cliptexture, clipcoord+ivec2(1, 0), 0).a,texelFetch(cliptexture, clipcoord+ivec2(-1, 0), 0).a),
                               max(texelFetch(cliptexture, clipcoord+ivec2(0, 1), 0).a, texelFetch(cliptexture, clipcoord+ivec2(0, -1), 0).a));

        vec4 color = compute_color_full(v) * v.color_xform[0] + v.color_xform[1];

        //frag_color = mix(color, clipper_color, clipper_color.a);
        frag_color.rgb = color.rgb * (1-clipper_color.a) + clipper_color.rgb;
        frag_color.a = color.a;

        if(neighbor_alpha >= 1 && clipper_color.a < 1){ //on an AA edge
            frag_color.a = color.a * (1-clipper_color.a);
        }
        if(clipper_color.a >= 1) {
            frag_color.a = 0;
        }

        bias_depth();
    }
    
#endif

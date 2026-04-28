#version 150
#include "swf_lib.shader"

#if COMPILING_VERTEX_PROGRAM
    void vert(){
        defaultvertfunc();
    }
    
#elif COMPILING_FRAGMENT_PROGRAM
    in vec2 screencoord;

    void frag(){
        //WATER STUFF
        vec4 frag_color_main = compute_color_full(v);
        
        float iswater = 0;
        if(frag_color_main.r > .99 && frag_color_main.g < .01 && frag_color_main.b > .99) iswater = 1;


        frag_color = frag_color_main * v.color_xform[0] + v.color_xform[1];
        if(iswater > .5) discard;

        bias_depth();
    }
    
#endif

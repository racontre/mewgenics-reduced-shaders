#version 150
#include "swf_lib.shader"
uniform sampler2D shaded;

// This has something to do with obstacles, specifically the rectangle around it and green bg?. Return; doesn't seem to change much.
// No noticeable improvements if disabled, but didn't find any glitches either yet.

#if COMPILING_VERTEX_PROGRAM
    out vec2 screencoord;
    
    void vert(){
        defaultvertfunc();
        screencoord = (gl_Position.xy+vec2(1, 1))*.5;
    }
    
#elif COMPILING_FRAGMENT_PROGRAM
    in vec2 screencoord;

    void frag(){
        vec4 shadowcolor = textureLod(shaded, screencoord, 0.0);
        vec4 maincolor = compute_color_full(v) * v.color_xform[0] + v.color_xform[1];
        frag_color = vec4(mix(maincolor.rgb, vec3(0,0,0), shadowcolor.a * .25), maincolor.a);
        bias_depth();
    }
    
#endif

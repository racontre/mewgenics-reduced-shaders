#version 150
#include "swf_lib.shader"

#if COMPILING_VERTEX_PROGRAM
    out vec2 screencoord;

    void vert(){
        defaultvertfunc();
        screencoord = (gl_Position.xy+vec2(1, 1))*.5;
    }
    
#elif COMPILING_FRAGMENT_PROGRAM
    in vec2 screencoord;

    vec3 hsv2rgb(vec3 c) {
        vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

    void frag(){

        vec4 outcolor = compute_color_full(v);

        float x = dot(screencoord*1280, vec2(1, -.5));

        vec3 hsv = vec3(x*.005, .3, (1-outcolor.r)*.4+.6);
        vec4 palettechoice = vec4(hsv2rgb(hsv).rgb, 1);


        if(!(abs(outcolor.x - outcolor.y) < .001 && abs(outcolor.x - outcolor.z) < .001)) {
            palettechoice = outcolor;
        }

        //keep black and white exact
        if(all(lessThan(outcolor.rgb, vec3(.001))) || all(greaterThan(outcolor.rgb, vec3(1-.001)))){
            palettechoice = outcolor;
        }

        frag_color = vec4(palettechoice.xyz, outcolor.w) * v.color_xform[0] + v.color_xform[1];
        bias_depth();
    }
    
#endif

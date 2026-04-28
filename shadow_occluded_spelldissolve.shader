#version 150
#include "swf_lib.shader"
uniform sampler2D shaded;
uniform float timer;

#if COMPILING_VERTEX_PROGRAM
    out vec2 screencoord;
    
    void vert(){
        defaultvertfunc();
        screencoord = (gl_Position.xy+vec2(1, 1))*.5;
    }
    
#elif COMPILING_FRAGMENT_PROGRAM
    in vec2 screencoord;
    
    float rand(vec2 n) { 
        return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
    }

    float noise(vec2 p){
        vec2 ip = floor(p);
        vec2 u = fract(p);
        u = u*u*(3.0-2.0*u);
        
        float res = mix(
            mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
            mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
        return res*res;
    }

    void frag(){
        vec2 adj_screencoord = vec2(screencoord.x*400, screencoord.y*50);
        vec2 distort = vec2(
            (noise(adj_screencoord+vec2(timer*0, timer*-50))-.5),
            (noise((adj_screencoord+vec2(235, 947))+vec2(timer*0, timer*-50))-.5)*2
        )*.01;
        vec4 shadowcolor = textureLod(shaded, screencoord+distort, 0.0);
        vec4 maincolor = compute_color_full(v) * v.color_xform[0] + v.color_xform[1];
        frag_color = vec4(mix(maincolor.rgb, vec3(0,0,0), shadowcolor.a * 1.0), maincolor.a);

        bias_depth();
    }
    
#endif

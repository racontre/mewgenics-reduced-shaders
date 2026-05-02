#version 150
#include "swf_lib.shader"

uniform sampler2D water_bot;
uniform sampler2D water_top;
uniform sampler2D reflections;
uniform float timer; //0
uniform vec4 distortfactor; //1,1,0,0
uniform vec2 distortscale; //1,1
uniform float reflection_transparency; //.25
uniform vec4 scroll; //-.01, .05, -.1, -.01
uniform mat4 camera_mat;

#if COMPILING_VERTEX_PROGRAM
    out vec2 screencoord;
    out vec2 reflectioncoord;
    
    void vert(){
        defaultvertfunc();
        reflectioncoord = (gl_Position.xy+vec2(1, 1))*.5;

        screencoord = (camera_mat * vec4(gl_Position.xy, 0.0, 1.0)).xy;
        screencoord *= vec2(1, (16.0/9.0)) * .05;
    }
    
#elif COMPILING_FRAGMENT_PROGRAM
    in vec2 screencoord;
    in vec2 reflectioncoord;

    void frag(){
        //WATER STUFF
        vec4 frag_color_main = compute_color_full(v);
        
        float iswater = 0;
        if(frag_color_main.r > .99 && frag_color_main.g < .01 && frag_color_main.b > .99) iswater = 1;

        vec2 screenscale = vec2(1, (9.0/16.0)) * 2;
        vec2 texscale = vec2(1, 2) * 3;

        vec2 sx_r = screencoord * screenscale * texscale * 2.7215;
        
        vec2 sx = sx_r;
        vec2 sin_distortionr = vec2(sin(sx.y * 15 + timer * 3), 0) * .001;

        sx = sx_r*distortscale.x;     
        vec2 sin_distortionb = vec2(
                                sin(sx.y + timer*.5) + sin(sx.y * 1.8 + timer*.5*1.5) + sin(sx.y * 2.9 + timer*.5*.5),
                                sin(sx.x + timer*.5 * .5) + sin(sx.x * 1.4 + timer*.5*2.9) + sin(sx.x * 2.5 + timer*.5)
                              ) * .015 * .5;
                              
        
                              
        sx = sx_r*distortscale.y;                   
        vec2 sin_distortiont = vec2(
                                sin(sx.y + timer*.5) + sin(sx.y * 1.8 + timer*.5*1.5) + sin(sx.y * 2.9 + timer*.5*.5),
                                sin(sx.x + timer*.5 * .5) + sin(sx.x * 1.4 + timer*.5*2.9) + sin(sx.x * 2.5 + timer*.5)
                              ) * .015 * .5;

        vec4 water_color_b = texture(water_bot, screencoord * screenscale * texscale * .5 + scroll.xy*timer*.3 * .5 + sin_distortionb * distortfactor.x * mix(1.0, sin(timer*distortfactor.w), distortfactor.z));
        vec4 water_color_t = texture(water_top, screencoord * screenscale * texscale * .5 + scroll.zw*timer*.3 * .5 + sin_distortiont * distortfactor.y * mix(1.0, sin(timer*distortfactor.w), distortfactor.z));
        vec4 water_color = water_color_b * (1.0-water_color_t.a) + water_color_t;
        water_color.a = 1;


        

        vec2 rcoord = reflectioncoord + sin_distortionb / texscale * .5 + sin_distortionr;
        vec2 rsize = textureSize(reflections, 0);
        vec4 reflection_color = texture(reflections, rcoord) * (1.0/4.0);
        reflection_color += texture(reflections, rcoord + vec2(0, 1)/rsize) * (1.0/8.0);
        reflection_color += texture(reflections, rcoord + vec2(1, 0)/rsize) * (1.0/8.0);
        reflection_color += texture(reflections, rcoord + vec2(0, -1)/rsize) * (1.0/8.0);
        reflection_color += texture(reflections, rcoord + vec2(-1, 0)/rsize) * (1.0/8.0);
        reflection_color += texture(reflections, rcoord + vec2(1, 1)/rsize) * (1.0/16.0);
        reflection_color += texture(reflections, rcoord + vec2(-1, -1)/rsize) * (1.0/16.0);
        reflection_color += texture(reflections, rcoord + vec2(-1, 1)/rsize) * (1.0/16.0);
        reflection_color += texture(reflections, rcoord + vec2(1, -1)/rsize) * (1.0/16.0);


        reflection_color *= reflection_transparency;
        water_color = water_color * (1.0-reflection_color.a) + reflection_color;// * reflection_color.a;

        frag_color = mix(frag_color_main, water_color, iswater) * v.color_xform[0] + v.color_xform[1];
        
        if(iswater < .5) discard;

        bias_depth();
    }
    
#endif

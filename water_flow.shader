#version 150
#include "swf_lib.shader"

uniform sampler2D water_bot;
uniform sampler2D water_top;
uniform sampler2D water_top2;
uniform sampler2D reflections;
uniform sampler2D flow_map;
uniform float timer; //0
uniform vec4 distortfactor; //1,1,0,0
uniform vec2 distortscale; //1,1
uniform float reflection_transparency; //.25
uniform vec4 scroll; //-.01, .05, -.1, -.01

uniform mat4 flow_texture_transform;
uniform float flowmap_padding;
uniform mat4 camera_mat;
//uniform mat4 flow_texture_camera_transform;

#if COMPILING_VERTEX_PROGRAM
    out vec2 screencoord;
    out vec2 reflectioncoord;
    out vec2 flowcoord;
    
    void vert(){
        defaultvertfunc();
        
        reflectioncoord = (gl_Position.xy+vec2(1, 1))*.5;

        screencoord = ((camera_mat) * vec4(gl_Position.xy, 0.0, 1.0)).xy;
        screencoord *= vec2(1, (16.0/9.0)) * .05;

        vec2 fc = (gl_Position.xy + vec2(1, 1)) * .5 * vec2(1280, 720);
        fc.y = 720-fc.y;

        flowcoord = (flow_texture_transform * vec4(fc, 0, 1)).xy; //map screen coords to world pos
        flowcoord = (flowcoord+vec2(flowmap_padding, flowmap_padding)) / (10+flowmap_padding*2); //map world pos to flow texture coordinate
    }
    
#elif COMPILING_FRAGMENT_PROGRAM
    in vec2 screencoord;
    in vec2 flowcoord;
    in vec2 reflectioncoord;

    void frag(){
	frag_color = vec4(0.0, 1.0, 0.0, 1.0);
return;

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

        vec2 water_coord_b = screencoord * screenscale * texscale * .5 + scroll.xy*timer*.3 * .5 + sin_distortionb * distortfactor.x * mix(1.0, sin(timer*distortfactor.w), distortfactor.z);
        vec2 water_coord_t = screencoord * screenscale * texscale * .5 + scroll.zw*timer*.3 * .5 + sin_distortiont * distortfactor.y * mix(1.0, sin(timer*distortfactor.w), distortfactor.z);

        //FLOW
        vec4 flow_tex = texture(flow_map, flowcoord);
        vec2 flow_vector = (flow_tex.rg - vec2(128.0/255.0, 128.0/255.0)) * flow_tex.a;
        flow_vector = -(flow_vector.x * vec2(2, 1) + flow_vector.y * vec2(-2, 1)) * .1;
        flow_vector.x *= 9.0/16.0;

        float flow_timer = timer*2;

        float timer_a = mod(flow_timer, 2.0)-1;
        float timer_b = mod(flow_timer+1, 2.0)-1;

        float fader = 1-abs(mod(flow_timer+1, 2.0) - 1);
        //float fader = (cos(flow_timer * 3.141592)+1)*.5;

        vec4 water_color_b = mix(texture(water_bot, water_coord_b + flow_vector * timer_a), texture(water_bot, water_coord_b + flow_vector * timer_b), fader);
        vec4 water_color_t = mix(texture(water_top, water_coord_t + flow_vector * timer_a), texture(water_top, water_coord_t + flow_vector * timer_b), fader);

        vec4 water_color_t2 = mix(texture(water_top2, water_coord_t + flow_vector * timer_a), texture(water_top2, water_coord_t + flow_vector * timer_b), fader);

        vec4 water_color = water_color_b * (1.0-water_color_t.a) + water_color_t;
        water_color = water_color * (1.0 - water_color_t2.a*flow_tex.b) + water_color_t2*flow_tex.b;
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

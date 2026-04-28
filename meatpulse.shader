#version 150
#include "swf_lib.shader"
uniform float timer; //0
uniform mat4 camera_mat;
uniform float pulse_speed;
uniform float pulse_amount;
uniform float pulse_resolution;
uniform vec2 pulse_offset;

// Throbbing Domain floor bg. 

#if COMPILING_VERTEX_PROGRAM

    void vert(){
        defaultvertfunc();
    }
    
#elif COMPILING_FRAGMENT_PROGRAM

    void frag(){
	//frag_color = vec4(1.0, 0.0, 1.0,1.0); //magenta
	//return;
        vertex v_adjusted = v;
        //v_adjusted.texcoord.x += sin(timer*pulse_speed+v.texcoord.x*pulse_resolution + pulse_offset.x)*pulse_amount;
        //v_adjusted.texcoord.y += sin(timer*pulse_speed+v.texcoord.y*pulse_resolution + pulse_offset.y)*pulse_amount;

        frag_color = compute_color_full(v_adjusted) * v_adjusted.color_xform[0] + v_adjusted.color_xform[1];
        bias_depth();
    }
    
#endif

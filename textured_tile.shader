#version 150
#include "swf_lib.shader"

uniform sampler2D tex;
uniform mat4 camera_mat;

#if COMPILING_VERTEX_PROGRAM
out vec2 screencoord;

void vert() {
    defaultvertfunc();

    screencoord = ((camera_mat) * vec4(gl_Position.xy, 0.0, 1.0)).xy;
    screencoord *= vec2(1, (16.0/9.0)) * .05;
}

#elif COMPILING_FRAGMENT_PROGRAM
in vec2 screencoord;
in vec2 reflectioncoord;

void frag() {
	return; //check results
    //WATER STUFF
    vec4 frag_color_main = compute_color_full(v);

    float iswater = 0;
    if(frag_color_main.r > .99 && frag_color_main.g < .01 && frag_color_main.b > .99) iswater = 1;

    vec2 screenscale = vec2(1, (9.0/16.0)) * 2;
    vec2 texscale = vec2(1, 2) * 3;

    vec4 water_color = texture(tex, screencoord * screenscale * texscale * .5  * mat2(1.0/sqrt(2.0), 1.0/sqrt(2.0), -1.0/sqrt(2.0), 1.0/sqrt(2.0)));

    frag_color = mix(frag_color_main, water_color, iswater) * v.color_xform[0] + v.color_xform[1];

    //if(iswater < .5) discard;

    bias_depth();
}

#endif

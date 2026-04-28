#version 150
#include "swf_lib.shader"

uniform sampler2D ice;
uniform sampler2D ice_distortion;
uniform sampler2D reflections;
//uniform float reflection_transparency; //.25
uniform mat4 camera_mat;

#if COMPILING_VERTEX_PROGRAM
out vec2 screencoord;
out vec2 reflectioncoord;

void vert() {
    defaultvertfunc();

    reflectioncoord = (gl_Position.xy+vec2(1, 1))*.5;

    screencoord = ((camera_mat) * vec4(gl_Position.xy, 0.0, 1.0)).xy;
    screencoord *= vec2(1, (16.0/9.0)) * .05;
}

#elif COMPILING_FRAGMENT_PROGRAM
in vec2 screencoord;
in vec2 reflectioncoord;

void frag() {
    //WATER STUFF
    vec4 frag_color_main = compute_color_full(v);

    float iswater = 0;
    if(frag_color_main.r > .99 && frag_color_main.g < .01 && frag_color_main.b > .99) iswater = 1;

    vec2 screenscale = vec2(1, (9.0/16.0)) * 2;
    vec2 texscale = vec2(1, 2) * 3;

    vec4 water_color = texture(ice, screencoord * screenscale * texscale * .5);
    vec4 distortioncolor = texture(ice_distortion, screencoord * screenscale * texscale * .5);

    vec2 rcoord = reflectioncoord;
    vec2 rsize = textureSize(reflections, 0);
    vec4 reflection_color = texture(reflections, rcoord + ((distortioncolor.xy-vec2(.5, .5))*distortioncolor.z*rsize * .00005));
    /*reflection_color += texture(reflections, rcoord + vec2(0, 1)/rsize) * (1.0/8.0);
    reflection_color += texture(reflections, rcoord + vec2(1, 0)/rsize) * (1.0/8.0);
    reflection_color += texture(reflections, rcoord + vec2(0, -1)/rsize) * (1.0/8.0);
    reflection_color += texture(reflections, rcoord + vec2(-1, 0)/rsize) * (1.0/8.0);
    reflection_color += texture(reflections, rcoord + vec2(1, 1)/rsize) * (1.0/16.0);
    reflection_color += texture(reflections, rcoord + vec2(-1, -1)/rsize) * (1.0/16.0);
    reflection_color += texture(reflections, rcoord + vec2(-1, 1)/rsize) * (1.0/16.0);
    reflection_color += texture(reflections, rcoord + vec2(1, -1)/rsize) * (1.0/16.0);*/


    reflection_color *= .5;//reflection_transparency;
    water_color = water_color * (1.0-reflection_color.a) + reflection_color;// * reflection_color.a;

    frag_color = mix(frag_color_main, water_color, iswater) * v.color_xform[0] + v.color_xform[1];

    //if(iswater < .5) discard;

    bias_depth();
}

#endif

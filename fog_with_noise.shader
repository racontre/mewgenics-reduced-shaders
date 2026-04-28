#version 150
#include "swf_lib.shader"
uniform sampler2D noise;
uniform float timer;
const float noiseamt = 1;
uniform mat4 camera_mat;

#if COMPILING_VERTEX_PROGRAM
    out vec2 screencoord;

    void vert(){
        defaultvertfunc();

        screencoord = (camera_mat * vec4(gl_Position.xy, 0.0, 1.0)).xy;
        screencoord *= vec2(1, (16.0/9.0)) * .05;
    }
    
#elif COMPILING_FRAGMENT_PROGRAM
    in vec2 screencoord;

    float stretch(float v, float A) {
        float a = 1.0-A;
        return .5 * ( (2.0*v - 1.0) / (a + (1.0-a) * abs(2.0*v - 1.0) ) ) + .5;
    }

    void frag(){
	return;
        vec4 outcolor = compute_color_full(v);
        float noise1 = texture(noise, screencoord * vec2(16, 9) * .1 + timer * vec2(.5, -1) * .05).r;
        float noise2 = texture(noise, (screencoord * vec2(16, 18) * .1 + timer * vec2(.5, -1) * .02) * .04).r;
        noise1 = stretch(noise1, .5);
        noise2 = stretch(noise2, .8);
        noise1 = mix(stretch(noise1*noise2, .5), 1, 1.0-noiseamt);

        frag_color = vec4(outcolor.rgb*noise1, outcolor.a) * v.color_xform[0] + v.color_xform[1];

        bias_depth();
    }
    
#endif
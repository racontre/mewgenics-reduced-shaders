#version 150
#include "swf_lib.shader"

//This puts a strain on game menu and save menu apparently
//Removing the radial gradient breaks fire.

#if COMPILING_VERTEX_PROGRAM

    void vert(){
        v.color = color;
        v.texcoord = texcoord;
        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);

        v.color_xform = color_xform;
        v.depth_bias = depth_bias;
    }
    
#elif COMPILING_FRAGMENT_PROGRAM

    void frag(){
        vec2 coord;
        if(v.texcoord.z >= 0){ //linear gradient
            coord = vec2((v.texcoord.x + 1.0) / 2.0, (v.texcoord.z * 2.0 + 1.0) / textureSize(gradient_atlas, 0).y);
        } else { //radial gradient
            //coord = vec2(sqrt(v.texcoord.x*v.texcoord.x+v.texcoord.y*v.texcoord.y), (-v.texcoord.z * 2.0 + 1.0) / gradient_dimensions.y);
            float f = v.texcoord.w;
            vec2 a = vec2(f, 0) - v.texcoord.xy;
            float l = length(a);
            a /= l;
            coord = vec2(1.0/max(1.0, sqrt(1.0- f*f*a.y*a.y)/l+f*a.x/l), (-v.texcoord.z * 2.0 + 1.0) / textureSize(gradient_atlas, 0).y);
        }
        vec4 gradient_color = textureLod(gradient_atlas, coord, 0.0); //no mipmap whatevers on gradient lookups
        frag_color = gradient_color * v.color  * v.color_xform[0] + v.color_xform[1];
        bias_depth();
    }
    
#endif

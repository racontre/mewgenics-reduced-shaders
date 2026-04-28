#version 150
#include "std_in.shader"
uniform sampler2D lightmap;

//This is the shader that loads the floor textures.

uniform mat4 camera_to_world;
uniform float lightmap_padding;
uniform vec2 offsetmax;

struct vertex
{
    vec4 color;
    vec4 texcoord;
    vec2 screencoord;
};


#if COMPILING_VERTEX_PROGRAM
    out vertex v;

    void vert(){ 
        v.color = color;
        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);

        //compute camera coords
        v.texcoord.xy = texcoord.xy * vec2(1280, 720);
        v.texcoord.y = 720 - v.texcoord.y;

        //camera to world
        v.texcoord.xy = ((camera_to_world) * vec4(v.texcoord.xy, 0, 1)).xy; //map screen coords to world pos
        v.texcoord.xy = (v.texcoord.xy+vec2(lightmap_padding, lightmap_padding)) / (10+lightmap_padding*2); //map world pos to flow texture coordinate
    } 
#elif COMPILING_FRAGMENT_PROGRAM
    in vertex v;
    out vec4 frag_color;

    //bicubic sampling from https://stackoverflow.com/a/42179924/997193
    vec4 cubic(float v) {
        vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
        vec4 s = n * n * n;
        float x = s.x;
        float y = s.y - 4.0 * s.x;
        float z = s.z - 4.0 * s.y + 6.0 * s.x;
        float w = 6.0 - x - y - z;
        return vec4(x, y, z, w) * (1.0/6.0);
    }

    vec4 textureBicubic(sampler2D sampler, vec2 texCoords) {

        vec2 texSize = textureSize(sampler, 0);
        vec2 invTexSize = 1.0 / texSize;

        texCoords = texCoords * texSize - 0.5;


        vec2 fxy = fract(texCoords);
        texCoords -= fxy;

        vec4 xcubic = cubic(fxy.x);
        vec4 ycubic = cubic(fxy.y);

        vec4 c = texCoords.xxyy + vec2(-0.5, +1.5).xyxy;

        vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
        vec4 offset = c + vec4(xcubic.yw, ycubic.yw) / s;

        offset *= invTexSize.xxyy;

        vec4 sample0 = texture(sampler, offset.xz);
        vec4 sample1 = texture(sampler, offset.yz);
        vec4 sample2 = texture(sampler, offset.xw);
        vec4 sample3 = texture(sampler, offset.yw);

        float sx = s.x / (s.x + s.y);
        float sy = s.z / (s.z + s.w);

        return mix(
            mix(sample3, sample2, sx), mix(sample1, sample0, sx)
            , sy);
    }

    void frag(){
	//frag_color = vec4(0.0, 1.0, 0.0, 1.0); // bright green
	//return;
        frag_color = clamp(textureBicubic(lightmap, v.texcoord.xy)-offsetmax.x, 0.0, offsetmax.y);
        //frag_color.a = 1;
    }
#endif

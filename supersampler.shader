#version 150
#include "std_in.shader"
uniform sampler2D framebuf;

// post processing anti aliasing shader according to deepseek lol

struct vertex {
    vec4 color;
    vec4 texcoord;
    vec2 screencoord;
};


#if COMPILING_VERTEX_PROGRAM
    out vertex v;

    void vert(){
        v.color = color;
        v.texcoord = texcoord;
        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);
        //v.screencoord = (gl_Position.xy+vec2(1, 1))*.5; //sample calculation if using odd shapes or ignoring texture coordinates
    } 
#elif COMPILING_FRAGMENT_PROGRAM
    in vertex v;
    out vec4 frag_color;

    void frag(){
	return; //check changes
        ivec2 isize = textureSize(framebuf, 0);
        vec2 pxcoord = v.texcoord.xy * textureSize(framebuf, 0);
        vec2 deriv = vec2(dFdx(pxcoord.x), dFdy(pxcoord.y));

        vec2 xrange = vec2(pxcoord.x - deriv.x*.5, pxcoord.x + deriv.x*.5);
        vec2 yrange = vec2(pxcoord.y - deriv.y*.5, pxcoord.y + deriv.y*.5);
        ivec2 ixr = ivec2(floor(xrange.x), ceil(xrange.y));
        ivec2 iyr = ivec2(floor(yrange.x), ceil(yrange.y));

        vec3 accum = vec3(0,0,0);

        vec2 pixel_intersection_x = vec2((1-(xrange.x - ixr.x)), xrange.y - (ixr.y - 1));
        vec2 pixel_intersection_y = vec2((1-(yrange.x - iyr.x)), yrange.y - (iyr.y - 1));

        int x = ixr.x;
        {
            float portion_x = pixel_intersection_x.x;
            int y = iyr.x;
            float portion = portion_x * pixel_intersection_y.x;
            accum += (texelFetch(framebuf, ivec2(x, y), 0).rgb) * portion;

            for(y = y+1; y<iyr.y-1; y++){
                accum += (texelFetch(framebuf, ivec2(x, y), 0).rgb) * portion_x;
            }

            portion = portion_x * pixel_intersection_y.y;
            accum += (texelFetch(framebuf, ivec2(x, y), 0).rgb) * portion;
        }

        for(x = x+1; x<ixr.y-1; x++){
            int y = iyr.x;
            float portion = pixel_intersection_y.x;
            accum += (texelFetch(framebuf, ivec2(x, y), 0).rgb) * portion;

            for(y = y+1; y<iyr.y-1; y++){
                accum += (texelFetch(framebuf, ivec2(x, y), 0).rgb);
            }

            portion = pixel_intersection_y.y;
            accum += (texelFetch(framebuf, ivec2(x, y), 0).rgb) * portion;
        }

        {
            float portion_x = pixel_intersection_x.y;
            int y = iyr.x;
            float portion = portion_x * pixel_intersection_y.x;
            accum += (texelFetch(framebuf, ivec2(x, y), 0).rgb) * portion;

            for(y = y+1; y<iyr.y-1; y++){
                accum += (texelFetch(framebuf, ivec2(x, y), 0).rgb) * portion_x;
            }

            portion = portion_x * pixel_intersection_y.y;
            accum += (texelFetch(framebuf, ivec2(x, y), 0).rgb) * portion;
        }

        float accum_sum = deriv.x * deriv.y;
        frag_color = vec4(((accum / accum_sum)), 1);
    }
#endif

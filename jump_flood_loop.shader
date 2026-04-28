#version 150
#include "std_in.shader"

uniform sampler2D framebuf;
uniform int offset;

struct vertex
{
    vec4 color;
    vec4 texcoord;
};


#if COMPILING_VERTEX_PROGRAM
    out vertex v;

    void vert(){
        v.color = color;
        v.texcoord = texcoord;
        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);
    } 

#elif COMPILING_FRAGMENT_PROGRAM
    in vertex v;
    out vec4 frag_color;

    vec2 encode_distance_2ch_relative(ivec2 srccoord, ivec2 dstcoord){
        ivec2 dist = (dstcoord - srccoord) + ivec2(127, 127);
        dist = clamp(dist, 0, 255);
        return vec2(dist / 255.0);
    }
    ivec2 decode_distance_2ch_relative(ivec2 srccoord, vec2 encoded){
	    ivec2 ioffset = ivec2(encoded * 255) - ivec2(127, 127);
        return srccoord + ioffset;
    }

    void frag(){
	return;
        vec2 texsize = textureSize(framebuf, 0);
		ivec2 coord = ivec2(v.texcoord.xy*texsize);
        vec4 tex_center = texelFetch(framebuf, coord, 0);

        ivec2 mincoord = ivec2(0,0);
        int mind2 = 256*256*256;
        float valid = 0;

        
        /*for(int y = -1; y <= 1; y++){
            for(int x = -1; x <= 1; x++){
                ivec2 offsetcoord = ivec2(x, y)*offset;

                vec4 tex = texelFetch(framebuf, coord+offsetcoord, 0);
                ivec2 decoded_position = decode_distance_2ch_relative(coord+offsetcoord, tex.rg);
                ivec2 v = decoded_position - coord;

                int offset_dist2 = v.x*v.x+v.y*v.y;
                if(offset_dist2 < mind2 && tex.rg != vec2(1, 1)){
                    mincoord = decoded_position;
                    mind2 = offset_dist2;
                    valid = 1;
                }
            }
        }*/

        //manually unrolled the above, this is so I can not double-sample the center texel
        {
            ivec2 offsetcoord = ivec2(-1, -1)*offset;

            vec4 tex = texelFetch(framebuf, coord+offsetcoord, 0);
            ivec2 decoded_position = decode_distance_2ch_relative(coord+offsetcoord, tex.rg);
            ivec2 v = decoded_position - coord;

            int offset_dist2 = v.x*v.x+v.y*v.y;
            if(offset_dist2 < mind2 && tex.rg != vec2(1, 1)){
                mincoord = decoded_position;
                mind2 = offset_dist2;
                valid = 1;
            }
        }
        {
            ivec2 offsetcoord = ivec2(0, -1)*offset;

            vec4 tex = texelFetch(framebuf, coord+offsetcoord, 0);
            ivec2 decoded_position = decode_distance_2ch_relative(coord+offsetcoord, tex.rg);
            ivec2 v = decoded_position - coord;

            int offset_dist2 = v.x*v.x+v.y*v.y;
            if(offset_dist2 < mind2 && tex.rg != vec2(1, 1)){
                mincoord = decoded_position;
                mind2 = offset_dist2;
                valid = 1;
            }
        }
        {
            ivec2 offsetcoord = ivec2(1, -1)*offset;

            vec4 tex = texelFetch(framebuf, coord+offsetcoord, 0);
            ivec2 decoded_position = decode_distance_2ch_relative(coord+offsetcoord, tex.rg);
            ivec2 v = decoded_position - coord;

            int offset_dist2 = v.x*v.x+v.y*v.y;
            if(offset_dist2 < mind2 && tex.rg != vec2(1, 1)){
                mincoord = decoded_position;
                mind2 = offset_dist2;
                valid = 1;
            }
        }
        {
            ivec2 offsetcoord = ivec2(-1, 0)*offset;

            vec4 tex = texelFetch(framebuf, coord+offsetcoord, 0);
            ivec2 decoded_position = decode_distance_2ch_relative(coord+offsetcoord, tex.rg);
            ivec2 v = decoded_position - coord;

            int offset_dist2 = v.x*v.x+v.y*v.y;
            if(offset_dist2 < mind2 && tex.rg != vec2(1, 1)){
                mincoord = decoded_position;
                mind2 = offset_dist2;
                valid = 1;
            }
        }
        {
            ivec2 offsetcoord = ivec2(0, 0)*offset;

            vec4 tex = tex_center; //this is the reason for the manual unroll
            ivec2 decoded_position = decode_distance_2ch_relative(coord+offsetcoord, tex.rg);
            ivec2 v = decoded_position - coord;

            int offset_dist2 = v.x*v.x+v.y*v.y;
            if(offset_dist2 < mind2 && tex.rg != vec2(1, 1)){
                mincoord = decoded_position;
                mind2 = offset_dist2;
                valid = 1;
            }
        }
        {
            ivec2 offsetcoord = ivec2(1, 0)*offset;

            vec4 tex = texelFetch(framebuf, coord+offsetcoord, 0);
            ivec2 decoded_position = decode_distance_2ch_relative(coord+offsetcoord, tex.rg);
            ivec2 v = decoded_position - coord;

            int offset_dist2 = v.x*v.x+v.y*v.y;
            if(offset_dist2 < mind2 && tex.rg != vec2(1, 1)){
                mincoord = decoded_position;
                mind2 = offset_dist2;
                valid = 1;
            }
        }
        {
            ivec2 offsetcoord = ivec2(-1, 1)*offset;

            vec4 tex = texelFetch(framebuf, coord+offsetcoord, 0);
            ivec2 decoded_position = decode_distance_2ch_relative(coord+offsetcoord, tex.rg);
            ivec2 v = decoded_position - coord;

            int offset_dist2 = v.x*v.x+v.y*v.y;
            if(offset_dist2 < mind2 && tex.rg != vec2(1, 1)){
                mincoord = decoded_position;
                mind2 = offset_dist2;
                valid = 1;
            }
        }
        {
            ivec2 offsetcoord = ivec2(0, 1)*offset;

            vec4 tex = texelFetch(framebuf, coord+offsetcoord, 0);
            ivec2 decoded_position = decode_distance_2ch_relative(coord+offsetcoord, tex.rg);
            ivec2 v = decoded_position - coord;

            int offset_dist2 = v.x*v.x+v.y*v.y;
            if(offset_dist2 < mind2 && tex.rg != vec2(1, 1)){
                mincoord = decoded_position;
                mind2 = offset_dist2;
                valid = 1;
            }
        }
        {
            ivec2 offsetcoord = ivec2(1, 1)*offset;

            vec4 tex = texelFetch(framebuf, coord+offsetcoord, 0);
            ivec2 decoded_position = decode_distance_2ch_relative(coord+offsetcoord, tex.rg);
            ivec2 v = decoded_position - coord;

            int offset_dist2 = v.x*v.x+v.y*v.y;
            if(offset_dist2 < mind2 && tex.rg != vec2(1, 1)){
                mincoord = decoded_position;
                mind2 = offset_dist2;
                valid = 1;
            }
        }


        frag_color = vec4(mix(vec2(1, 1), encode_distance_2ch_relative(coord, mincoord), valid), tex_center.ba);
    }

#endif

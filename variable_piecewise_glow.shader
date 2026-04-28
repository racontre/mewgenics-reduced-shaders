#version 150
#include "std_in.shader"

uniform sampler2D framebuf;
uniform vec2 axis;
uniform float radius;
uniform float alpha_cutoff;

//blurs the red channel, leaves the rest the same

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

    void frag(){
	frag_color = vec4(1.0, 1.0, 0.0, 1.0);
	return;
        float x,y,rr=radius*radius,d,w,w0;
		vec2 texSize = textureSize(framebuf, 0);
		
        vec2 p=v.texcoord.xy;
        float accum = 0.0;
		float sum = 0;
		int size = int(radius);
		float sigma = radius / 3.0;

		float C = -.5 / (sigma * sigma);

		vec4 tex = texture(framebuf, v.texcoord.xy);
		
		//symmetric version, bilinear filtering taken into consideration
		for(int x = 0; x <= size; x += 2){
			float weight_0 = exp(C*x*x);
			float weight_1 = exp(C*(x+1)*(x+1));
			if(x == 0) weight_0 *= .5; //0 is counted twice, so must be subtracted again
			
			float samp_offset = weight_1 / (weight_0 + weight_1);
			float weight = (weight_0+weight_1);
			
			float samp_a = texture(framebuf, v.texcoord.xy + (x+samp_offset) * axis / texSize).r;
			float samp_b = texture(framebuf, v.texcoord.xy + -(x+samp_offset) * axis / texSize).r;
			samp_a *= step(alpha_cutoff, samp_a);
			samp_b *= step(alpha_cutoff, samp_b);

			accum += weight * samp_a;
			accum += weight * samp_b;

			sum += weight*2;
		}

		frag_color = vec4(accum / sum, tex.gba);
    }

#endif

#version 150
#include "std_in.shader"

// runs horribly on Mac

uniform sampler2D framebuf;
uniform vec2 axis;
uniform float radius;

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
	frag_color = vec4(1.0,0.0,1.0,1.0);
	return;
        float x,y,rr=radius*radius,d,w,w0;
		vec2 texSize = textureSize(framebuf, 0);
		
        vec2 p=v.texcoord.xy;
        vec3 accum = vec3(0.0,0.0,0.0);
		float sum = 0;
		int size = int(radius);
		float sigma = radius / 3.0;

		float C = -.5 / (sigma * sigma);

		//weight = exp(-.5 * pow(x / sigma, 2.0));
		//weight = exp (C * x * x)
		//^^^ these 2 are equivalent
		
		/*for(int x = -size; x <= size; x++){
			float weight = exp(-.5 * pow(x / sigma, 2.0));
			accum += weight * texture(framebuf, v.texcoord.xy + x * axis / texSize).rgb;
			sum += weight;
		}*/
		
		//symmetric version (half the math, one extra tex lookup that can be optimized out
		/*for(int x = 0; x <= size; x++){
			float weight = exp(-.5 * pow(x / sigma, 2.0));
			if(x == 0) weight *= .5; //0 is counted twice, so must be subtracted again
			
			accum += weight * texture(framebuf, v.texcoord.xy + x * axis / texSize).rgb;
			accum += weight * texture(framebuf, v.texcoord.xy + -x * axis / texSize).rgb;

			sum += weight*2;
		}*/
		
		//symmetric version, bilinear filtering taken into consideration
		for(int x = 0; x <= size; x += 2){
			float weight_0 = exp(C*x*x);
			float weight_1 = exp(C*(x+1)*(x+1));
			if(x == 0) weight_0 *= .5; //0 is counted twice, so must be subtracted again
			
			float samp_offset = weight_1 / (weight_0 + weight_1);
			float weight = (weight_0+weight_1);
			
			accum += weight * texture(framebuf, v.texcoord.xy + (x+samp_offset) * axis / texSize).rgb;
			accum += weight * texture(framebuf, v.texcoord.xy + -(x+samp_offset) * axis / texSize).rgb;

			sum += weight*2;
		}
		
		//texel fetch version
		/*ivec2 ipos = ivec2(v.texcoord.xy * texSize);
		ivec2 iaxis = ivec2(axis);
		for(int x = -size; x <= size; x++){
			float weight = exp(-.5 * pow(x / sigma, 2.0));
			accum += weight * texelFetch(framebuf, ipos + x * iaxis, 0).rgb;
			sum += weight; 
		}*/
		
		//texel fetch version, symmetric
		/*ivec2 ipos = ivec2(v.texcoord.xy * texSize);
		ivec2 iaxis = ivec2(axis);
		ivec2 isize = ivec2(texSize)-ivec2(1, 1);
		
		{
			float weight = exp(-.5 * pow(0.0 / sigma, 2.0));
			accum += weight * texelFetch(framebuf, clamp(ipos, ivec2(0, 0), ivec2(isize)), 0).rgb;
			sum += weight; 
		}
		for(int x = 1; x <= size; x++){
			float weight = exp(-.5 * pow(x / sigma, 2.0));
			accum += weight * texelFetch(framebuf, clamp(ipos + x * iaxis, ivec2(0, 0), ivec2(isize)), 0).rgb;
			accum += weight * texelFetch(framebuf, clamp(ipos - x * iaxis, ivec2(0, 0), ivec2(isize)), 0).rgb;
			sum += weight*2; 
		}*/

		frag_color = vec4(accum / sum, 1.0f);
    }

#endif

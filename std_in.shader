#if COMPILING_VERTEX_PROGRAM
    in vec2 position;
    in vec4 color;
    in vec4 texcoord;
    
    #if MATRICES_AS_ATTRIBS
        in mat4 mvp;
        in mat2x4 color_xform;
        in float depth_bias;
    #else 
        uniform mat4 mvp;
        uniform mat2x4 color_xform;
        uniform float depth_bias;
    #endif
#endif

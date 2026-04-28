#version 430 core

layout(std430, binding = 0)
restrict volatile buffer InputBuffer {
    int Input[];
};

layout(std430, binding = 1)
restrict volatile buffer InputCounterBuffer {
    uint InputCounter;
};

layout(std430, binding = 2)
restrict volatile buffer LatchedCounterBuffer {
    uint LatchedCounter;
};


uniform sampler2D cursor_tex;
uniform ivec2 cursor_size;
uniform ivec2 cursor_hotspot;
uniform mat4 projection;

struct vertex {
    vec2 texcoord;
};

#if COMPILING_VERTEX_PROGRAM
    out vertex v;

    void vert() {
        uint counter = InputCounter;
        uint latched = atomicCompSwap(LatchedCounter, 16384, counter);
        if(latched == 16384) {
            latched = counter;
        }

        latched = latched & (16384 - 1);

        ivec2 mouse_coord = ivec2(
            Input[latched * 2 + 0],
            Input[latched * 2 + 1]) + ivec2(-cursor_hotspot.x, cursor_hotspot.y);

        v.texcoord = vec2(gl_VertexID % 2, gl_VertexID / 2);
        gl_Position = projection * vec4(vec2(mouse_coord/* + vec2(0.5)*/) + v.texcoord * cursor_size - vec2(0, cursor_size.y), 0, 1);
    }
#elif COMPILING_FRAGMENT_PROGRAM
    in vertex v;
    out vec4 frag_color;

    void frag() {
        frag_color = texture(cursor_tex, vec2(v.texcoord.x, 1.0-v.texcoord.y));
    }
#endif

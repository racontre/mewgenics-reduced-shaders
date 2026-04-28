#version 150

uniform sampler2D cursor_tex;
uniform vec2 mouse_coord;
uniform ivec2 cursor_size;
uniform ivec2 cursor_hotspot;
uniform mat4 projection;

struct vertex
{
    vec2 texcoord;
};

#if COMPILING_VERTEX_PROGRAM
    out vertex v;

    void vert(){
        v.texcoord = vec2(gl_VertexID % 2, gl_VertexID / 2);
        gl_Position = projection * vec4(vec2(mouse_coord + ivec2(-cursor_hotspot.x, cursor_hotspot.y)/* + vec2(0.5)*/) + v.texcoord * cursor_size - vec2(0, cursor_size.y), 0, 1);
    } 
#elif COMPILING_FRAGMENT_PROGRAM
    in vertex v;
    out vec4 frag_color;

    void frag(){
        frag_color = texture(cursor_tex, vec2(v.texcoord.x, 1.0-v.texcoord.y));
    }
#endif

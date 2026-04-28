#version 150
#include "swf_lib.shader"

#if COMPILING_VERTEX_PROGRAM

    void vert(){
        defaultvertfunc();
    }
    
#elif COMPILING_FRAGMENT_PROGRAM

    void frag(){
        defaultfragfunc();
    }
    
#endif

#version 320 es
precision mediump float;
uniform sampler2D tex;
in vec2 v_texcoord;
out vec4 fragColor;
void main() {
  vec4 C = texture(tex, v_texcoord);
  vec3 T = vec3(1.0, 0.8, 0.6);
  fragColor = vec4(C.rgb * T, C.a);
}

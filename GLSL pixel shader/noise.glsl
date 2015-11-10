#version 330
precision mediump float;

varying vec2 uv;
uniform float iGlobalTime;

float random(float p) {
  return fract(sin(p)*10000.);
}

float noise(vec2 p) {
  return random(p.x + p.y*10000.);
}

vec2 sw(vec2 p) {return vec2( floor(p.x) , floor(p.y) );}
vec2 se(vec2 p) {return vec2( ceil(p.x)  , floor(p.y) );}
vec2 nw(vec2 p) {return vec2( floor(p.x) , ceil(p.y)  );}
vec2 ne(vec2 p) {return vec2( ceil(p.x)  , ceil(p.y)  );}

float smoothNoise(vec2 p) {
  vec2 inter = smoothstep(0., 1., fract(p));
  float s = mix(noise(sw(p)), noise(se(p)), inter.x);
  float n = mix(noise(nw(p)), noise(ne(p)), inter.x);
  return mix(s, n, inter.y);
}

float movingNoise(vec2 p, float time) {
  float total = 0.0;
  total += smoothNoise(p     - time);
  total += smoothNoise(p*2.  + time) / 2.;
  total += smoothNoise(p*4.  - time) / 4.;
  total += smoothNoise(p*8.  + time) / 8.;
  total += smoothNoise(p*16. - time) / 16.;
  total /= 1. + 1./2. + 1./4. + 1./8. + 1./16.;
  return total;
}

float nestedNoise(vec2 p, float time) {
  float x = movingNoise(p, time);
  float y = movingNoise(p + 100., time);
  return movingNoise(p + vec2(x, y), time);
}

void main() {
  vec2 p = uv * 30.0;
  float brightness = nestedNoise(p, iGlobalTime);
  // float brightness = movingNoise(p, iGlobalTime);
  // float brightness = smoothNoise(p);
  gl_FragColor = vec4(vec3(brightness), 1.0);
}
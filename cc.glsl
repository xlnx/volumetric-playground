// random/hash function              
float hash( float n )
{
  return fract(cos(n)*41415.92653);
}

// 3d noise function
float noise( in vec3 x )
{
  vec3 p  = floor(x);
  vec3 f  = smoothstep(0.0, 1.0, fract(x));
  float n = p.x + p.y*57.0 + 113.0*p.z;

  return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
    mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
    mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
}

float fbm( vec3 p )
{
  const mat3 m = mat3( 0.00,  1.60,  1.20, -1.60,  0.72, -0.96, -1.20, -0.96,  1.28 );
  float f = 0.5000*noise( p ); p = m*p*1.1;
  f += 0.2500*noise( p ); p = m*p*1.2;
  f += 0.1666*noise( p ); p = m*p;
  f += 0.0834*noise( p );
  return f;
}

void main()
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
	gl_FragColor = vec4(1.) * fbm(vec3(uv * 10., iGlobalTime));
}
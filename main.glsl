#define PI 3.141592654
#define EPS .00

const float omega = 2.;

vec2 complexMul(vec2 a, vec2 b)
{
	return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x);
}

float UVRandom(vec2 uv, float salt, float random)
{
	uv += vec2(salt, random);
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 gaussian(vec2 uv, vec2 seed)
{
	float rand1 = UVRandom(uv, 10.612, seed.x);
	float rand2 = UVRandom(uv, 11.899, seed.y);
	float x = sqrt(2. * log(rand1 + 1.));
	float y = 2. * PI * rand2;
	return x * vec2(cos(y), sin(y)); 
}

void main()
{
	// float t = gTime;
	// float k = length(uv);
	// float sinv = sin(omega * t);
	// float cosv = cos(omega * t);
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
	vec2 tex = uv * .5 + .5;
	vec2 seed = vec2(1.);
	gl_FragColor = vec4(gaussian(tex, seed * .5 + 1.), 0, 1);
}
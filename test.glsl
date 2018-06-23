#define PI 3.14159
#define RAYMARCH_CLOUD_ITER 12

struct Ray
{
	vec3 o;
	vec3 dir;
};

vec3 hsv2rgb(vec3 c)
{
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// float rand(vec2 n) { 
// 	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
// }

// float rand(vec3 n)
// {
// 	return fract(sin(dot(n, vec3(12.9898, 4.1414, 5.87924))) * 43758.5453);
// }

// float noise(vec3 p)
// {
// 	vec2 e = vec2(0.0, 1.0);
// 	vec3 i = floor(p);
// 	vec3 f = fract(p);
	
// 	float x0 = mix(rand(i + e.xxx), rand(i + e.yxx), f.x);
// 	float x1 = mix(rand(i + e.xyx), rand(i + e.yyx), f.x);
// 	float x2 = mix(rand(i + e.xxy), rand(i + e.yxy), f.x);
// 	float x3 = mix(rand(i + e.xyy), rand(i + e.yyy), f.x);
	
// 	float y0 = mix(x0, x1, f.y);
// 	float y1 = mix(x2, x3, f.y);
	
// 	float val = mix(y0, y1, f.z);
	
// 	val = val * val * (3.0 - 2.0 * val);
// 	return val;
// }

// float SmoothNoise(vec3 p)
// {
// 	float amp = 1.0;
// 	float freq = 1.0;
// 	float val = 0.0;
	
// 	for (int i = 0; i < 4; i++)
// 	{
// 		amp *= 0.5;
// 		val += amp * noise(freq * p - float(i) * 11.7179);
// 		freq *= 2.0;
// 	}
	
// 	return val;
// }

// vec3 RayMarchCloud(Ray ray, vec3 sun, vec3 bg)
// {
// 	vec3 rayPos = ray.o;
// 	rayPos = ray.dir * (100.0 - rayPos.z) / ray.dir.z;

// 	float dl = 1.0;
// 	vec3 color = bg * 0.8;
// 	vec3 c1 = vec3(0.05, 0.01 - 0.001 * iGlobalTime, 0.1);
// 	vec3 c2 = vec3(0, 0, 0.2 * iGlobalTime);
// 	vec3 c3 = vec3(0.01, 0.01, 0.01);
// 	for (int i = 0; i != RAYMARCH_CLOUD_ITER; ++i) {
// 		rayPos += dl * ray.dir;
// 		float dens = SmoothNoise(c1 * rayPos - c2) * SmoothNoise(c3 * rayPos);
// 		color -= 0.01 * dens * dl;
// 		color += 0.02 * dens * dl;
// 	}
// 	return color;
// }

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


mat3 m = mat3( 0.00,  1.60,  1.20, -1.60,  0.72, -0.96, -1.20, -0.96,  1.28 );

// Fractional Brownian motion
float fbm( vec3 p )
{
	float f = 0.5000*noise( p ); p = m*p*1.1;
	f += 0.2500*noise( p ); p = m*p*1.2;
	f += 0.1666*noise( p ); p = m*p;
	f += 0.0834*noise( p );
	return f;
}

vec3 RayMarchCloud(Ray ray)
{
	// ray.dir
	return vec3(0.);
}

vec3 SKY_grad(float h, float fTime)
{
	//Gradient values sampled from a reference image.
	const vec3 r1 = vec3(195./255.,43./255.,6./255.);
	const vec3 r2 = vec3(228./255.,132./255.,28./255.);
	const vec3 bg1 = vec3(168./255.,139./255.,83./255.);
	const vec3 bl1 = vec3(86./255.,120./255.,147./255.);
	const vec3 bl2 = vec3(96./255.,130./255.,158./255.);
	const vec3 bl3 = vec3(96./255.,130./255.,218./255.);

	h = h-h*0.25*sin(fTime);
	vec3 c;
	if(h<0.25)
		c = mix(r1,r2,4.*h);
	else if(h<0.5)
		c = mix(r2,bg1,4.*(h-0.25));
	else
		c = mix(bg1,bl2,2.*(h-0.5));

	float light = 1.0+0.25*sin(fTime);
	return mix(c,bl3,0.25+0.25*sin(fTime))*light;
}


void main()
{
	// float alpha = iGlobalTime * 0.42;
	// vec3 sun = vec3(sin(alpha), 0, cos(alpha));
	vec3 sun = normalize(vec3(1, 0, 0.1 * iGlobalTime));

	vec2 uv = gl_FragCoord.xy / iResolution.xy - 0.5;
	vec3 Position0 = vec3(1, uv);
	vec3 p = normalize(Position0);

	vec3 color = vec3(0, 0, 0);

	float angle_from_origin = clamp(acos(dot(p, sun)), 0.0, PI);
	float angle_pos = asin(p.z);

	// if (angle_pos > 0.0)
	// {
	float angle_scaled = cos(sqrt(12.3 * angle_pos) - 0.8) + 0.4;

	// vec3 c = vec3(250./255.,163./255.,37./255.);
	float atmosV = 0.25 + 0.5 * (angle_scaled);
	float atmosS = 0.9 - angle_scaled / 18.0;
	float atmosH = mix(0.61, 0.63, p.z);
	vec3 atmos = hsv2rgb(vec3(atmosH, atmosS, atmosV));

	vec3 gradS = SKY_grad(0.75-0.75*dot(p,sun)*clamp(1.0-3.0*p.z,0.0,1.0)*angle_scaled,0.0);
	vec3 gradF = (gradS + atmos)/2.0;

	// Ray ray;
	// ray.o = vec3(0, 0, 0);
	// ray.dir = p;
	// color += atmos + RayMarchCloud(ray, sun, atmos); 

    vec3 domecolor = vec3(0.);
    domecolor += vec3(.98, .86, .62);// * cos(angle_pos * .25); 

    // color += mix(atmos, domecolor, cos(angle_pos * 10.) * 1.);
	color = atmos;
    // color = domecolor;

	const float c1 = 0.025, c2 = 0.15;
	float d = length(sun - p);
	float I = c1 / d + c2 * pow(2.0, -d);
	vec3 c = vec3(255./255.,213./255.,73./255.);
	// vec3 c = vec3(250./255.,163./255.,37./255.);

	color += c * I;

	gl_FragColor = vec4(1.) * fbm(vec3(uv, iGlobalTime)); //vec4(color, 1);
}
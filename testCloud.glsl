// Created by Pheema - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define M_PI (3.14159265358979)
#define GRAVITY (9.80665)
#define EPS (1e-3)
#define RAYMARCH_CLOUD_ITER (16)
#define WAVENUM (32)

const float kSensorWidth = 36e-3;
const float kFocalLength = 18e-3;

const vec2 kWind = vec2(0.0, 1.0);
const float kCloudHeight = 100.0;
const float kOceanScale = 10.0;

const float kCameraSpeed = 10.0;
const float kCameraHeight = 1.0;
const float kCameraShakeAmp = 0.002;
const float kCameraRollNoiseAmp = 0.2;

struct Ray
{
	vec3 o;
    vec3 dir;
};

struct HitInfo
{
	vec3 pos;
    vec3 normal;
    float dist;
    Ray ray;
};

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float rand(vec3 n)
{
    return fract(sin(dot(n, vec3(12.9898, 4.1414, 5.87924))) * 43758.5453);
}

float Noise3D(vec3 p)
{
    vec2 e = vec2(0.0, 1.0);
    vec3 i = floor(p);
    vec3 f = fract(p);
    
    float x0 = mix(rand(i + e.xxx), rand(i + e.yxx), f.x);
    float x1 = mix(rand(i + e.xyx), rand(i + e.yyx), f.x);
    float x2 = mix(rand(i + e.xxy), rand(i + e.yxy), f.x);
    float x3 = mix(rand(i + e.xyy), rand(i + e.yyy), f.x);
    
    float y0 = mix(x0, x1, f.y);
    float y1 = mix(x2, x3, f.y);
    
    float val = mix(y0, y1, f.z);
    
    val = val * val * (3.0 - 2.0 * val);
    return val;
}

float SmoothNoise(vec3 p)
{
    float amp = 1.0;
    float freq = 1.0;
    float val = 0.0;
    
    for (int i = 0; i < 4; i++)
    {   
        amp *= 0.5;
        val += amp * Noise3D(freq * p - float(i) * 11.7179);
        freq *= 2.0;
    }
    
    return val;
}

vec3 RayMarchCloud(Ray ray, vec3 sunDir, vec3 bgColor)
{
    vec3 rayPos = ray.o;
    rayPos += ray.dir * (kCloudHeight - rayPos.y) / ray.dir.y;
    
    float dl = 1.0;
    float scatter = 0.0;
    vec3 t = bgColor;
    for(int i = 0; i < RAYMARCH_CLOUD_ITER; i++) {
        rayPos += dl * ray.dir;
        float dens = SmoothNoise(vec3(0.05, 0.001 - 0.001 * iGlobalTime, 0.1) * rayPos - vec3(0,0, 0.2 * iGlobalTime)) * 
            SmoothNoise(vec3(0.01, 0.01, 0.01) * rayPos);
        t -= 0.01 * t * dens * dl;
        t += 0.02 * dens * dl;
	}
    return t;
}

// Environment map
vec3 BGColor(vec3 dir, vec3 sunDir) {
    vec3 color = vec3(0);
    
    color += mix(
        vec3(0.094, 0.2266, 0.3711),
        vec3(0.988, 0.6953, 0.3805),
       	clamp(0.0, 1.0, dot(sunDir, dir) * dot(sunDir, dir)) * smoothstep(-0.1, 0.1, sunDir.y)
    );
    
    dir.x += 0.01 * sin(312.47 * dir.y + iGlobalTime) * exp(-40.0 * dir.y);
    dir = normalize(dir);
    
    color += smoothstep(0.995, 1.0, dot(sunDir, dir)); 
	return color;
}

void main()
{
	vec2 uv = ( gl_FragCoord.xy / iResolution.xy ) * 2.0 - 1.0;
	float aspect = iResolution.y / iResolution.x;
    
    // Camera settings
	vec3 camPos = vec3(0, kCameraHeight, -kCameraSpeed * iGlobalTime);
    vec3 camDir = vec3(kCameraShakeAmp * (rand(vec2(iGlobalTime, 0.0)) - 0.5), kCameraShakeAmp * (rand(vec2(iGlobalTime, 0.1)) - 0.5), -1);
    
    vec3 up = vec3(0, 1, 0);// vec3(kCameraRollNoiseAmp * (SmoothNoise(vec3(0.2 * iGlobalTime, 0.0, 0.0)) - 0.5), 1.0, 0.0);
    
	vec3 camForward = normalize(camDir);
	vec3 camRight = cross(camForward, up);
	vec3 camUp = cross(camRight, camForward);
	
    // Ray
    Ray ray;
    ray.o = camPos;
    ray.dir = normalize(
        kFocalLength * camForward + 
        kSensorWidth * 0.5 * uv.x * camRight + 
        kSensorWidth * 0.5 * aspect * uv.y * camUp
    );
	
    // Controll the height of the sun
    float mouseY = iMouse.y;
    if (mouseY <= 0.0) mouseY = 0.5 * iResolution.y;
    vec3 sunDir = normalize(vec3(0, -0.1 + 0.3 * mouseY / iResolution.y, -1));
    
    vec3 color = vec3(0);
	HitInfo hit;
    float l = 0.0;
	vec3 bg = BGColor(ray.dir, sunDir);
    if (ray.dir.y < 0.0) 
    {
        // Render an ocean
        // HitInfo hit = IntersectOcean(ray);
        
        // vec3 oceanColor = vec3(0.0, 0.2648, 0.4421) * dot(-ray.dir, vec3(0, 1, 0));
        // vec3 refDir = reflect(ray.dir, hit.normal);
        // refDir.y = abs(refDir.y);
        // l = -camPos.y / ray.dir.y;
        // color = oceanColor + BGColor(refDir, sunDir) * FTerm(dot(refDir, hit.normal), 0.5);
    } 
    else 
    {
        // Render clouds
        color += RayMarchCloud(ray, sunDir, bg);
        l = (kCloudHeight - camPos.y) / ray.dir.y;
    }
    
    // Fog
    color = color; //mix(color, bg * 1.3, 1.0 - exp(-0.0001 * l));
    
    // Color grading
    color = smoothstep(0.3, 0.8, color);
	gl_FragColor = vec4(color, 1.0);
}

const float PI = 3.1415926;
const float PI2 = PI *2.0; 

vec3 sundir = normalize(vec3 ( -1.0,0.1,0.0));
vec3 haloclr1 = vec3(254.,201.,59.)/255.;
vec3 haloclr2 = vec3(253.,158.,45.)/255.;

/************************************
		 Math 
************************************/

vec2 rot (vec2 p, float a) 
{ float s = sin(a); float c = cos(a); return mat2(c,s,-s,c) * p; }


// by iq
float noise(in vec3 v)
{
	vec3 p = floor(v);
    vec3 f = fract(v);
	f = f*f*(3.-2.*f);
	vec2 uv = (p.xy+vec2(37.,17.)*p.z) + f.xy;
	vec2 rg = texture2D( iChannel0, (uv+.5)/256.).yx;
	return mix(rg.x, rg.y, f.z);
} 

vec3 random3f( vec3 p )
{
	return texture2D( iChannel0, (p.xy + vec2(3.0,1.0)*p.z+0.5)/256.0).xyz;
}

// by iq
vec3 voronoi( in vec3 x )
{
    vec3 p = floor( x );
    vec3 f = fract( x );

	float id = 0.0;
    vec2 res = vec2( 100.0 );
    for( int k=-1; k<=1; k++ )
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec3 b = vec3( float(i), float(j), float(k) );
        vec3 r = vec3( b ) - f + random3f( p + b );
        float d = dot( r, r );

        if( d < res.x )
        {
			id = dot( p+b, vec3(1.0,57.0,113.0 ) );
            res = vec2( d, res.x );			
        }
        else if( d < res.y )
        {
            res.y = d;
        }
    }
    return vec3( sqrt( res ), abs(id) );
}

/************************************
		sun & sky & clouds
************************************/

float grow( float x, float bias, float k ) 
{
    return 1.0- exp(-abs(x-bias)*k);
}
float fbmCloud ( vec3 p ) 
{
    float a = 0.5;
    p *= 0.5;
    p.x += iGlobalTime*0.5;
    p.y += iGlobalTime*0.2;
    float f = 1.0;
    float v = 0.0;
    for ( int i = 0 ; i < 5 ; ++i)
    {
        v += a* noise ( p*f ) ;
        a *= 0.5 ;
        f *= 2.;
    }
    v = max(0.0, v - 0.5);
    return v;
}

float calcDomeRay( vec3 ro, vec3 rd, out vec3 domePos)
{
    float r = 500.0; // skydome radius
    float h = 30.0;   // sky height 
    vec3 o = ro ;		
    vec3 p = o;  p.y -= r - h; // p : skydome center;
    float a = dot(rd,rd);
    vec3 op = 2.0*o-p;
    float b = dot(op, rd);
    float c = dot(op,op) - r*r;
    float bac = b*b-a*c;
    float t = -1.0;
    if ( bac > 0.0 )
    {
        t = (-b +sqrt(bac)) / a;
    }
    if ( t < 0.0 ) t = -1.0;
    domePos = ro + rd*t;
    return t;
}

vec3 renderCloud ( vec3 ro, vec3 rd, vec3 bg)
{
    float sundot = clamp(dot(sundir, rd),0.,1.);
    vec3 halo1 = haloclr1 * pow ( sundot, 50.0);
    vec3 halo2 = haloclr2 * pow ( sundot, 20.0);
   	// cloud
    vec4 sum = vec4(bg, 0.0);
    vec3 domePos;
    float domeT;
    if ( rd.y > -0.1 )
    {
        float domeT = calcDomeRay(ro,rd,domePos);
    	if ( domeT > -0.5 ) 
    	{
        	float t = 0.0;
            for ( int i = 0 ;i < 4 ; ++i)
            {
                vec3 pos = domePos + rd * t ;
                float ratio = 0.2;
                float d1 = fbmCloud ( pos*ratio);;
                float d2 = fbmCloud ( (pos*ratio + sundir*1.0 ) ) ;
               
                float dif = clamp(d1-d2,0.0,1.0);
                // diff lighting
                vec4 clr = vec4(vec3(0.3),0.0) + vec4(haloclr2 *dif *5.0, d1);
                clr.rgb += halo2*5.0 + halo1 *2.0 ;				// hack
                clr.w *=  exp ( -distance(domePos, ro)*.025);	// hack
                clr.rgb = clr.rgb * clr.a;
                sum = sum + clr * ( 1.0-sum.a);
                
                t += 1.0;
            }
        }
    }
    return sum.rgb;
}

vec3 renderAtmosphere (vec3 rd)
{
    vec3 atm = vec3(0.0);
    float ry = max(0.0,rd.y);
    atm.r = mix(0.25, 0., grow(ry, 0.0, 5.0));
  	atm.g = mix(0.06,0., grow(ry, 0.1, 0.5));
   	atm.b = mix(0.,0.3, grow(ry, 0., 0.5));
    return atm;
}

vec3 renderSky( vec3 rd)
{
    // sun 
    float sundot = clamp(dot(sundir, rd),0.,1.);
    vec3 core = vec3(1.) * pow(sundot,250.0);
   
    vec3 halo1 = haloclr1 * pow ( sundot, 50.0);
    vec3 halo2 = haloclr2 * pow ( sundot, 20.0);
    vec3 sun = core + halo1 *0.5 + halo2 *0.9 ;
  
    // atm 
    vec3 atm = renderAtmosphere ( rd);
    return sun + atm;
}


vec3 renderSkyCloudDome ( vec3 ro, vec3 rd )
{
	vec3 sky = renderSky(rd);
    vec3 cloud = renderCloud( ro, rd, sky );
    return cloud;
}


/************************************
			Render
************************************/

vec3 render( in vec3 ro, in vec3 rd )
{ 
    vec3 clr = vec3(0.0);
    
    clr = renderSkyCloudDome(ro,rd);
    
    return clr;
	
}


mat3 camera( in vec3 pos, in vec3 lookat, float roll)
{
    vec3 z = normalize(lookat- pos);
    vec3 x = vec3(sin(roll),cos(roll),0.0);  x = cross( z, x ) ;
    vec3 y = cross(x,z);
    return mat3(x, y, z ) ;
}

void main()
{
	vec2 q = gl_FragCoord.xy/iResolution.xy;
    vec2 p = -1.0+2.0*q;
	p.x *= iResolution.x/iResolution.y;
    vec2 mo = iMouse.xy/iResolution.xy;
    vec3 off = vec3(0.0,0.0,0.0);
    float my = 0.6;
    float mx = 0.95;
    if ( iMouse.z > 0.0 )
    {
     	my = mix(0.35,0.75, mo.y);
    	mx = mix(0.9, 1.0,  mo.x);
    }
	vec3 ro = off + vec3( -0.5+3.5*cos(PI2 *mx), 0.0 + 2.0*my, 0.5 + 3.5*sin(PI2 *mx) );
	vec3 ta = off + vec3( 0.0, 1.0,0.0 );
    mat3 ca = camera( ro, ta, 0.0 );
	vec3 rd = ca * normalize( vec3(p.xy,2.0) );
    vec3 col = render( ro, rd );
	col = pow( col, vec3(0.4545) );
    gl_FragColor=vec4( col, 1.0 );
}




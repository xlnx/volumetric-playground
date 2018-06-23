#define RENDER_CLOUDS 1
             
vec3 skybottom   = vec3( 0.6, 0.8, 1.2 );
vec3 skytop      = vec3(0.05, 0.2, 0.5);
vec3 reflskycolor= vec3(0.025, 0.10, 0.20);

vec3 light       = normalize( vec3(  0.1, 0.25,  0.9 ) );

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

// fog and water intersection function.
// 1st: collects fog intensity while traveling
// 2nd: check if hits the water surface and returns the distance
bool trace(in vec3 rStart, in vec3 rDirection, in float sundot, out float fog, out float dist)
{
  float h = 20.0;
  float t = 0.0;
  float st = 1.0;
  float alpha = 0.1;
  float asum = 0.0;
  vec3 p = rStart;
	
  for( int j=1000; j<1120; j++ )
  {
    // some speed-up if all is far away...
    if( t>500.0 ) 
      st = 2.0;
    else if( t>800.0 ) 
      st = 5.0;
    else if( t>1000.0 ) 
      st = 12.0;

    p = rStart + t*rDirection; // calc current ray position

    h = p.y - 0.;//water(p.xz);

    if( h<0.1 ) // hit the water?
    {
      dist = t; 
      fog = asum;
      return true;
    }

    if( p.y>450.0 ) // lost in space? quit...
      break;
    
    // speed up ray if possible...    
    if(rDirection.y > 0.0) // look up (sky!) -> make large steps
      t += 30.0 * st;
    else
      t += max(1.0,1.0*h)*st;
  }

  dist = t; 
  fog = asum;
  if (h<10.0)
   return true;
  return false;
}


vec3 camera( float time )
{
  return vec3( 500.0 * sin(1.5+1.57*time), 0.0, 1200.0*time );
}


void main()
{
  vec2 xy = -1.0 + 2.0*gl_FragCoord.xy / iResolution.xy;
  vec2 s = xy*vec2(1.75,1.0);

  // get camera position and view direction
  float time = (iGlobalTime+13.5+44.)*.05;
  vec3 campos = camera( time );
  vec3 camtar = camera( time + 0.4 );
  campos.y = max(70.+30.0, 70.0+90.0 + 60.0*sin(time*2.0));
  camtar.y = campos.y*0.5;

  float roll = 0.14*sin(time*1.2);
  vec3 cw = normalize(camtar-campos);
  vec3 cp = vec3(sin(roll), cos(roll),0.0);
  vec3 cu = normalize(cross(cw,cp));
  vec3 cv = normalize(cross(cu,cw));
  vec3 rd = normalize( s.x*cu + s.y*cv + 1.6*cw );

  float sundot = clamp(dot(rd,light),0.0,1.0);

  vec3 col;
  float fog=0.0, dist=0.0;

  if (!trace(campos,rd,sundot, fog, dist))
  {
    // // render sky
    float t = pow(1.0-0.7*rd.y, 15.0);
    // col = 0.8*(skybottom*t + skytop*(1.0-t));
    // // sun
    // col += 0.47*vec3(1.6,1.4,1.0)*pow( sundot, 350.0 );
    // // sun haze
    // col += 0.4*vec3(0.8,0.9,1.0)*pow( sundot, 2.0 );

    // CLOUDS
    vec2 shift = vec2( iGlobalTime*80.0, iGlobalTime*60.0 );
    vec4 sum = vec4(0,0,0,0); 
    for (int q=1000; q<1100; q++) // 100 layers
    {
      float c = (float(q-1000)*12.0+350.0-campos.y) / rd.y; // cloud height
      vec3 cpos = campos + c*rd + vec3(831.0, 321.0+float(q-1000)*.15-shift.x*0.2, 1330.0+shift.y*3.0); // cloud position
      float alpha = smoothstep(0.5, 1.0, 
        fbm( cpos*0.0015 )
        )*.9; // fractal cloud density
      vec3 localcolor = mix(vec3( 1.1, 1.05, 1.0 ), 0.7*vec3( 0.4,0.4,0.3 ), alpha); // density color white->gray
      alpha = (1.0-sum.w)*alpha; // alpha/density saturation (the more a cloud layer's density, the more the higher layers will be hidden)
      sum += vec4(localcolor*alpha, alpha); // sum up weightened color
      
      if (sum.w>0.98)
        break;
    }
    float alpha = smoothstep(0.7, 1.0, sum.w);
    sum.rgb /= sum.w+0.0001;

    // This is an important stuff to darken dense-cloud parts when in front 
    // (or near)
    // of the sun (simulates cloud-self shadow)
    sum.rgb -= 0.6*vec3(0.8, 0.75, 0.7)*pow(sundot,13.0)*alpha;
    // This brightens up the low-density parts (edges) of the clouds (simulates light scattering in fog)
    sum.rgb += 0.2*vec3(1.3, 1.2, 1.0)* pow(sundot,5.0)*(1.0-alpha);

    col = mix( col, sum.rgb , sum.w*(1.0-t) );
  }
  else
  {
  }

  gl_FragColor=vec4(col,1.0);
}



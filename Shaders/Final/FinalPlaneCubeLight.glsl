#define PI 3.1459
#define RAD PI / 180.0
//#define SMOKE

#ifdef LOW_QUALITY
#define INSCATTER_STEPS 24
#else
#	ifdef ULTRA_QUALITY
#define INSCATTER_STEPS 64
#	else
#define INSCATTER_STEPS 48
#	endif
#endif

uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D tex;
uniform float tiltTime;
uniform float tiltY;
uniform float tiltZ;
uniform float boxPosZ;
uniform float cubeHeightDiv;
uniform float heightmapHeight;

varying vec2 uv;

float gAnimTime = iGlobalTime * 0.5;


float time=iGlobalTime;
int textureSize = 100;
vec3 boxPos = vec3(-5.0,-1.5,boxPosZ);
vec4 globalColor = vec4(0.0);
vec4 boxColor = vec4(0.3,1.0,0.3,1.0);
vec4 planeColor = vec4(0.3,0.3,1.0,1.0);
float shadowK = 24.0;

const float epsilon = 0.0001; //TODO: smaller epsilon with bisection?
const int maxIterations = 256;
const float marchEpsilon = 0.001;

struct Intersection
{
	vec3 intersectP;
	vec4 color;
	vec3 normal;
	bool exists;
};

struct Ray
{
	vec3 origin;
	vec3 dir;
};

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
            	oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

mat4 translationMatrix(vec3 delta)
{
	return mat4(	1.0,	0.0,	0.0,	delta.x,
					0.0,	1.0,	0.0,	delta.y,
					0.0,	0.0,	1.0,	delta.z,
					0.0,	0.0,	0.0,	1.0 	);
}

mat4 lookAt(vec3 eye, vec3 center, vec3 up)
{
    vec3 zaxis = normalize(center - eye);
    vec3 xaxis = normalize(cross(up, zaxis));
    vec3 yaxis = cross(zaxis, xaxis);

    mat4 matrix;
    //Column Major
    matrix[0][0] = xaxis.x;
    matrix[1][0] = yaxis.x;
    matrix[2][0] = zaxis.x;
    matrix[3][0] = 0;

    matrix[0][1] = xaxis.y;
    matrix[1][1] = yaxis.y;
    matrix[2][1] = zaxis.y;
    matrix[3][1] = 0;

    matrix[0][2] = xaxis.z;
    matrix[1][2] = yaxis.z;
    matrix[2][2] = zaxis.z;
    matrix[3][2] = 0;

    matrix[0][3] = -dot(xaxis, eye);
    matrix[1][3] = -dot(yaxis, eye);
    matrix[2][3] = -dot(zaxis, eye);
    matrix[3][3] = 1;

    return matrix;
}

vec3 translate(vec4 point, mat4 translMatrix)
{
	return (translMatrix*point).xyz;
}

vec3 opTx( vec3 p, mat4 m )
{
    vec3 q = inverse(m)*vec4(p,1.0);
    return q;
}

float f(float x, float y)
{
	return texture(tex, trunc(vec2(x,y)*1.0)/(textureSize)).x*4.0/cubeHeightDiv*heightmapHeight;///cubeHeightDiv; //1.5 ist Wert, wie oft Würfel wiederholt werden
	//return texture(tex, trunc(vec2(x,y)*1.0)/(textureSize)).x*4.0/cubeHeightDiv+cubeHeight; //1.5 ist Wert, wie oft Würfel wiederholt werden

}

vec3 bisect(vec3 _pos, vec3 _direction, int counter)
{
	float step = marchEpsilon*0.5;
	vec3 pos = _pos-_direction*step;

	for(int i=0; i<counter; i++)
	{
		step = step*0.5;
		if (pos.y <= f(pos.x, pos.z)*5.0)
			pos = pos - step*_direction;
		else
			pos = pos + step*_direction;
	}
	return pos;
}

float distBox(vec3 p, vec3 b)
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}
float distBox2(vec3 p, vec3 b, vec3 m)
{
  vec3 d = abs(p-m) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float distPlane(vec3 p, vec4 n, vec3 pos)
{
  // n must be normalized
  //return dot(p-pos,n.xyz) + n.w;
    //return max(-distBox2(p, 0.5, vec3(5.0,1.02,3.0)),(dot(p-pos,n.xyz) + n.w));
    return max(-distBox2(p, 2, vec3(5.0,-0.4,3.0)),(dot(p-pos,n.xyz) + n.w));

}

float distScene(vec3 point)
{
	globalColor = planeColor;
	float distanceBox = distBox(((vec4(point.x,point.y,point.z,1.0)
		*translationMatrix(boxPos) //translation of cube
		*rotationMatrix(vec3(-1.0,0.0,0.0), tiltTime/1.5*(PI/2))) //rotation around z-axis
		*translationMatrix(vec3(0.0,tiltY,tiltZ))).xyz, //translation, so cube rotates around edge 
		vec3(0.5)); 

	float lightBox = distBox2(point,vec3(1),vec3(5.0,-7.5,7.0));

	float distancePlane = distPlane(point, vec4(0.0,1.0,0.0,1.0), vec3(0.0,2.5,0.0));

	//globalColor = distanceBox < distancePlane ? boxColor : planeColor;
	//return distanceBox < distancePlane ? distanceBox : distancePlane;
	//return min(distanceBox,lightBox);
	return min(distanceBox,lightBox);

}

vec3 getNormal(vec3 point)
{
	//grad of the vector (= normal)
	float d = epsilon;
	vec3 left = point + vec3(-d, 0.0, 0.0);
	vec3 right = point + vec3(d, 0.0, 0.0);
	vec3 up = point + vec3(0.0, d, 0.0);
	vec3 down = point + vec3(0.0, -d, 0.0);
	vec3 behind = point + vec3(0.0, 0.0, d);
	vec3 before = point + vec3(0.0, 0.0, -d);

	//gradient
	vec3 gradient = vec3(distScene(right) - distScene(left),
						distScene(up) - distScene(down),
						distScene(behind) - distScene(before));
	return normalize(gradient);
}

vec3 getNormalHf(vec3 p)
{
    vec3 n = vec3( f(p.x-epsilon,p.z) - f(p.x+epsilon,p.z),
                         2.0*epsilon,
                         f(p.x,p.z-epsilon) - f(p.x,p.z+epsilon) );
    return normalize( n );
}

/*****************************************/
/************** Cross Shader *************/
/*****************************************/

Intersection rayMarch(vec3 origin, vec3 direction, int maxSteps)
{
	Intersection intersect;
	intersect.exists = false;

	vec3 newPos = origin;
	newPos += 1.0*direction;

	float height = 0; //TODO; 0 = guter Init wert?
	float t = 1000;

	for(int i = 0; i <= maxSteps; i++)
	{
		t = distScene(newPos);

		if(t < epsilon)
		{
			intersect.exists = true;
			intersect.normal = getNormal(newPos);

			intersect.color = globalColor;
			
			intersect.intersectP = newPos;

			return intersect;
		}
		else
		{
			newPos += t*direction;
		}
	}
	intersect.intersectP = newPos;
	intersect.color = vec4(0.0,0.0,0.0,0.0);
	return intersect;
}

float hash (float n)
{
	return fract(sin(n)*43758.5453);
}

float noise (in vec3 x)
{
	vec3 p = floor(x);
	vec3 f = fract(x);

	f = f*f*(3.0-2.0*f);

	float n = p.x + p.y*57.0 + 113.0*p.z;

	float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
						mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
					mix(mix( hash(n+113.0), hash(n+114.0),f.x),
						mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
	return res;
}

float raySphereIntersect( in vec3 ro, in vec3 rd, in vec4 sph )
{
	vec3 oc = ro - sph.xyz; // looks like we are going place sphere from an offset from ray origin, which is = camera
	float b = 2.0 * dot( oc, rd );
	float c = dot( oc, oc ) - sph.w * sph.w; // w should be size
	float h = b * b - 4.0 * c;
	if ( h < 0.0 )
	{
		return -10000.0;
	}
	float t = (-b - sqrt(h)) / 2.0;
	
	return t;
}

vec3 inscatter( in Ray rayEye, in vec4 light, in vec3 screenPos, in float sceneTraceDepth )
{
	vec3 rayEeyeNDir = normalize( rayEye.dir );
	
	// the eye ray does not intersect with the light, so skip computing
	if ( raySphereIntersect( rayEye.origin, rayEeyeNDir, light ) < -9999.0 )
		return vec3( 0.0 );
	
	float scatter = 0.0;
	float invStepSize = 1.0 / float( INSCATTER_STEPS );
	
	vec3 hitPos, hitNrm;
	vec3 p = rayEye.origin;
	vec3 dp = rayEeyeNDir * invStepSize * sceneTraceDepth;
	
	// apply random offset to minimize banding artifacts.
	p += dp * noise( screenPos ) * 1.5;
	
	for ( int i = 0; i < INSCATTER_STEPS; ++i )
	{
		p += dp;
		
		Ray rayLgt;
		rayLgt.origin = p;
		rayLgt.dir = light.xyz - p;
		float dist2Lgt = length( rayLgt.dir );
		rayLgt.dir /= 8.0;
		
		float sum = 0.0;

		Intersection scatterIntersect = rayMarch(rayLgt.origin, rayLgt.dir, 16);
		//if ( !raymarch( rayLgt, 16, hitPos, hitNrm ) ) //TODO: take own raymarching function
		if (!scatterIntersect.exists ) //TODO: when intersect exists = false instead of true
		{
			// a simple falloff function base on distance to light
			float falloff = 1.0 - pow( clamp( dist2Lgt / light.w, 0.0, 1.0 ), 0.125 );
			sum += falloff;
			
#ifdef SMOKE
			float smoke = noise( 1.5 * ( p + vec3( gAnimTime, 0.0, 0.0 ) ) ) * 0.375;
			sum += smoke * falloff;
#endif
		}
		
		scatter += sum;
	}
	
	scatter *= invStepSize; // normalize the scattering value
	scatter *= 8.0; // make it brighter
	
	return vec3( scatter );
}

float softShadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    for( float t=mint; t < maxt; )
    {
        float h = distScene(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
}

float shadow(vec3 pos, vec3 lightDir)
{
	Intersection shadowIntersect = rayMarch(pos, -lightDir, 128);
	return shadowIntersect.exists ? 0.2 : 1.0;
}

void main()
{
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec4(5.0+sin(iGlobalTime), 15.0, 0.0+sin(iGlobalTime), 1.0);//*rotationMatrix(vec3(0.0,1.0,0.0), iGlobalTime*0.5)*translationMatrix(vec3(-boxPos.xy, 3.5));
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));//TODO: wieder zu -1.0 machen!
	camDir = (lookAt(camP, vec3(-boxPos.xy, 3.5), vec3(0.0,1.0,0.0))*vec4(camDir.xyz, 1.0)).xyz;

	//camDir = (vec4(camDir,0.)* rotationMatrix(vec3(0.0,1.0,0.0), iMouse.y)).xyz;

	vec3 areaLightPos = vec3(0.0,10.0,-10.0);

	//Light Scatter
	Ray ray;
	ray.origin = camP;
	ray.dir = normalize(vec3( p.x, p.y, 1 )); // OpenGL is right handed

	//vec4 lightWs = vec4(5.0 + sin( iGlobalTime * 0.5 ) * 2.0, 2.02 , 3.0 + cos( iGlobalTime * 0.5 ) * 2.0, 20.0);
	vec4 lightWs = vec4(5.0,11.5,7.0,10.0);

	Intersection intersect = rayMarch(camP, camDir, 128);

	if(intersect.exists)
	{
		intersect.color = intersect.color*max(0.2, dot(intersect.normal, normalize(areaLightPos-intersect.intersectP)));


		//Soft Shadows
	}	

		intersect.color.rgb += inscatter( ray, lightWs, vec3( gl_FragCoord.xy, 0.0 ), 12.0 );
		intersect.color.r = smoothstep( 0.0, 1.0, intersect.color.r );
		intersect.color.g = smoothstep( 0.0, 1.0, intersect.color.g - 0.1 );
		intersect.color.b = smoothstep(-0.3, 1.3, intersect.color.b );
		gl_FragColor = intersect.color;

		/*Intersection intersect;


		intersect.color.rgb += inscatter( ray, lightWs, vec3( gl_FragCoord.xy, 0.0 ), 12.0 );
		intersect.color.r = smoothstep( 0.0, 1.0, intersect.color.r );
		intersect.color.g = smoothstep( 0.0, 1.0, intersect.color.g - 0.1 );
		intersect.color.b = smoothstep(-0.3, 1.3, intersect.color.b );
		gl_FragColor = intersect.color;
*/
	//else
		//gl_FragColor = mix(vec4(0.0,0.0,0.0,0.0),fogColor, min(length(intersect.intersectP-camP)/fog,1.0));
		//gl_FragColor = vec4(0.0,0.0,0.0,0.0);

}		
#define PI 3.1459
#define RAD PI / 180.0

uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D tex;
varying vec2 uv;

vec3 dirLightPos;
vec3 planeColor;

const float epsilon = 0.01;
const float marchEpsilon = 0.01;
const int maxIterations = 700;
const int textureSize = 75;
const vec4 fogColor = vec4(1.0, 0.2, 0.0, 1.0);
const int fogK = 13;
const float shadowK = 30.0;

const vec3 aPlane = vec3(-1.0,0.0,10.0);
const vec3 bPlane = vec3(1.0,0.0,10.0);
const vec3 cPlane = vec3(2.0,0.0,0.0);
const vec3 dPlane = vec3(-1.0,0.0,0.0);

// vec3 applyFog( in vec3  rgb,       // original color of the pixel
//                in float distance ) // camera to point distance
// {
//     float fogAmount = 1.0 - exp( -distance*b );
//     vec3  fogColor  = vec3(0.5,0.6,0.7);
//     return mix( rgb, fogColor, fogAmount );
// }

struct Intersection
{
	vec3 intersectP;
	vec4 color;
	vec3 normal;
	bool exists;
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
                0.0,                               	0.0,                                0.0,                                1.0);
}
vec3 opTx( vec3 p, mat4 m )
{
    vec3 q = inverse(m)*vec4(p,1.0);
    return q;
}

float f(float x, float y)
{
	return texture(tex, vec2(x,y)/textureSize).x*1.0;
}

vec3 bisect(vec3 _pos, vec3 _direction, int counter)
{
	float step = marchEpsilon*0.5;
	vec3 pos = _pos-_direction*step;

	for(int i=0; i<counter; i++)
	{
		step = step*0.5;
		if (pos.y <= f(pos.x, pos.z))
			pos = pos - step*_direction;
		else
			pos = pos + step*_direction;
	}
	return pos;
}

vec3 getNormal(vec3 p)
{
    vec3 n = vec3( f(p.x-epsilon,p.z) - f(p.x+epsilon,p.z),
                         2.0*epsilon,
                         f(p.x,p.z-epsilon) - f(p.x,p.z+epsilon) );
    return normalize( n );
}

float softShadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    for( float t=mint; t < maxt; )
    {
        float h = f((ro + rd*t).x, (ro + rd*t).z);
        if( h<0.001 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
}

Intersection rayMarch(vec3 origin, vec3 direction, float beginEpsilon)
{
	Intersection intersect;
	intersect.exists = false;

	vec3 newPos = origin;
	newPos += beginEpsilon*direction; //set nearer pos, when terrain is far below the cam

	for(int i = 0; i <= maxIterations; i++)
	{
		float height = f(newPos.x, newPos.z);

		if(newPos.y <= height) 
		{
			newPos = bisect(newPos, direction, 15);
			height = f(newPos.x, newPos.z);
			intersect.exists = true;
			intersect.normal = getNormal(newPos);
			intersect.color = vec4(height);
			intersect.intersectP = newPos;
			return intersect;
		}
		else
		{
			newPos += marchEpsilon*direction;
		}
	}
	intersect.intersectP = newPos;
	intersect.color = vec4(0.0,0.0,0.0,0.0);
	return intersect;
}

float shadow(vec3 pos, vec3 lightDir)
{
	Intersection shadowIntersect = rayMarch(pos, -lightDir, 0.0);
	return shadowIntersect.exists ? 0.2 : 1.0;

}

void main()
{
	float fov = 70.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec3(50.0, 1.5, 20.0+iGlobalTime/2);//vec3(15.0, abs(sin(iGlobalTime))*5+5.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));
	camDir = (rotationMatrix(vec3(1.0,0.0,0.0), -25.0 * RAD) * vec4(camDir, 1.0)).xyz;

	vec3 areaLightPos = opTx(vec3(100.0,10.0,0.0),rotationMatrix(vec3(0.0,1.0,0.0), iGlobalTime));
	//vec3 dirLightPos = opTx(vec3(100.0,10.0,0.0),rotationMatrix(vec3(0.0,1.0,0.0), iGlobalTime));
	vec3 lightDirection = opTx(vec3(-1.0,-1.0,0.0),rotationMatrix(vec3(0.0,1.0,0.0), iGlobalTime));


	vec4 snowColor = vec4(0.0);

	Intersection intersect = rayMarch(camP, camDir, 1.0);

	if(intersect.exists)
	{
		vec3 lightDir = normalize(dirLightPos - intersect.intersectP);
		//float shadow = max(0.2, softShadow(intersect.intersectP, dirLightPos, 0.1, length(dirLightPos - intersect.intersectP), shadowK));
		if(dot(intersect.normal, vec3(0.0,1.0,0.0)) >= 0.95)
			snowColor = vec4(1.0);
		float shadowIntersect = shadow(intersect.intersectP-lightDirection*0.01, lightDirection);
		intersect.color = intersect.color*vec4(0.5, 1.0, 1.0, 1.0)*shadowIntersect+snowColor;//*shadow + snowColor; //snowColor is making problems
		intersect.color = intersect.color*max(0.2, dot(intersect.normal, normalize(areaLightPos-intersect.intersectP))); //lighting
		//shadows

		intersect.color = mix(intersect.color, fogColor, min(length(intersect.intersectP-camP)/fogK,1.0)); //fog
		Intersection reflIntersect = rayMarch(intersect.intersectP+intersect.normal*0.01, normalize(reflect(camDir, intersect.normal)), 0.0);
		if(reflIntersect.exists)
		{
			reflIntersect.color = reflIntersect.color*vec4(0.5, 1.0, 1.0, 1.0);
			reflIntersect.color = reflIntersect.color*max(0.2, dot(reflIntersect.normal, normalize(areaLightPos-reflIntersect.intersectP))); //lighting
			//reflIntersect.color = mix(reflIntersect.color, fogColor, min(length(reflIntersect.intersectP-camP)/fogK,1.0)); //fog
		}
		gl_FragColor = mix(intersect.color+reflIntersect.color*0.5, fogColor, length(intersect.intersectP-camP)/fogK);
	}		
	else
		gl_FragColor = fogColor;
}		
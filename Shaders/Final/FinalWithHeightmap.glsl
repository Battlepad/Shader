#define PI 3.1459
#define RAD PI / 180.0

uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D tex;

uniform float epsilon;
uniform float maxIterations;

uniform float tiltTime;
uniform float tiltY;
uniform float tiltZ;

uniform float boxPosZ;
uniform float boxPosY;
uniform float camPosX;
uniform float camPosY;
uniform float camPosZ;
uniform float camPosMove;
uniform float lookAtY;

uniform float boxColorInterpolate;
uniform float boxColorEndInterpolate;

uniform float cubeHeightDiv;
uniform float heightmapHeight;
uniform float boxHeight;

varying vec2 uv;

float time=iGlobalTime;
int textureSize = 100;
vec4 globalColor = vec4(0.0);
vec4 boxColor = vec4(0.31,0.439,0.812,1.0);
vec4 boxColorEnd = vec4(0.15,0.87,0.77,1.0);
vec4 planeColor = vec4(0.31,0.439,0.812,1.0);
float shadowK = 24.0;

const float marchEpsilon = 0.005;

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

vec3 opTx( vec3 p, mat4 m )
{
    vec3 q = inverse(m)*vec4(p,1.0);
    return q;
}

float f(float x, float y)
{
	return texture(tex, trunc(vec2(x,y)*0.95)/(textureSize)).x*heightmapHeight/cubeHeightDiv;//cubeHeightDiv; //0.95 ist Wert, wie oft Würfel wiederholt werden
	//return texture(tex, trunc(vec2(x,y)*0.95)/(textureSize)).x*/1;//cubeHeightDiv; //1.5 ist Wert, wie oft Würfel wiederholt werden

	//return texture(tex, trunc(vec2(x,y)*1.0)/(textureSize)).x*4.0/cubeHeightDiv+cubeHeight; //0.95 (lassen) ist Wert, wie oft Würfel wiederholt werden
	//je höher, desto dichter (kleiner) sind cubes, je kleiner, desto größer sind cubes
}

/*vec3 BiSection(vec3 origin, vec3 dir, float t)
{

	float minT = t - epsilon;
	float maxT = t;

	vec3 p = origin + minT * dir;

	for(float i = 1.0; i <15.0; ++i)
	{
		t = (minT + maxT) * 0.5;
		p = origin + t * dir;
		float height = f(p.x, p.z);
		if(height > p.y)
		{
			maxT = t;
		}
		else if(height < p.y)
		{
			minT = t;
		} 
	}
	return p;
}*/

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

float distBox2(vec3 p, vec3 b, vec3 m)
{
  vec3 d = abs(p-m) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}


float distScene(vec3 point)
{
	float distanceHill = distBox2(vec4(point.x,point.y,point.z,1.0),
		vec3(0.5,boxHeight,0.5),vec3(15.3,-1.5,14.15));
	float distanceBox = distBox2(vec4(point.x,point.y,point.z,1.0),
		vec3(0.5),vec3(15.3,boxPosY,14.15)); 

	globalColor = distanceBox < distanceHill ? mix(boxColor, boxColorEnd, boxColorEndInterpolate) : boxColor;

	return min(distanceHill, distanceBox);
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

Intersection rayMarch(vec3 origin, vec3 direction)
{
	Intersection intersect;
	intersect.exists = false;

	vec3 newPos = origin;
	newPos += 3.0*direction;

	float height = 0; //TODO; 0 = guter Init wert?
	float t = 1000;

	for(int i = 0; i <= maxIterations; i++)
	{
		t = distScene(newPos);
		height = f(newPos.x, newPos.z);

		if(t < epsilon)
		{
			intersect.exists = true;
			intersect.normal = getNormal(newPos);

			intersect.color = globalColor;
			
			intersect.intersectP = newPos;

			return intersect;
		}
		else if(newPos.y <= height)
		{
			newPos = bisect(newPos, direction, 0.0); //TODO: raushauen?

			intersect.exists = true;
			intersect.normal = getNormalHf(newPos);
			
			globalColor = planeColor;
			intersect.color = globalColor;
			
			intersect.intersectP = newPos;

			return intersect;
		}
		else
		{
			newPos += epsilon*direction;
		}
	}
	intersect.intersectP = newPos;
	intersect.color = vec4(0.0,0.0,0.0,0.0);
	return intersect;
}

float shadow(vec3 pos, vec3 lightDir)
{
	Intersection shadowIntersect = rayMarch(pos, -lightDir);
	return shadowIntersect.exists ? 0.2 : 1.0;
}

void main()
{
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec4(camPosX, camPosY, camPosZ, 1.0)*rotationMatrix(vec3(0.0,1.0,0.0), 1.3)*translationMatrix(vec3(16.0,0.0,15.0)); //opTx(point,rotationMatrix(vec3(-1.0,0.0,0.0), iGlobalTime)), vec3(0.0,1.0,1.0)
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));//TODO: wieder zu -1.0 machen!
	camDir = (lookAt(camP, vec3(15.0, lookAtY,15.0), vec3(0.0,1.0,0.0))*vec4(camDir.xyz, 1.0)).xyz;

	vec3 areaLightPos = vec3(0.0,15.0,-10.0);

	Intersection intersect = rayMarch(camP, camDir);

	if(intersect.exists)
	{
		intersect.color = intersect.color*max(0.2, dot(intersect.normal, normalize(areaLightPos-intersect.intersectP)));
		gl_FragColor = mix(intersect.color+0.2, vec4(1.0,0.42,0.36,0.0), length(intersect.intersectP-camP)/200);
	}		
	else
		gl_FragColor =  mix(mix(vec4(1.0,0.42,0.36,0.0), vec4(1.0,1.0,1.0,1.0), length(intersect.intersectP-camP)/200), vec4(0.0), boxColorInterpolate);
}		
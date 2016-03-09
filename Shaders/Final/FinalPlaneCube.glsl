#define PI 3.1459
#define RAD PI / 180.0

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D tex;
uniform float time;
uniform float tiltX;
uniform float tiltY;
uniform float tiltZ;
uniform float boxPosZ;
uniform float boxPosY;
uniform float camPosMove;
uniform float camPosX;
uniform float camPosY;

uniform float boxColorInterpolate;

uniform float cubeHeightDiv;
uniform float heightmapHeight;
uniform float soundIntensity;
uniform float lightIntensityAbove;

varying vec2 uv;

int textureSize = 100;
vec3 boxPos = vec3(-5.0,-1.5,boxPosZ);
vec4 globalColor = vec4(0.0);
vec4 boxColor = vec4(0.15,0.87,0.77,1.0);
vec4 planeColor = vec4(0.31,0.439,0.812,1.0);
float shadowK = 18.0;

const float epsilon = 0.001; 
const int maxIterations = 256;

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

float distBox(vec3 p, vec3 b, vec3 m)
{
  vec3 d = abs(p-m) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float distPlane(vec3 point, vec3 normal, float d) 
{
    return max(-distBox(point, 0.5, vec3(5.0,1.02,4.5)),dot(point, normal) - d);
}

float distScene(vec3 point)
{
	float distanceBox;
	vec4 boxColorMixed = mix(boxColor, planeColor, boxColorInterpolate);
	if(iGlobalTime<33.5)
	{
		distanceBox = distBox(((vec4(point.x,point.y,point.z,1.0)
			*translationMatrix(boxPos) //translation of cube
			*rotationMatrix(vec3(-1.0,0.0,0.0), time/0.5*(PI/2))) //rotation around z-axis
			*translationMatrix(vec3(0.0,tiltY,tiltZ))).xyz, //translation, so cube rotates around edge 
			vec3(0.5), vec3(0.0,boxPosY,0.0)); 
	}
	else
	{
		distanceBox = distBox(((vec4(point.x,point.y,point.z,1.0)
			*translationMatrix(vec3(-5.0,boxPosY,-4.5)) //translation of cube
			*rotationMatrix(vec3(tiltX,tiltY,tiltZ), time)) //rotation around z-axis
			*translationMatrix(vec3(0.0,0.0,0.0))).xyz, //translation, so cube rotates around edge 
			vec3(0.5), vec3(0.0,0.0,0.0)); 
	}

	float distancePlane = distPlane(point, vec3(0.0,1.0,0.0), 1.5);
	globalColor = distanceBox < distancePlane ? boxColorMixed : planeColor;
	return distanceBox < distancePlane ? distanceBox : distancePlane;
}

float distSceneReflect(vec3 point)
{
	globalColor = planeColor;
	return distPlane(point, vec3(0.0,1.0,0.0), 1.5);
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

Intersection rayMarch(vec3 origin, vec3 direction)
{
	Intersection intersect;
	intersect.exists = false;

	vec3 newPos = origin;
	newPos += 1.0*direction;

	float height = 0;
	float t = 1000;

	for(int i = 0; i <= maxIterations; i++)
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

Intersection rayMarchReflect(vec3 origin, vec3 direction)
{
	Intersection intersect;
	intersect.exists = false;

	vec3 newPos = origin;
	newPos += 1.0*direction;

	float height = 0;
	float t = 1000;

	for(int i = 0; i <= maxIterations; i++)
	{
		t = distSceneReflect(newPos);

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

void main()
{
	vec2 uv =  gl_FragCoord.xy/iResolution.x;


	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 holePosIn = vec3(5.0,1.02,4.5);
	vec3 holePosAbove = vec3(5.0,3.02,4.5);
	vec4 lightColor1 = vec4(1.0, 0.392, 0.322, 1.0);

	vec3 camP = vec4(camPosX, camPosY, -1.0, 1.0)*rotationMatrix(vec3(0.0,1.0,0.0), camPosMove)*translationMatrix(vec3(holePosIn.x, 1.0, holePosIn.z));
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));//TODO: wieder zu -1.0 machen!
	camDir = (lookAt(camP, vec3(holePosIn.x, 3.0, holePosIn.z), vec3(0.0,1.0,0.0))*vec4(camDir.xyz, 1.0)).xyz;

	vec3 areaLightPos = vec3(0.0,10.0,-10.0);

	vec3 dirLightPos = vec3(0.0,10.0,-10.0);
	vec3 lightDirection = normalize(vec3(-1.0,1.0,-1.0));

	Intersection intersect = rayMarch(camP, camDir);

	if(intersect.exists)
	{
		float shadow = max(0.7, softShadow(intersect.intersectP, lightDirection, 0.1, length(dirLightPos - intersect.intersectP), shadowK));

		intersect.color = intersect.color*max(0.2, dot(intersect.normal, normalize(areaLightPos-intersect.intersectP)));

		Intersection reflIntersect = rayMarchReflect(intersect.intersectP+intersect.normal*0.01, normalize(reflect(camDir, intersect.normal)));
		if(reflIntersect.exists)
		{
			intersect.color += vec4(1.0,0.3,0.3,1.0)*0.1;
		}

		float lightIntensity1 = max(0.4*(2.0-distance(intersect.intersectP, holePosAbove)),0.0);
		float lightIntensity2 = max(1.0*(1.0-distance(intersect.intersectP, holePosIn)),0.0);
		intersect.color += (lightIntensity1*lightColor1)*lightIntensityAbove + (lightIntensity2*lightColor1)*soundIntensity;
		intersect.color *= shadow;

		gl_FragColor = mix(intersect.color+0.2, vec4(1.0,1.0,1.0,1.0), length(intersect.intersectP-camP)/100);
	}		
	else
	{
		gl_FragColor =  vec4(1.0,0.42,0.36,0.0);
	}
}		
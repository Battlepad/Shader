#define PI 3.1459
#define RAD PI / 180.0

uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D tex;
uniform float tiltTime;
uniform float tiltY;
uniform float tiltZ;
uniform float boxPosZ;
uniform float boxPosY;
uniform float cubeHeightDiv;
uniform float heightmapHeight;

varying vec2 uv;

float time=iGlobalTime;
int textureSize = 100;
vec4 globalColor = vec4(0.0);
vec4 boxColor = vec4(0.3,1.0,0.3,1.0);
vec4 planeColor = vec4(0.3,0.3,1.0,1.0);
float shadowK = 24.0;

const float epsilon = 0.02;
const int maxIterations = 1250;
const float marchEpsilon = 0.001;

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
	return texture(tex, trunc(vec2(x,y)*0.95)/(textureSize)).x*heightmapHeight/cubeHeightDiv;//cubeHeightDiv; //1.5 ist Wert, wie oft Würfel wiederholt werden
	//return texture(tex, trunc(vec2(x,y)*1.0)/(textureSize)).x*4.0/cubeHeightDiv+cubeHeight; //0.95 (lassen) ist Wert, wie oft Würfel wiederholt werden
	//je höher, desto dichter (kleiner) sind cubes, je kleiner, desto größer sind cubes
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
    return max(-distBox2(p, 10.0, vec3(5.0,-1.0,3.0)),(dot(p-pos,n.xyz) + n.w));

}

float distScene(vec3 point)
{
	float distanceBox = distBox2(vec4(point.x,point.y,point.z,1.0),
		vec3(0.5),vec3(15.0,0.7,15.0)); //		vec3(0.5),vec3(4.5,boxPosY,4.5)); 
	float distancePlane = distPlane(point, vec4(0.0,1.0,0.0,1.0), vec3(0.0,2.5,0.0));
	//globalColor = distanceBox < distancePlane ? boxColor : planeColor;
	globalColor = boxColor;

	//globalColor = planeColor;
	return distanceBox;
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
	newPos += 1.0*direction;

	float height = 0; //TODO; 0 = guter Init wert?
	//float t = 1000;

	for(int i = 0; i <= maxIterations; i++)
	{
		//t = distScene(newPos);
		height = f(newPos.x, newPos.z);

		/*if(t < epsilon)
		{
			intersect.exists = true;
			intersect.normal = getNormal(newPos);

			intersect.color = globalColor;
			
			intersect.intersectP = newPos;

			return intersect;
		}*/
		if(newPos.y <= height)
		{
			newPos = bisect(newPos, direction, 10); //TODO: raushauen?
			//height = f(newPos.x, newPos.z)*heightmapHeight;
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

	vec3 camP = vec4(5.0, 7.0, 0.0, 1.0)*rotationMatrix(vec3(0.0,1.0,0.0), iGlobalTime*0.5)*translationMatrix(vec3(15.0,0.0,15.0)); //opTx(point,rotationMatrix(vec3(-1.0,0.0,0.0), iGlobalTime)), vec3(0.0,1.0,1.0)
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));//TODO: wieder zu -1.0 machen!
	camDir = (lookAt(camP, vec3(15.0, 0.0,15.0), vec3(0.0,1.0,0.0))*vec4(camDir.xyz, 1.0)).xyz;

	vec3 areaLightPos = vec3(0.0,10.0,-10.0);

	vec3 dirLightPos = opTx(vec3(4.0,2.0,0.0),rotationMatrix(vec3(0.0,1.0,0.0), iGlobalTime));
	vec3 lightDirection = opTx(vec3(-1.0,-1.0,0.0),rotationMatrix(vec3(0.0,1.0,0.0), iGlobalTime));


	Intersection intersect = rayMarch(camP, camDir);

	if(intersect.exists)
	{
		//vec3 lightDir = normalize(dirLightPos - intersect.intersectP);

		//vec3 lightDir = normalize(dirLightPos - intersect.intersectP);
		//float shadow = max(0.2, softShadow(intersect.intersectP, lightDir, 0.1, length(dirLightPos - intersect.intersectP), shadowK));
		//float shadowIntersect = shadow(intersect.intersectP-lightDirection*0.01, lightDirection);
		intersect.color = intersect.color*max(0.2, dot(intersect.normal, normalize(areaLightPos-intersect.intersectP)));
		//float shadow = max(0.2, softShadow(intersect.intersectP, lightDir, 0.1, length(dirLightPos - intersect.intersectP), shadowK));
		//intersect.color = intersect.color*vec4(0.5, 1.0, 1.0, 1.0)*shadowIntersect;

		//Intersection reflIntersect = rayMarch(intersect.intersectP+intersect.normal*0.01, normalize(reflect(camDir, intersect.normal)));
		//if(reflIntersect.exists)
		//{
	//		float shadowReflect = max(0.2, softShadow(reflIntersect.intersectP, lightDir, 0.1, length(dirLightPos - reflIntersect.intersectP), shadowK));
//			reflIntersect.color = reflIntersect.color*shadowReflect;
		//}

		//Soft Shadows
		gl_FragColor = intersect.color+0.2;
	}		
	else
		//gl_FragColor = mix(vec4(0.0,0.0,0.0,0.0),fogColor, min(length(intersect.intersectP-camP)/fog,1.0));
		gl_FragColor = vec4(0.0,0.0,0.0,0.0);

}		
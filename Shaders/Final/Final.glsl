uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
varying vec2 uv;

float time=iGlobalTime;

const float epsilon = 0.00001;
const int maxIterations = 256;
const float shadowK = 24.0;

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
                0.0,                                0.0,                                0.0,                                1.0);
}

vec3 opTx( vec3 p, mat4 m )
{
    vec3 q = inverse(m)*vec4(p,1.0);
    return q;
}
// float softshadow( in vec3 origin, in vec3 dir, float mint, float maxt, float k )
// {
//     float res = 1.0;
//     for( float t = mint; t < maxt; )
//     {
//         float h = distScene(origin + dir * t);
//         if( h < epsilon )
//             return 0.0;
//         res = min( res, k*h/t );
//         t += h;
//     }
//     return res;
// }

float distPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

float distBox( vec3 p, vec3 b )
{
  return length(max(abs(p)-b,0.0));
}


float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

vec3 opTx( vec3 p, mat4 m )
{
    vec3 q = inverse(m)*vec4(p,1.0);
    return q;
}

float distScene(vec3 point)
{
	float distance;
	//float distanceSphere = distSphere(point, vec3(0.0, sin(iGlobalTime)+1,0.0), 0.500);
	//float distanceSphere = opTwist(point);
	//float distanceTorus = distTorus(point, vec3(0.0, sin(iGlobalTime)/2,0.0), vec2(0.40,0.1));
	// float distanceTorus = distTorus(opTx(point, mat4(
 //                1, 0, 0, 0,
 //                0, cos(iGlobalTime), -sin(iGlobalTime), 0,
 //                0, sin(iGlobalTime), cos(iGlobalTime), 0,
 //                0.0, 0.0, 0.0, 1 )),vec3(0.0, 0.0,0.0), vec2(0.40,0.2)); //point to rotate around       

	 //float distanceTorus = distTorus(opTx(point, rotationMatrix(vec3(1.0,1.0,0.0), iGlobalTime)),vec3(0.0, 0.0,0.0), vec2(0.40,0.2)); //point to rotate around       
	//float distanceBox = distBox(point, vec3(1.0,1.0,0.0));
	float distanceBox = sdBox(opTx(point, rotationMatrix(vec3(1.0,1.0,0.0) iGlobalTime), vec3(1.0,1.0,0.0));


	

	//float distanceSphere2 = distSphere(point, vec3(2.0, cos(iGlobalTime)+1,0.0), 0.500);
	//float distancePlane = distPlane(point, vec4(0.0,1.0,0.0,1.0));
	//distance = min(distanceSphere, distanceSphere2);
	//distance = min(distance, distancePlane);
	//return distance;
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

	vec4 sphereColor = vec4(1.0, 0.2, 0.0, 1.0);
	
	float tSphere = 10000.0;
	float tPlane = 10000.0;

	vec3 newPos = origin;

	for(int i = 0; i <= maxIterations; i++)
	{
		float t = distScene(newPos);
		//tSphere = distance(newPos);
		//tPlane = sdPlane(newPos, vec4(0.0,1.0,0.0,1.0));
		newPos += direction*t;

		if(t < epsilon) 
		{
			intersect.exists = true;
			intersect.normal = getNormal(newPos);

			vec4 color = sphereColor;
			intersect.color = color;
			
			intersect.intersectP = newPos;

			return intersect;
		}
	}



	intersect.intersectP = newPos;
	intersect.color = vec4(0.0,0.0,0.0,0.0);
	return intersect;
}

void main()
{
	float fov = 70.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec3(sin(iGlobalTime), sin(iGlobalTime), -10.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	vec3 areaLightPos = vec3(0.5, 3.0, -1.0);
	vec3 dirLightPos = opTx(vec3(4.0,2.0,0.0),rotationMatrix(vec3(0.0,1.0,0.0), iGlobalTime));
	vec3 lightDirection = normalize(vec3(-1.0,-1.0,0.0));


	vec4 fogColor = vec4(0.0,0.8,0.8,1.0);
	float fog = 75.0;

	Intersection intersect = rayMarch(camP, camDir);

	if(intersect.exists)
	{
		//vec3 lightDir = normalize(dirLightPos - intersect.intersectP);
		//float shadow = max(0.2, softShadow(intersect.intersectP, lightDir, 0.1, length(dirLightPos - intersect.intersectP), shadowK));
		intersect.color = intersect.color;

		//Intersection reflIntersect = rayMarch(intersect.intersectP+intersect.normal*0.01, normalize(reflect(camDir, intersect.normal)));
		//if(reflIntersect.exists)
		//{
	//		float shadowReflect = max(0.2, softShadow(reflIntersect.intersectP, lightDir, 0.1, length(dirLightPos - reflIntersect.intersectP), shadowK));
//			reflIntersect.color = reflIntersect.color*shadowReflect;
		//}

		//Soft Shadows
		gl_FragColor = mix(intersect.color, fogColor, length(intersect.intersectP-camP)/fog);
	}		
	else
		gl_FragColor = mix(vec4(0.0,0.0,0.0,0.0),fogColor, min(length(intersect.intersectP-camP)/fog,1.0));
}		
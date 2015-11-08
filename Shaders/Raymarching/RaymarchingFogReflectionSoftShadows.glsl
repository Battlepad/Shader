uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
varying vec2 uv;

float time=iGlobalTime;

const float epsilon = 0.001;
const int maxIterations = 256;
const float shadowK = 16.0;

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

float sphSoftShadow( in vec3 ro, in vec3 rd, in vec4 sph, in float k )
{
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    
    float d = -sph.w + sqrt( max(0.0,sph.w*sph.w-h));
    float t = -b     - sqrt( max(0.0,h) );
    return (t<0.0) ? 1.0 : smoothstep( 0.0, 1.0, k*d/t );
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

vec3 repeat(vec3 P, vec3 b) //P ist Punkt wo man mit Marching gerade ist
{
	return mod(P,b)-b/2;
}

float distPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

float distSphere(vec3 p, vec3 m, float r){
	return length(p - m) - r;
}

float distance(vec3 point){
	vec3 spherePos = vec3(0.0,0.0,0.0);
	float radius = 0.500;
	vec3 b = vec3(4.0,3.0,3.0);
	float dist = distSphere(point, spherePos, radius);
	return dist;

}

float distScene(vec3 point)
{
	float distance;
	float distanceSphere = distSphere(point, vec3(0.0, sin(iGlobalTime)+1,0.0), 0.500);
	//float distanceSphere2 = distSphere(point, vec3(2.0, cos(iGlobalTime)+1,0.0), 0.500);
	float distancePlane = distPlane(point, vec4(0.0,1.0,0.0,1.0));
	//distance = min(distanceSphere, distanceSphere2);
	//distance = min(distance, distancePlane);
	//return distance;
	return min(distanceSphere, distancePlane);
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

	vec3 camP = vec3(0.0, 0.0, -5.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	vec3 areaLightPos = vec3(0.5, 3.0, -1.0);
	vec3 dirLightPos = vec3(4.0,4.0,0.0);
	vec3 lightDirection = normalize(vec3(-1.0,-1.0,0.0));


	vec4 fogColor = vec4(0.0,0.8,0.8,1.0);
	float fog = 100.0;

	Intersection intersect = rayMarch(camP, camDir);

	if(intersect.exists)
	{
		vec3 lightDir = normalize(dirLightPos - intersect.intersectP);
		float shadow = max(0.2, softShadow(intersect.intersectP, lightDir, 0.1, length(dirLightPos - intersect.intersectP), shadowK));
		intersect.color = intersect.color*shadow;

		Intersection reflIntersect = rayMarch(intersect.intersectP+intersect.normal*0.01, normalize(reflect(camDir, intersect.normal)));
		if(reflIntersect.exists)
		{
			float shadowReflect = max(0.2, softShadow(reflIntersect.intersectP, lightDir, 0.1, length(dirLightPos - reflIntersect.intersectP), shadowK));
			reflIntersect.color = reflIntersect.color*shadowReflect;
		}

		//Soft Shadows
		gl_FragColor = mix(intersect.color+reflIntersect.color, fogColor, length(intersect.intersectP-camP)/fog);
	}		
	else
		gl_FragColor = mix(vec4(0.0,0.0,0.0,0.0),fogColor, min(length(intersect.intersectP-camP)/fog,1.0));
}		
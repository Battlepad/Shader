uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
varying vec2 uv;

float time=iGlobalTime;

const float epsilon = 0.001;
const int maxIterations = 128;

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

vec3 repeat(vec3 P, vec3 b) //P ist Punkt wo man mit Marching gerade ist
{
	return mod(P,b)-b/2;
}

float distSphere(vec3 p, vec3 m, float r){
	return length(p - m) - r;
}

float distance(vec3 point){
	vec3 spherePos = vec3(0.0,0.0,0.0);
	float radius = 0.500;
	vec3 b = vec3(4.0,3.0,3.0);
	float dist = distSphere(repeat(point, b), spherePos, radius);
	return dist;

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
	vec3 gradient = vec3(distance(right) - distance(left),
						distance(up) - distance(down),
						distance(behind) - distance(before));
	return normalize(gradient);
}

Intersection rayMarch(vec3 origin, vec3 direction)
{
	Intersection intersect;
	intersect.exists = false;

	vec3 areaLightPos = vec3(1.0, 0.0, 0.0);
	vec3 dirLightPos = vec3(0.0,1.0,0.0);
	vec3 lightDirection = vec3(0.5,0.0,0.5);
	vec4 sphereColor = vec4(0.0, 0.0, 1.0, 1.0);
	
	float t = 10000.0;

	vec3 newPos = origin;

	for(int i = 0; i <= maxIterations; i++)
	{
		t = distance(newPos);
		newPos += direction*t;

		if(t < epsilon) 
		{
			intersect.exists = true;
			intersect.normal = getNormal(newPos);

			vec4 color = sphereColor*max(0.2, dot(intersect.normal, normalize(areaLightPos-newPos)));
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

	vec3 camP = vec3(sin(iGlobalTime), 0.0, -20.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	vec4 fogColor = vec4(1.0,0.5,1.0,1.0);
	float fog = 100.0;

	Intersection intersect = rayMarch(camP, camDir);
	if(intersect.exists)
	{
		Intersection reflIntersect = rayMarch(intersect.intersectP+intersect.normal*0.01, normalize(reflect(camDir, intersect.normal)));
		gl_FragColor = mix(intersect.color+reflIntersect.color, fogColor, length(intersect.intersectP-camP)/fog);
	}		
	else
		gl_FragColor = mix(vec4(0.0,0.0,0.0,0.0),fogColor, min(length(intersect.intersectP-camP)/fog,1.0));

	//gl_FragColor = mix(vec4(0.0,0.0,0.0,0.0),fogColor, length(newPos-camP)/200);
}		